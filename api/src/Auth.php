<?php

declare(strict_types=1);

/**
 * Cadastro, login e recuperação de senha do LaborHub.
 * Mantém o contrato da API Dart anterior (/auth/...), agora sobre o MySQL.
 */
final class Auth
{
    // Hash sem senha conhecida: iguala o tempo de resposta para emails inexistentes.
    private const HASH_FALSO = '$2y$10$2uhynh1phTdNxOwRD0xX2uxIzN7NuypRl.p6DMPbCpg4O3Q0nNCa2';
    private const ATIVO = 'usuarios_ativo = 1 AND usuarios_deletado_em IS NULL';
    private const DIAS_SESSAO = 30;

    /** @param Closure(string, string): void $enviarCodigo */
    public function __construct(
        private PDO $db,
        private string $segredo,
        private Closure $enviarCodigo,
    ) {
        if (strlen($segredo) < 32) {
            throw new InvalidArgumentException('APP_SECRET: mínimo 32 caracteres');
        }
    }

    /** @return array{0: int, 1: array, 2?: ?callable} */
    public function processar(string $rota, array $dados, string $ip, ?string $token = null): array
    {
        // Rotas de sessão: identificadas pelo token (Authorization: Bearer), sem email no corpo.
        if ($rota === 'auth/profile') {
            return $this->atualizarPerfil($token, $dados);
        }
        if ($rota === 'auth/session') {
            return $this->renovarSessao($token);
        }
        if ($rota === 'auth/logout') {
            return $this->encerrarSessao($token);
        }
                // Consultas do app logado.
        if ($rota === 'profissionais') {
            return $this->listarProfissionais($token);
        }
        if ($rota === 'solicitacoes') {
            return $this->listarSolicitacoes($token);
        }
        if ($rota === 'solicitacoes/cancelar') {
            return $this->cancelarSolicitacao($token, $dados);
        }

        if($rota === 'solicitacoes/criar') {
            return $this->enviarSolicitacao($token, $dados);
        }

        $email = $this->email($dados);
        return match ($rota) {
            'auth/register' => $this->cadastrar($dados, $email, $ip),
            'auth/login' => $this->entrar($dados, $email),
            'auth/password/request' => $this->solicitarCodigo($email, $ip),
            'auth/password/verify' => $this->validarCodigo($dados, $email),
            'auth/password/reset' => $this->redefinirSenha($dados, $email),
            default => throw new ApiError(404, 'Rota não encontrada.'),
        };
    }

    /** Limite persistente de tentativas por chave (IP ou email). */
    public function limitar(string $chave, int $maximo, int $segundos): void
    {
        $agora = time();
        $chave = $this->hmac("limite:$chave");
        $this->db->prepare('DELETE FROM limites WHERE limites_inicio < ?')->execute([$agora - 3600]);
        $this->db->prepare(
            'INSERT INTO limites (limites_chave, limites_inicio, limites_total) VALUES (?, ?, 1)
             ON DUPLICATE KEY UPDATE
               limites_total = IF(limites_inicio <= ?, 1, limites_total + 1),
               limites_inicio = IF(limites_inicio <= ?, ?, limites_inicio)'
        )->execute([$chave, $agora, $agora - $segundos, $agora - $segundos, $agora]);

        $consulta = $this->db->prepare('SELECT limites_total FROM limites WHERE limites_chave = ?');
        $consulta->execute([$chave]);
        if ((int) $consulta->fetchColumn() > $maximo) {
            throw new ApiError(429, 'Muitas tentativas. Aguarde e tente novamente.');
        }
    }

    private function cadastrar(array $dados, string $email, string $ip): array
    {
        $this->limitar("cadastro:$ip", 10, 3600);
        $senha = $this->texto($dados, 'password', 128);
        $this->validarSenha($senha);
        $usuario = $this->objeto($dados, 'usuario');
        $endereco = $this->objeto($dados, 'endereco');
        $pessoaFisica = isset($dados['pessoaFisica']);
        if ($pessoaFisica === isset($dados['pessoaJuridica'])) {
            throw new ApiError(400, 'Informe pessoa física ou pessoa jurídica, apenas uma.');
        }

        // Repetição após resposta perdida: aceita somente com a mesma senha.
        $existente = $this->buscarUsuario($email);
        if ($existente !== null) {
            if (password_verify($senha, (string) $existente['usuarios_senha_hash'])) {
                return [200, ['usuarios_id' => (int) $existente['usuarios_id']]];
            }
            throw new ApiError(409, 'Não foi possível cadastrar este email.');
        }

        $this->db->beginTransaction();
        try {
            $this->db->prepare(
                'INSERT INTO usuarios (usuarios_email, usuarios_imagem, usuarios_telefone, usuarios_senha_hash,
                   usuarios_ativo, usuarios_is_admin, usuarios_criado_em)
                 VALUES (?, ?, ?, ?, 1, 0, UTC_TIMESTAMP())'
            )->execute([
                $email,
                $this->opcional($usuario, 'usuarios_imagem', 255),
                $this->opcional($usuario, 'usuarios_telefone', 20),
                password_hash($senha, PASSWORD_DEFAULT),
            ]);
            $id = (int) $this->db->lastInsertId();

            if ($pessoaFisica) {
                $pf = $this->objeto($dados, 'pessoaFisica');
                $this->db->prepare(
                    'INSERT INTO pessoaFisica (pf_nome, pf_sobrenome, pf_dataNascimento, pf_genero, pf_cpf, pf_tipo, pf_usuarios_id)
                     VALUES (?, ?, ?, ?, ?, ?, ?)'
                )->execute([
                    $this->texto($pf, 'pf_nome', 50),
                    $this->texto($pf, 'pf_sobrenome', 150),
                    $this->data($pf, 'pf_dataNascimento'),
                    $this->opcional($pf, 'pf_genero', 100),
                    $this->documento($pf, 'pf_cpf', 11),
                    $this->tipo($pf, 'pf_tipo'),
                    $id,
                ]);
            } else {
                $pj = $this->objeto($dados, 'pessoaJuridica');
                $this->db->prepare(
                    'INSERT INTO pessoaJuridica (pj_razaoSocial, pj_nomeFantasia, pj_dataFundacao, pj_cnpj, pj_tipo, pj_usuarios_id)
                     VALUES (?, ?, ?, ?, ?, ?)'
                )->execute([
                    $this->texto($pj, 'pj_razaoSocial', 200),
                    $this->texto($pj, 'pj_nomeFantasia', 200),
                    $this->data($pj, 'pj_dataFundacao'),
                    $this->documento($pj, 'pj_cnpj', 14),
                    $this->tipo($pj, 'pj_tipo'),
                    $id,
                ]);
            }

            $this->db->prepare(
                'INSERT INTO endereco (endereco_nome, endereco_rua, endereco_bairro, endereco_cep, endereco_complemento,
                   endereco_numero, endereco_descricao, endereco_cidade, endereco_uf, endereco_usuarios_id)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
            )->execute([
                $this->opcional($endereco, 'endereco_nome', 30) ?? 'Principal',
                $this->texto($endereco, 'endereco_rua', 100),
                $this->opcional($endereco, 'endereco_bairro', 100),
                $this->texto($endereco, 'endereco_cep', 20),
                $this->opcional($endereco, 'endereco_complemento', 150),
                $this->texto($endereco, 'endereco_numero', 20),
                $this->opcional($endereco, 'endereco_descricao', 1000),
                $this->texto($endereco, 'endereco_cidade', 100),
                strtoupper($this->texto($endereco, 'endereco_uf', 2)),
                $id,
            ]);

            // Serviço enviado pelo cadastro de profissional (CadastroProfissionalRepository).
            if (isset($dados['servicos'])) {
                $servico = $this->objeto($dados, 'servicos');
                $valor = $servico['servicos_valor'] ?? null;
                if ($valor !== null && (!(is_int($valor) || is_float($valor)) || $valor < 0 || $valor > 9999999.99)) {
                    throw new ApiError(400, 'Dados inválidos.');
                }
                $this->db->prepare(
                    'INSERT INTO servicos (servicos_nome, servicos_data, servicos_valor, servicos_tipo_cobranca,
                       servicos_nivel_experiencia, servicos_descricao, servicos_usuarios_id)
                     VALUES (?, ?, ?, ?, ?, ?, ?)'
                )->execute([
                    $this->texto($servico, 'servicos_nome', 100),
                    $this->opcional($servico, 'servicos_data', 25),
                    $valor,
                    $this->opcional($servico, 'servicos_tipo_cobranca', 1000),
                    $this->opcional($servico, 'servicos_nivel_experiencia', 50),
                    $this->opcional($servico, 'servicos_descricao', 1000),
                    $id,
                ]);
            }

            $this->db->commit();

        } catch (Throwable $erro) {
            $this->db->rollBack();
            if ($erro instanceof PDOException && $erro->getCode() === '23000') {
                throw new ApiError(409, 'Email, CPF ou CNPJ já cadastrado.');
            }
            throw $erro;
        }

        return [201, ['usuarios_id' => $id]];
    }

    private function entrar(array $dados, string $email): array
    {
        $this->limitar("login:$email", 10, 900);
        $senha = $this->texto($dados, 'password', 128);
        $usuario = $this->buscarUsuario($email);
        $hash = (string) ($usuario['usuarios_senha_hash'] ?? self::HASH_FALSO);
        if (!password_verify($senha, $hash) || $usuario === null) {
            throw new ApiError(401, 'Email ou senha inválidos.');
        }
        $id = (int) $usuario['usuarios_id'];
        if (password_needs_rehash($hash, PASSWORD_DEFAULT)) {
            $this->db->prepare('UPDATE usuarios SET usuarios_senha_hash = ? WHERE usuarios_id = ?')
                ->execute([password_hash($senha, PASSWORD_DEFAULT), $id]);
        }

        return [200, $this->perfil($usuario) + $this->criarSessao($id)];
    }

    /**
     * Usuário dono do token. Use em rotas que exigem login:
     * $usuario = $auth->usuarioDaSessao($token);
     */
    public function usuarioDaSessao(?string $token): array
    {
        if ($token === null || !preg_match('/^[A-Za-z0-9_-]{43}$/', $token)) {
            $this->sessaoInvalida();
        }
        $consulta = $this->db->prepare(
            'SELECT usuarios.*, sessoes.sessoes_id FROM sessoes
             JOIN usuarios ON usuarios.usuarios_id = sessoes.sessoes_usuarios_id
             WHERE sessoes.sessoes_token_hash = ? AND sessoes.sessoes_expira_em > UTC_TIMESTAMP() AND ' . self::ATIVO
        );
        $consulta->execute([$this->hmac("sessao:$token")]);
        return $consulta->fetch() ?: $this->sessaoInvalida();
    }

    private function criarSessao(int $id): array
    {
        $this->db->exec('DELETE FROM sessoes WHERE sessoes_expira_em <= UTC_TIMESTAMP()');
        $token = $this->tokenAleatorio();
        $expira = time() + self::DIAS_SESSAO * 86400;
        $this->db->prepare(
            'INSERT INTO sessoes (sessoes_token_hash, sessoes_usuarios_id, sessoes_criada_em, sessoes_expira_em)
             VALUES (?, ?, UTC_TIMESTAMP(), ?)'
        )->execute([$this->hmac("sessao:$token"), $id, gmdate('Y-m-d H:i:s', $expira)]);
        return ['token' => $token, 'sessao_expira_em' => gmdate('Y-m-d\TH:i:s\Z', $expira)];
    }

    /** Valida o token, estende a validade (30 dias a partir do uso) e devolve o perfil atualizado. */
    private function renovarSessao(?string $token): array
    {
        $usuario = $this->usuarioDaSessao($token);
        $expira = time() + self::DIAS_SESSAO * 86400;
        $this->db->prepare('UPDATE sessoes SET sessoes_expira_em = ? WHERE sessoes_id = ?')
            ->execute([gmdate('Y-m-d H:i:s', $expira), $usuario['sessoes_id']]);
        return [200, $this->perfil($usuario) + ['sessao_expira_em' => gmdate('Y-m-d\TH:i:s\Z', $expira)]];
    }


     /** Atualiza os dados do usuário logado. Email, CPF/CNPJ, tipo e senha não mudam por aqui. */
    private function atualizarPerfil(?string $token, array $dados): array
    {
        $usuario = $this->usuarioDaSessao($token);
        $id = (int) $usuario['usuarios_id'];
        $dadosUsuario = $this->objeto($dados, 'usuario');
        $endereco = $this->objeto($dados, 'endereco');
        if (!is_int($endereco['endereco_id'] ?? null)) {
            throw new ApiError(400, 'Dados inválidos.');
        }
        $pessoaFisica = isset($dados['pessoaFisica']);
        if ($pessoaFisica === isset($dados['pessoaJuridica'])) {
            throw new ApiError(400, 'Informe pessoa física ou pessoa jurídica, apenas uma.');
        }

        $this->db->beginTransaction();
        try {
            $this->db->prepare(
                'UPDATE usuarios SET usuarios_imagem = ?, usuarios_telefone = ?, usuarios_atualizado_em = UTC_TIMESTAMP()
                 WHERE usuarios_id = ?'
            )->execute([
                $this->opcional($dadosUsuario, 'usuarios_imagem', 255),
                $this->opcional($dadosUsuario, 'usuarios_telefone', 20),
                $id,
            ]);

            if ($pessoaFisica) {
                $pf = $this->objeto($dados, 'pessoaFisica');
                $this->db->prepare(
                    'UPDATE pessoaFisica SET pf_nome = ?, pf_sobrenome = ?, pf_dataNascimento = ?, pf_genero = ?
                     WHERE pf_usuarios_id = ?'
                )->execute([
                    $this->texto($pf, 'pf_nome', 50),
                    $this->texto($pf, 'pf_sobrenome', 150),
                    $this->data($pf, 'pf_dataNascimento'),
                    $this->opcional($pf, 'pf_genero', 100),
                    $id,
                ]);
            } else {
                $pj = $this->objeto($dados, 'pessoaJuridica');
                $this->db->prepare(
                    'UPDATE pessoaJuridica SET pj_razaoSocial = ?, pj_nomeFantasia = ?, pj_dataFundacao = ?
                     WHERE pj_usuarios_id = ?'
                )->execute([
                    $this->texto($pj, 'pj_razaoSocial', 200),
                    $this->texto($pj, 'pj_nomeFantasia', 200),
                    $this->data($pj, 'pj_dataFundacao'),
                    $id,
                ]);
            }

            // Só altera endereço do próprio usuário.
            $this->db->prepare(
                'UPDATE endereco SET endereco_nome = ?, endereco_rua = ?, endereco_bairro = ?, endereco_cep = ?,
                   endereco_complemento = ?, endereco_numero = ?, endereco_cidade = ?, endereco_uf = ?
                 WHERE endereco_id = ? AND endereco_usuarios_id = ?'
            )->execute([
                $this->opcional($endereco, 'endereco_nome', 30) ?? 'Principal',
                $this->texto($endereco, 'endereco_rua', 100),
                $this->opcional($endereco, 'endereco_bairro', 100),
                $this->texto($endereco, 'endereco_cep', 20),
                $this->opcional($endereco, 'endereco_complemento', 150),
                $this->texto($endereco, 'endereco_numero', 20),
                $this->texto($endereco, 'endereco_cidade', 100),
                strtoupper($this->texto($endereco, 'endereco_uf', 2)),
                $endereco['endereco_id'],
                $id,
            ]);
            $this->db->commit();
        } catch (Throwable $erro) {
            $this->db->rollBack();
            throw $erro;
        }

        // Mesma resposta de auth/session: o app substitui a cópia local.
        return $this->renovarSessao($token);
    }

    private function criarSolicitacao(?string $token, array $dados): array
    {
        $usuario = $this->usuarioDaSessao($token);

        $servicoId = $dados['servicos_id'] ?? null;
        $enderecoId = $dados['solicitacao_endereco_id'] ?? null;
        $quantidade = $dados['solicitacao_quantidade'] ?? null;
        $data = $this->data($dados, 'solicitacao_data');
        $observacao = $this->opcional(
            $dados,
            'solicitacao_observacao',
            1000
        );

        if (!is_int($servicoId) || $servicoId <= 0) {
            throw new ApiError(400, 'Informe um serviço válido.');
        }

        if (!is_int($enderecoId) || $enderecoId <= 0) {
            throw new ApiError(400, 'Informe um endereço válido.');
        }

        if (!is_int($quantidade) || $quantidade < 1 || $quantidade > 100) {
            throw new ApiError(400, 'Informe uma quantidade entre 1 e 100.');
        }

        if ($data === null) {
            throw new ApiError(400, 'Informe a data do serviço.');
        }

        $hoje = new DateTimeImmutable('today');
        $dataServico = new DateTimeImmutable($data);

        if ($dataServico < $hoje || $dataServico > $hoje->modify('+60 days')) {
            throw new ApiError(
                400,
                'Escolha uma data entre hoje e os próximos 60 dias.'
            );
        }

        $this->db->beginTransaction();

        try {
            // Confere se o serviço está ativo e se o endereço
            // pertence ao profissional que oferece esse serviço.
            $consulta = $this->db->prepare(
                'SELECT se.servicos_id
                 FROM servicos se
                 JOIN usuarios u
                   ON u.usuarios_id = se.servicos_usuarios_id
                 JOIN endereco e
                   ON e.endereco_usuarios_id = u.usuarios_id
                 WHERE se.servicos_id = ?
                   AND e.endereco_id = ?
                   AND u.usuarios_ativo = 1
                   AND u.usuarios_deletado_em IS NULL'
            );

            $consulta->execute([$servicoId, $enderecoId]);

            if ($consulta->fetchColumn() === false) {
                throw new ApiError(
                    400,
                    'Serviço ou endereço do profissional inválido.'
                );
            }

            // Cadastra a solicitação usando o cliente identificado pelo token.
            $inserir = $this->db->prepare(
                "INSERT INTO solicitacao (
                    solicitacao_data,
                    solicitacao_data_atual,
                    solicitacao_status,
                    solicitacao_quantidade,
                    solicitacao_observacao,
                    solicitacao_criada_em,
                    solicitacao_endereco_id,
                    solicitacao_usuarios_id
                 ) VALUES (
                    ?,
                    UTC_TIMESTAMP(),
                    'Pendente',
                    ?,
                    ?,
                    UTC_TIMESTAMP(),
                    ?,
                    ?
                 )"
            );

            $inserir->execute([
                $data,
                $quantidade,
                $observacao,
                $enderecoId,
                (int) $usuario['usuarios_id'],
            ]);

            // Obtém o ID gerado pelo INSERT da solicitação.
            $solicitacaoId = (int) $this->db->lastInsertId();

            // Cadastra o vínculo na tabela N:N.
            $vincular = $this->db->prepare(
                'INSERT INTO solicitacaoServico (
                    solicitacaoServico_solicitacao_id,
                    solicitacaoServico_servicos_id
                 ) VALUES (?, ?)'
            );

            $vincular->execute([$solicitacaoId, $servicoId]);

            $this->db->commit();

            return [201, ['solicitacao_id' => $solicitacaoId]];
        } catch (Throwable $erro) {
            $this->db->rollBack();
            throw $erro;
        }
    }



        /** Serviços de profissionais ativos, no formato de Profissional.fromMap. */
    private function listarProfissionais(?string $token): array
    {
        $this->usuarioDaSessao($token);
        $linhas = $this->db->query(
            "SELECT
               COALESCE(CONCAT(pf.pf_nome, ' ', pf.pf_sobrenome), pj.pj_nomeFantasia, '') AS profissional_nome,
               se.servicos_id as profissional_servicos_id,
               COALESCE(se.servicos_nome, '') AS profissional_profissao,
               COALESCE(e.endereco_cidade, '') AS profissional_cidade,
               COALESCE(e.endereco_uf, '') AS profissional_uf,
               e.endereco_id AS profissional_endereco_id,
               COALESCE(av.media, 0) AS profissional_avaliacao,
               COALESCE(av.total, 0) AS profissional_total_avaliacoes,
               COALESCE(se.servicos_descricao, '') AS profissional_observacao,
               COALESCE(se.servicos_valor, 0) AS profissional_preco,
               u.usuarios_id AS profissional_usuarios_id,
               COALESCE(u.usuarios_imagem, '') AS profissional_imagem,
               COALESCE(u.usuarios_telefone, '') AS profissional_telefone,
               COALESCE(u.usuarios_email, '') as profissional_email,
               COALESCE(se.servicos_data, '') AS profissional_data,
               COALESCE(se.servicos_tipo_cobranca, '') AS profissional_tipo_cobranca,
               COALESCE(se.servicos_nivel_experiencia, '') AS profissional_experiencia,
               COALESCE(se.servicos_nome, '') AS profissional_servicos_nome,
               COALESCE(av.estrelas_5, 0) AS estrelas_5,
               COALESCE(av.estrelas_4, 0) AS estrelas_4,
               COALESCE(av.estrelas_3, 0) AS estrelas_3,
               COALESCE(av.estrelas_2, 0) AS estrelas_2,
               COALESCE(av.estrelas_1, 0) AS estrelas_1

             FROM servicos se
             JOIN usuarios u ON u.usuarios_id = se.servicos_usuarios_id
             LEFT JOIN pessoaFisica pf ON pf.pf_usuarios_id = u.usuarios_id
             LEFT JOIN pessoaJuridica pj ON pj.pj_usuarios_id = u.usuarios_id
             JOIN endereco e ON e.endereco_id =
               (SELECT MIN(endereco_id) FROM endereco WHERE endereco_usuarios_id = u.usuarios_id)
             LEFT JOIN (
               SELECT
                 avaliado_usuarios_id,
                 ROUND(AVG(avaliacao_notas), 1) AS media,
                 COUNT(*) AS total,
                 SUM(avaliacao_notas = 5) AS estrelas_5,
                 SUM(avaliacao_notas = 4) AS estrelas_4,
                 SUM(avaliacao_notas = 3) AS estrelas_3,
                 SUM(avaliacao_notas = 2) AS estrelas_2,
                 SUM(avaliacao_notas = 1) AS estrelas_1
               FROM avaliacao
               GROUP BY avaliado_usuarios_id
             ) av ON av.avaliado_usuarios_id = u.usuarios_id
             WHERE u.usuarios_ativo = 1 AND u.usuarios_deletado_em IS NULL
               AND COALESCE(pf.pf_tipo, pj.pj_tipo) = 'Profissional'
             ORDER BY profissional_nome"
        )->fetchAll();

        // DECIMAL chega como texto no PDO: converte para número, como o app espera.
        return [200, ['profissionais' => array_map(fn (array $linha): array => [
            'profissional_avaliacao' => (float) $linha['profissional_avaliacao'],
            'profissional_total_avaliacoes' => (int) $linha['profissional_total_avaliacoes'],
            'profissional_preco' => (float) $linha['profissional_preco'],
        ] + $linha, $linhas)]];
    }

    /** Solicitações do cliente logado, no formato de Solicitacao.fromMap. */
    private function listarSolicitacoes(?string $token): array
    {
        $usuario = $this->usuarioDaSessao($token);
        $consulta = $this->db->prepare(
            "SELECT
               so.solicitacao_id,
               COALESCE(so.solicitacao_data, DATE(so.solicitacao_criada_em)) AS solicitacao_data,
               so.solicitacao_conclusao,
               so.solicitacao_status,
               so.solicitacao_motivo,
               so.solicitacao_observacao,
               SUM(se.servicos_valor) * so.solicitacao_quantidade AS servicos_valor,
               COALESCE(MIN(CONCAT(pf.pf_nome, ' ', pf.pf_sobrenome)), MIN(pj.pj_nomeFantasia), '') AS profissional_nome,
               COALESCE(GROUP_CONCAT(DISTINCT se.servicos_nome SEPARATOR ', '), '') AS profissional_profissao,
               COALESCE(MIN(u.usuarios_imagem), '') AS profissional_imagem
             FROM solicitacao so
             JOIN solicitacaoServico ss ON ss.solicitacaoServico_solicitacao_id = so.solicitacao_id
             JOIN servicos se ON se.servicos_id = ss.solicitacaoServico_servicos_id
             JOIN usuarios u ON u.usuarios_id = se.servicos_usuarios_id
             LEFT JOIN pessoaFisica pf ON pf.pf_usuarios_id = u.usuarios_id
             LEFT JOIN pessoaJuridica pj ON pj.pj_usuarios_id = u.usuarios_id
             WHERE so.solicitacao_usuarios_id = ?
               AND so.solicitacao_deletada_em IS NULL
               AND so.solicitacao_status IN ('Finalizado', 'Pendente', 'Recusado')
             GROUP BY so.solicitacao_id
             ORDER BY solicitacao_data DESC"
        );
        $consulta->execute([$usuario['usuarios_id']]);

        return [200, ['solicitacoes' => array_map(fn (array $linha): array => [
            'servicos_valor' => (float) $linha['servicos_valor'],
        ] + $linha, $consulta->fetchAll())]];
    }

    /** Cancela uma solicitação pendente do próprio cliente. */
    private function cancelarSolicitacao(?string $token, array $dados): array
    {
        $usuario = $this->usuarioDaSessao($token);
        $id = $dados['solicitacao_id'] ?? null;
        if (!is_int($id)) {
            throw new ApiError(400, 'Dados inválidos.');
        }

        $atualizar = $this->db->prepare(
            "UPDATE solicitacao SET solicitacao_status = 'Cancelado', solicitacao_atualizada_em = UTC_TIMESTAMP()
             WHERE solicitacao_id = ? AND solicitacao_usuarios_id = ?
               AND solicitacao_status = 'Pendente' AND solicitacao_deletada_em IS NULL"
        );
        $atualizar->execute([$id, $usuario['usuarios_id']]);
        if ($atualizar->rowCount() !== 1) {
            throw new ApiError(409, 'Esta solicitação não pode mais ser cancelada.');
        }
        return [200, ['message' => 'Solicitação cancelada.']];
    }

    private function encerrarSessao(?string $token): array
    {
        if ($token !== null) {
            $this->db->prepare('DELETE FROM sessoes WHERE sessoes_token_hash = ?')
                ->execute([$this->hmac("sessao:$token")]);
        }
        return [200, ['message' => 'Sessão encerrada.']];
    }

    /** Usuário (formato de Usuarios.fromMap), tipo e dados do perfil, para o app guardar offline. */
    private function perfil(array $usuario): array
    {
        $id = (int) $usuario['usuarios_id'];
        $buscar = function (string $sql) use ($id): array {
            $consulta = $this->db->prepare($sql);
            $consulta->execute([$id]);
            return $consulta->fetchAll();
        };
        $pf = $buscar('SELECT * FROM pessoaFisica WHERE pf_usuarios_id = ? LIMIT 1')[0] ?? null;
        $pj = $buscar('SELECT * FROM pessoaJuridica WHERE pj_usuarios_id = ? LIMIT 1')[0] ?? null;
        $criado = $usuario['usuarios_criado_em'] ?? gmdate('Y-m-d H:i:s');

        return [
            'usuarios_id' => $id,
            'usuarios_email' => $usuario['usuarios_email'],
            'usuarios_imagem' => $usuario['usuarios_imagem'] ?? '',
            'usuarios_telefone' => $usuario['usuarios_telefone'],
            'usuarios_senha_hash' => '',
            'usuarios_ativo' => 1,
            'usuarios_is_admin' => (int) $usuario['usuarios_is_admin'],
            'usuarios_criado_em' => str_replace(' ', 'T', (string) $criado) . 'Z',
            'tipo' => $pf['pf_tipo'] ?? $pj['pj_tipo'] ?? null,
            'pessoaFisica' => $pf,
            'pessoaJuridica' => $pj,
            'enderecos' => $buscar('SELECT * FROM endereco WHERE endereco_usuarios_id = ? ORDER BY endereco_id'),
        ];
    }

    private function solicitarCodigo(string $email, string $ip): array
    {
        // Mesmos limites e mesma resposta para emails cadastrados ou não.
        $this->limitar("envio-ip:$ip", 10, 3600);
        $this->limitar("envio-hora:$email", 5, 3600);
        $this->limitar("envio-minuto:$email", 1, 60);

        $resposta = ['message' => 'Se o email estiver cadastrado, você receberá um código.'];
        $usuario = $this->buscarUsuario($email);
        if ($usuario === null) {
            return [202, $resposta];
        }

        $id = (int) $usuario['usuarios_id'];
        $codigo = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $hash = $this->hmac("$email:codigo:$codigo");
        // O novo código substitui qualquer código ou autorização anterior.
        $this->db->prepare(
            'UPDATE usuarios SET usuarios_reset_hash = ?, usuarios_expira_em = UTC_TIMESTAMP() + INTERVAL 10 MINUTE
             WHERE usuarios_id = ?'
        )->execute([$hash, $id]);
        $this->db->prepare('DELETE FROM limites WHERE limites_chave = ?')
            ->execute([$this->hmac("limite:verificar:$email")]);

        // O email é enviado depois da resposta: a latência do SMTP não revela se a conta existe.
        $enviar = function () use ($email, $codigo, $hash, $id): void {
            try {
                ($this->enviarCodigo)($email, $codigo);
            } catch (Throwable) {
                $this->db->prepare(
                    'UPDATE usuarios SET usuarios_reset_hash = NULL, usuarios_expira_em = NULL
                     WHERE usuarios_id = ? AND usuarios_reset_hash = ?'
                )->execute([$id, $hash]);
                // Sem email, código ou detalhes do SMTP no log.
                error_log('Falha na entrega de email de recuperação. Verifique o SMTP.');
            }
        };
        return [202, $resposta, $enviar];
    }

    private function validarCodigo(array $dados, string $email): array
    {
        $codigo = $this->texto($dados, 'code', 6);
        if (!preg_match('/^\d{6}$/', $codigo)) {
            throw new ApiError(400, 'Informe os seis dígitos.');
        }
        try {
            $this->limitar("verificar:$email", 5, 600);
        } catch (ApiError) {
            // Cinco tentativas: o código é descartado.
            $this->db->prepare(
                'UPDATE usuarios SET usuarios_reset_hash = NULL, usuarios_expira_em = NULL WHERE usuarios_email = ?'
            )->execute([$email]);
            $this->codigoInvalido();
        }

        $consulta = $this->db->prepare(
            'SELECT usuarios_id, usuarios_reset_hash FROM usuarios
             WHERE usuarios_email = ? AND ' . self::ATIVO . ' AND usuarios_expira_em > UTC_TIMESTAMP()'
        );
        $consulta->execute([$email]);
        $usuario = $consulta->fetch();
        $esperado = $this->hmac("$email:codigo:$codigo");
        if ($usuario === false || !hash_equals((string) $usuario['usuarios_reset_hash'], $esperado)) {
            $this->codigoInvalido();
        }

        // Troca o código por uma autorização de uso único, válida por 5 minutos.
        $token = $this->tokenAleatorio();
        $atualizar = $this->db->prepare(
            'UPDATE usuarios SET usuarios_reset_hash = ?, usuarios_expira_em = UTC_TIMESTAMP() + INTERVAL 5 MINUTE
             WHERE usuarios_id = ? AND usuarios_reset_hash = ?'
        );
        $atualizar->execute([$this->hmac("$email:autorizacao:$token"), $usuario['usuarios_id'], $esperado]);
        if ($atualizar->rowCount() !== 1) {
            $this->codigoInvalido();
        }
        return [200, ['resetToken' => $token]];
    }

    private function redefinirSenha(array $dados, string $email): array
    {
        $token = $this->texto($dados, 'resetToken', 100);
        $senha = $this->texto($dados, 'password', 128);
        if ($senha !== $this->texto($dados, 'confirmation', 128)) {
            throw new ApiError(400, 'As senhas não conferem.');
        }
        $this->validarSenha($senha);

        // Troca e consumo da autorização no mesmo UPDATE: uso único mesmo com requisições simultâneas.
        $atualizar = $this->db->prepare(
            'UPDATE usuarios SET usuarios_senha_hash = ?, usuarios_reset_hash = NULL, usuarios_expira_em = NULL,
               usuarios_atualizado_em = UTC_TIMESTAMP()
             WHERE usuarios_email = ? AND usuarios_reset_hash = ? AND usuarios_expira_em > UTC_TIMESTAMP()
               AND ' . self::ATIVO
        );
        $atualizar->execute([password_hash($senha, PASSWORD_DEFAULT), $email, $this->hmac("$email:autorizacao:$token")]);
        if ($atualizar->rowCount() !== 1) {
            $this->codigoInvalido();
        }
        // Senha nova encerra as sessões abertas em todos os aparelhos.
        $this->db->prepare(
            'DELETE sessoes FROM sessoes JOIN usuarios ON usuarios.usuarios_id = sessoes.sessoes_usuarios_id
             WHERE usuarios.usuarios_email = ?'
        )->execute([$email]);
        return [200, ['message' => 'Senha redefinida com sucesso.']];
    }

    private function buscarUsuario(string $email): ?array
    {
        $consulta = $this->db->prepare('SELECT * FROM usuarios WHERE usuarios_email = ? AND ' . self::ATIVO);
        $consulta->execute([$email]);
        return $consulta->fetch() ?: null;
    }

    /** 256 bits aleatórios em base64url (43 caracteres). */
    private function tokenAleatorio(): string
    {
        return rtrim(strtr(base64_encode(random_bytes(32)), '+/', '-_'), '=');
    }

    private function hmac(string $valor): string
    {
        return hash_hmac('sha256', $valor, $this->segredo);
    }

    private function email(array $dados): string
    {
        $email = strtolower(trim($this->texto($dados, 'email', 255)));
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new ApiError(400, 'Informe um email válido.');
        }
        return $email;
    }

    private function texto(array $dados, string $chave, int $maximo): string
    {
        $valor = $dados[$chave] ?? null;
        if (!is_string($valor) || trim($valor) === '' || mb_strlen($valor) > $maximo) {
            throw new ApiError(400, 'Dados inválidos.');
        }
        return $valor;
    }

    private function opcional(array $dados, string $chave, int $maximo): ?string
    {
        $valor = $dados[$chave] ?? null;
        if ($valor === null || $valor === '') {
            return null;
        }
        return trim($this->texto($dados, $chave, $maximo));
    }

    private function objeto(array $dados, string $chave): array
    {
        $valor = $dados[$chave] ?? null;
        // {} chega como [] no PHP; listas não vazias são rejeitadas.
        if (!is_array($valor) || ($valor !== [] && array_is_list($valor))) {
            throw new ApiError(400, 'Dados inválidos.');
        }
        return $dados[$chave];
    }

    /** CPF (11) ou CNPJ (14) apenas com dígitos; opcional para manter compatibilidade. */
    private function documento(array $dados, string $chave, int $digitos): ?string
    {
        $valor = $this->opcional($dados, $chave, 20);
        if ($valor === null) {
            return null;
        }
        $valor = preg_replace('/\D/', '', $valor);
        if (strlen($valor) !== $digitos) {
            throw new ApiError(400, 'Documento inválido.');
        }
        return $valor;
    }

    private function tipo(array $dados, string $chave): string
    {
        $tipo = $this->texto($dados, $chave, 15);
        if (!in_array($tipo, ['Cliente', 'Profissional'], true)) {
            throw new ApiError(400, 'Tipo de perfil inválido.');
        }
        return $tipo;
    }

    /** Aceita dd/mm/aaaa (formulário) ou aaaa-mm-dd / ISO 8601 (DateTime.toIso8601String). */
    private function data(array $dados, string $chave): ?string
    {
        $valor = $this->opcional($dados, $chave, 40);
        if ($valor === null) {
            return null;
        }
        $valor = substr($valor, 0, 10);
        foreach (['d/m/Y', 'Y-m-d'] as $formato) {
            $data = DateTimeImmutable::createFromFormat("!$formato", $valor);
            if ($data !== false && $data->format($formato) === $valor) {
                return $data->format('Y-m-d');
            }
        }
        throw new ApiError(400, 'Data inválida.');
    }

    private function validarSenha(string $senha): void
    {
        $tamanho = mb_strlen($senha);
        if (trim($senha) === '' || $tamanho < 7 || $tamanho > 128) {
            throw new ApiError(400, 'A senha deve ter de 7 a 128 caracteres.');
        }
    }

    private function sessaoInvalida(): never
    {
        throw new ApiError(401, 'Sessão inválida ou expirada. Entre novamente.');
    }

    private function codigoInvalido(): never
    {
        throw new ApiError(400, 'Código ou autorização inválidos ou expirados. Solicite outro código.');
    }
}
