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
        if ($rota === 'solicitacoes/historico-profissional') {
            return $this->listarHistoricoProfissional($token);
        }
        if ($rota === 'solicitacoes/historico-profissional/ocultar') {
            return $this->ocultarHistoricoProfissional($token, $dados);
        }

        if ($rota === 'solicitacoes/agendamentos-profissional') {
            return $this->listarAgendamentosProfissional($token);
        }
        if ($rota === 'solicitacoes/cancelar') {
            return $this->cancelarSolicitacao($token, $dados);
        }
        if ($rota === 'solicitacoes/avaliar') {
            return $this->avaliarSolicitacao($token, $dados);
        }
        if ($rota === 'solicitacoes/enviarSolicitacao') {
            return $this->enviarSolicitacao($token, $dados);
        }
        if ($rota === 'perfil/notificacoes') {
            return $this->salvarPreferenciaNotificacoes($token, $dados);
        }
        if ($rota === 'perfil/dispositivo') {
            return $this->salvarDispositivo($token, $dados);
        }
        if ($rota === 'perfil/notificacoes/consultar') {
            $usuario = $this->usuarioDaSessao($token);

            $consulta = $this->db->prepare(
                'SELECT notificacoes_ativas FROM usuarios WHERE usuarios_id = ?'
            );
            $consulta->execute([(int) $usuario['usuarios_id']]);

            return [200, [
                'notificacoes_ativas' => (int) $consulta->fetchColumn() === 1,
            ]];
        }

        // Contagem para o card.
        if ($rota === 'solicitacoes/listarServicoPendente') {
            $usuario = $this->usuarioDaSessao($token);
            $usuarioId = (int) $usuario['usuarios_id'];

            return [
                200,
                [
                    'totalPendente' => $this->listarServicoPendente($usuarioId),
                ],
            ];
        }

        // Listagem dos pedidos recebidos.
        if ($rota === 'solicitacoes/solicitacaoPendente') {
            $usuario = $this->usuarioDaSessao($token);
            $usuarioId = (int) $usuario['usuarios_id'];

            return [
                200,
                [
                    'solicitacoes' => $this->SolicitacaoPendente($usuarioId),
                ],
            ];
        }

        // Contagem para o card.
        if ($rota === 'solicitacoes/listarServicoAtivo') {
            $usuario = $this->usuarioDaSessao($token);
            $usuarioId = (int) $usuario['usuarios_id'];

            return [
                200,
                [
                    'totalAtivo' => $this->listarServicoAtivo($usuarioId),
                ],
            ];
        }

        // Listagem dos pedidos ativo.
        if ($rota === 'solicitacoes/SolicitacaoProfissionalAtivo') {
            $usuario = $this->usuarioDaSessao($token);
            $usuarioId = (int) $usuario['usuarios_id'];

            return [
                200,
                [
                    'solicitacoesAtivas' => $this->SolicitacaoProfissionalAtivo($usuarioId),
                ],
            ];
        }

        if ($rota === 'solicitacoes/recusarSolicitacao') {
            return [200, $this->alterarSituacaoSolicitacao($token, $dados, 'Recusado')];
        }
        if ($rota === 'solicitacoes/aceitarSolicitacao') {
            return [200, $this->alterarSituacaoSolicitacao($token, $dados, 'Ativo')];
        }
        if ($rota === 'solicitacoes/finalizarSolicitacao') {
            return [200, $this->alterarSituacaoSolicitacao($token, $dados, 'Finalizado')];
        }

        if ($rota === 'profissional/avaliacoes') {
            return $this->listarAvaliacoesProfissional($token, $dados);
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
    public function limitarAcesso(string $rota, string $ip, ?string $token): void
    {
        $consultas = [
            'auth/session',
            'profissionais',
            'profissional/avaliacoes',
            'solicitacoes',
            'solicitacoes/listarServicoPendente',
            'solicitacoes/listarServicoAtivo',
            'solicitacoes/solicitacaoPendente',
            'solicitacoes/SolicitacaoProfissionalAtivo',
            'solicitacoes/historico-profissional',
            'solicitacoes/agendamentos-profissional',
        ];
        if ($token !== null && in_array($rota, $consultas, true)) {
            try {
                $usuario = $this->usuarioDaSessao($token);
            } catch (ApiError $erro) {
                $this->limitar('ip:' . $ip, 60, 900);
                throw $erro;
            }
            // A Home consulta quatro rotas. O orçamento de leitura acompanha a conta.
            $this->limitar('consultas:usuario:' . $usuario['usuarios_id'], 120, 60);
            return;
        }
        $this->limitar('ip:' . $ip, 60, 900);
    }

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
            if (isset($dados['servicos'])) {
                $servico = $this->objeto($dados, 'servicos');
                $servicoId = $servico['servicos_id'] ?? null;

                if (!is_int($servicoId) || $servicoId <= 0) {
                    throw new ApiError(400, 'Informe um serviço válido.');
                }

                $valor = $servico['servicos_valor'] ?? null;
                if ($valor === '') {
                    $valor = null;
                }

                if ($valor !== null && (!is_numeric($valor) || (float) $valor < 0)) {
                    throw new ApiError(400, 'Informe um valor válido para o serviço.');
                }

                $this->db->prepare(
                    'UPDATE servicos
                     SET servicos_nome = ?,
                         servicos_data = ?,
                         servicos_valor = ?,
                         servicos_tipo_cobranca = ?,
                         servicos_nivel_experiencia = ?,
                         servicos_descricao = ?
                     WHERE servicos_id = ? AND servicos_usuarios_id = ?'
                )->execute([
                    $this->texto($servico, 'servicos_nome', 100),
                    $this->opcional($servico, 'servicos_data', 25),
                    $valor,
                    $this->opcional($servico, 'servicos_tipo_cobranca', 1000),
                    $this->opcional($servico, 'servicos_nivel_experiencia', 50),
                    $this->opcional($servico, 'servicos_descricao', 1000),
                    $servicoId,
                    $id,
                ]);
            }
            $this->db->commit();
        } catch (Throwable $erro) {
            $this->db->rollBack();
            throw $erro;
        }

        // Mesma resposta de auth/session: o app substitui a cópia local.
        return $this->renovarSessao($token);
    }

    private function enviarSolicitacao(?string $token, array $dados): array
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

        $fuso = new DateTimeZone('America/Sao_Paulo');

        $hoje = new DateTimeImmutable('today', $fuso);
        $dataServico = new DateTimeImmutable($data, $fuso);

        if ($dataServico < $hoje || $dataServico > $hoje->modify('+60 days')) {
            throw new ApiError(
                400,
                'Escolha uma data entre hoje e os próximos 60 dias.'
            );
        }

        $this->db->beginTransaction();

        try {
            // Serializa envios do mesmo cliente, inclusive requisições simultâneas.
            $bloqueio = $this->db->prepare(
                'SELECT usuarios_id FROM usuarios WHERE usuarios_id = ? FOR UPDATE'
            );
            $bloqueio->execute([(int) $usuario['usuarios_id']]);
            $bloqueio->fetchColumn();


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

            $existente = $this->db->prepare(
                "SELECT so.solicitacao_id
                 FROM solicitacao so
                 WHERE so.solicitacao_usuarios_id = ?
                   AND (so.solicitacao_status IS NULL OR
                        so.solicitacao_status NOT IN ('Recusado', 'Recusada', 'Finalizado'))
                   AND EXISTS (
                       SELECT 1 FROM solicitacaoServico ss
                       WHERE ss.solicitacaoServico_solicitacao_id = so.solicitacao_id
                         AND ss.solicitacaoServico_servicos_id = ?
                   )
                 LIMIT 1"
            );
            $existente->execute([(int) $usuario['usuarios_id'], $servicoId]);
            if ($existente->fetchColumn() !== false) {
                throw new ApiError(
                    409,
                    'Você já solicitou este serviço. Aguarde a recusa ou a finalização para solicitar novamente.'
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
            } catch (\Throwable $erro) {
                $this->db->rollBack();
                throw $erro;
            }

            $logFcm = sys_get_temp_dir() . '/laborhub-fcm.log';

            error_log(
                "[FCM] Início. Serviço {$servicoId}, pedido {$solicitacaoId}\n",
                3,
                $logFcm
            );

            try {
                $this->notificarNovaSolicitacao($servicoId, $solicitacaoId);
                error_log("[FCM] Função terminou sem exceção\n", 3, $logFcm);
            } catch (\Throwable $erro) {
                error_log(
                    '[FCM] Falha: ' . get_class($erro)
                    . ' | código: ' . $erro->getCode() . "\n",
                    3,
                    $logFcm
                );
            }

            return [201, ['solicitacao_id' => $solicitacaoId]];

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
        return [200, ['profissionais' => array_map(fn(array $linha): array => [
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
               COALESCE(so.solicitacao_data_atual, DATE(so.solicitacao_criada_em)) AS solicitacao_data_atual,
               so.solicitacao_conclusao,
               so.solicitacao_quantidade,
               CASE WHEN so.solicitacao_status = 'Recusada' THEN 'Recusado'
                    ELSE so.solicitacao_status END AS solicitacao_status,
               so.solicitacao_motivo,
               so.solicitacao_observacao,
               SUM(se.servicos_valor) * so.solicitacao_quantidade AS servicos_valor,
               COALESCE(MIN(CONCAT(pf.pf_nome, ' ', pf.pf_sobrenome)), MIN(pj.pj_nomeFantasia), '') AS profissional_nome,
               COALESCE(GROUP_CONCAT(DISTINCT se.servicos_nome SEPARATOR ', '), '') AS profissional_profissao,
               COALESCE(MIN(u.usuarios_imagem), '') AS profissional_imagem,
               COALESCE(MIN(u.usuarios_telefone), '') AS profissional_telefone,
               COALESCE(MIN(u.usuarios_email), '') AS profissional_email,
               COALESCE(MIN(e.endereco_cidade), '') AS profissional_cidade,
               COALESCE(MIN(e.endereco_uf), '') AS profissional_uf,
               MIN(av.avaliacao_notas) AS avaliacao_notas,
               MIN(av.avaliacao_descricao) AS avaliacao_descricao,
               MAX(se.servicos_tipo_cobranca) AS servicos_tipo_cobranca
             FROM solicitacao so
             JOIN solicitacaoServico ss ON ss.solicitacaoServico_solicitacao_id = so.solicitacao_id
             JOIN servicos se ON se.servicos_id = ss.solicitacaoServico_servicos_id
             JOIN usuarios u ON u.usuarios_id = se.servicos_usuarios_id
             LEFT JOIN pessoaFisica pf ON pf.pf_usuarios_id = u.usuarios_id
             LEFT JOIN pessoaJuridica pj ON pj.pj_usuarios_id = u.usuarios_id
             LEFT JOIN endereco e ON e.endereco_id = so.solicitacao_endereco_id
             LEFT JOIN avaliacao av ON av.avaliacao_solicitacao_id = so.solicitacao_id
             WHERE so.solicitacao_usuarios_id = ?
               AND so.solicitacao_deletada_em IS NULL
               AND so.solicitacao_status IN ('Finalizado', 'Pendente', 'Ativo', 'Recusado', 'Recusada')
             GROUP BY so.solicitacao_id
             ORDER BY solicitacao_data DESC"
        );
        $consulta->execute([$usuario['usuarios_id']]);

        return [200, ['solicitacoes' => array_map(fn(array $linha): array => [
            'servicos_valor' => (float) $linha['servicos_valor'],
        ] + $linha, $consulta->fetchAll())]];
    }

    private function listarHistoricoProfissional(?string $token): array
    {
        $usuario = $this->usuarioDaSessao($token);
        $consulta = $this->db->prepare(
            "SELECT so.solicitacao_id,
                    COALESCE(so.solicitacao_conclusao, so.solicitacao_data,
                             DATE(so.solicitacao_criada_em)) AS data,
                    CASE WHEN so.solicitacao_status = 'Finalizado'
                         THEN 'Finalizado' ELSE 'Recusado' END AS situacao,
                    COALESCE(so.solicitacao_motivo, so.solicitacao_observacao, '') AS detalhes,
                    itens.servico,
                    COALESCE(
                        (SELECT MIN(NULLIF(TRIM(CONCAT_WS(' ', pf.pf_nome, pf.pf_sobrenome)), ''))
                         FROM pessoaFisica pf WHERE pf.pf_usuarios_id = so.solicitacao_usuarios_id),
                        (SELECT MIN(NULLIF(pj.pj_nomeFantasia, ''))
                         FROM pessoaJuridica pj WHERE pj.pj_usuarios_id = so.solicitacao_usuarios_id),
                        'Cliente') AS cliente
             FROM solicitacao so
             JOIN (
                 SELECT ss.solicitacaoServico_solicitacao_id AS solicitacao_id,
                        COALESCE(GROUP_CONCAT(DISTINCT se.servicos_nome
                            ORDER BY se.servicos_nome SEPARATOR ', '), 'Serviço') AS servico
                 FROM solicitacaoServico ss
                 JOIN servicos se ON se.servicos_id = ss.solicitacaoServico_servicos_id
                 WHERE se.servicos_usuarios_id = ?
                 GROUP BY ss.solicitacaoServico_solicitacao_id
             ) itens ON itens.solicitacao_id = so.solicitacao_id
             LEFT JOIN historico_profissional_oculto oculto
               ON oculto.solicitacao_id = so.solicitacao_id AND oculto.profissional_id = ?
             WHERE so.solicitacao_deletada_em IS NULL
               AND so.solicitacao_status IN ('Finalizado', 'Recusado', 'Recusada')
               AND oculto.solicitacao_id IS NULL
             ORDER BY data DESC, so.solicitacao_id DESC"
        );
        $consulta->execute([$usuario['usuarios_id'], $usuario['usuarios_id']]);
        return [200, ['historico' => $consulta->fetchAll()]];
    }

    private function ocultarHistoricoProfissional(?string $token, array $dados): array
    {
        $usuario = $this->usuarioDaSessao($token);
        $id = $dados['solicitacao_id'] ?? null;
        if (!is_int($id) || $id <= 0) {
            throw new ApiError(400, 'Solicitação inválida.');
        }

        // O vínculo é sempre conferido no banco usando o usuário da sessão.
        $consulta = $this->db->prepare(
            "INSERT INTO historico_profissional_oculto (profissional_id, solicitacao_id)
             SELECT ?, so.solicitacao_id FROM solicitacao so
             WHERE so.solicitacao_id = ?
               AND so.solicitacao_deletada_em IS NULL
               AND so.solicitacao_status IN ('Finalizado', 'Recusado', 'Recusada')
               AND EXISTS (
                   SELECT 1 FROM solicitacaoServico ss
                   JOIN servicos se ON se.servicos_id = ss.solicitacaoServico_servicos_id
                   WHERE ss.solicitacaoServico_solicitacao_id = so.solicitacao_id
                     AND se.servicos_usuarios_id = ?
               )
             ON DUPLICATE KEY UPDATE
               ocultado_em = historico_profissional_oculto.ocultado_em"
        );
        $consulta->execute([$usuario['usuarios_id'], $id, $usuario['usuarios_id']]);
        $confirmacao = $this->db->prepare(
            'SELECT 1 FROM historico_profissional_oculto
             WHERE profissional_id = ? AND solicitacao_id = ?'
        );
        $confirmacao->execute([$usuario['usuarios_id'], $id]);
        if (!$confirmacao->fetchColumn()) {
            throw new ApiError(404, 'Serviço não encontrado no seu histórico.');
        }
        return [200, ['sucesso' => true]];
    }


    private function listarAgendamentosProfissional(?string $token): array
    {
        $usuario = $this->usuarioDaSessao($token);
        $consulta = $this->db->prepare(
            "SELECT
               so.solicitacao_id,
               COALESCE(so.solicitacao_data, so.solicitacao_conclusao,
                        DATE(so.solicitacao_criada_em)) AS solicitacao_data,
               so.solicitacao_conclusao,
               so.solicitacao_status,
               COALESCE(so.solicitacao_data_atual, DATE(so.solicitacao_criada_em)) AS solicitacao_data_atual,
               so.solicitacao_quantidade,
               so.solicitacao_observacao,
               itens.servicos_valor * so.solicitacao_quantidade AS servicos_valor,
               itens.servicos_nome,
               COALESCE(
                   (SELECT MIN(NULLIF(TRIM(CONCAT_WS(' ', pf.pf_nome, pf.pf_sobrenome)), ''))
                    FROM pessoaFisica pf WHERE pf.pf_usuarios_id = cliente.usuarios_id),
                   (SELECT MIN(NULLIF(pj.pj_nomeFantasia, ''))
                    FROM pessoaJuridica pj WHERE pj.pj_usuarios_id = cliente.usuarios_id),
                   'Cliente'
               ) AS cliente_nome,
               cliente.usuarios_imagem AS cliente_imagem
             FROM solicitacao so
             JOIN (
                 SELECT ss.solicitacaoServico_solicitacao_id AS solicitacao_id,
                        COALESCE(SUM(se.servicos_valor), 0) AS servicos_valor,
                        COALESCE(GROUP_CONCAT(DISTINCT se.servicos_nome
                            ORDER BY se.servicos_nome SEPARATOR ', '), '') AS servicos_nome
                 FROM solicitacaoServico ss
                 JOIN servicos se ON se.servicos_id = ss.solicitacaoServico_servicos_id
                 WHERE se.servicos_usuarios_id = ?
                 GROUP BY ss.solicitacaoServico_solicitacao_id
             ) itens ON itens.solicitacao_id = so.solicitacao_id
             LEFT JOIN usuarios cliente ON cliente.usuarios_id = so.solicitacao_usuarios_id
             WHERE so.solicitacao_deletada_em IS NULL
               AND so.solicitacao_status IN ('Ativo', 'Finalizado')
             ORDER BY solicitacao_data DESC, so.solicitacao_id DESC"
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


    /** Avalia (uma única vez) o profissional de um serviço finalizado do próprio cliente. */
    private function avaliarSolicitacao(?string $token, array $dados): array
    {
        $usuario = $this->usuarioDaSessao($token);
        $id = $dados['solicitacao_id'] ?? null;
        $nota = $dados['avaliacao_notas'] ?? null;
        if (!is_int($id) || !is_int($nota) || $nota < 1 || $nota > 5) {
            throw new ApiError(400, 'Escolha de 1 a 5 estrelas.');
        }
        $comentario = $this->opcional($dados, 'avaliacao_descricao', 500);

        // O profissional vem do serviço da solicitação, nunca do app.
        $consulta = $this->db->prepare(
            "SELECT MIN(se.servicos_usuarios_id)
             FROM solicitacao so
             JOIN solicitacaoServico ss ON ss.solicitacaoServico_solicitacao_id = so.solicitacao_id
             JOIN servicos se ON se.servicos_id = ss.solicitacaoServico_servicos_id
             WHERE so.solicitacao_id = ? AND so.solicitacao_usuarios_id = ?
               AND so.solicitacao_status = 'Finalizado' AND so.solicitacao_deletada_em IS NULL"
        );
        $consulta->execute([$id, $usuario['usuarios_id']]);
        $profissionalId = $consulta->fetchColumn();
        if ($profissionalId === null || $profissionalId === false) {
            throw new ApiError(409, 'Somente serviços finalizados podem ser avaliados.');
        }

        $existe = $this->db->prepare('SELECT 1 FROM avaliacao WHERE avaliacao_solicitacao_id = ?');
        $existe->execute([$id]);
        if ($existe->fetchColumn() !== false) {
            throw new ApiError(409, 'Este serviço já foi avaliado.');
        }

        try {
            $this->db->prepare(
                'INSERT INTO avaliacao (avaliacao_notas, avaliacao_descricao, avaliacao_data,
                   avaliador_usuarios_id, avaliado_usuarios_id, avaliacao_solicitacao_id)
                 VALUES (?, ?, UTC_DATE(), ?, ?, ?)'
            )->execute([$nota, $comentario, $usuario['usuarios_id'], $profissionalId, $id]);
        } catch (PDOException $erro) {
            // Chave única de 04-avaliacao.sql: duas avaliações simultâneas do mesmo serviço.
            if ($erro->getCode() === '23000') {
                throw new ApiError(409, 'Este serviço já foi avaliado.');
            }
            throw $erro;
        }

        return [201, ['message' => 'Avaliação enviada.']];
    }

//     listar dados de quem avaliou os servicos
    private function listarAvaliacoesProfissional(
        ?string $token,
        array $dados
    ): array {
        $this->usuarioDaSessao($token);

        $profissionalId = filter_var(
            $dados['profissional_usuarios_id'] ?? null,
            FILTER_VALIDATE_INT,
            ['options' => ['min_range' => 1]]
        );

        if ($profissionalId === false) {
            return [400, ['mensagem' => 'Informe um profissional válido.']];
        }

        $stmt = $this->db->prepare(
            "SELECT
                a.avaliacao_id,
                a.avaliacao_assunto,
                a.avaliacao_descricao,
                a.avaliacao_resposta,
                a.avaliacao_notas,
                a.avaliacao_data,
                COALESCE(
                    NULLIF(TRIM(CONCAT_WS(' ', pf.pf_nome, pf.pf_sobrenome)), ''),
                    NULLIF(TRIM(pj.pj_nomeFantasia), ''),
                    'Usuário'
                ) AS avaliador_nome,
                COALESCE(u.usuarios_imagem, '') AS avaliador_imagem
             FROM avaliacao a
             LEFT JOIN usuarios u
                ON u.usuarios_id = a.avaliador_usuarios_id
             LEFT JOIN pessoaFisica pf
                ON pf.pf_usuarios_id = u.usuarios_id
             LEFT JOIN pessoaJuridica pj
                ON pj.pj_usuarios_id = u.usuarios_id
             WHERE a.avaliado_usuarios_id = :profissional_id
             ORDER BY a.avaliacao_data DESC, a.avaliacao_id DESC"
        );

        $stmt->bindValue(':profissional_id', $profissionalId, PDO::PARAM_INT);
        $stmt->execute();

        return [200, ['avaliacoes' => $stmt->fetchAll(PDO::FETCH_ASSOC)]];
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

       $pf = $buscar(
           'SELECT * FROM pessoaFisica WHERE pf_usuarios_id = ? LIMIT 1'
       )[0] ?? null;

       $pj = $buscar(
           'SELECT * FROM pessoaJuridica WHERE pj_usuarios_id = ? LIMIT 1'
       )[0] ?? null;

       $criado = $usuario['usuarios_criado_em'] ?? gmdate('Y-m-d H:i:s');
       $tipo = $pf['pf_tipo'] ?? $pj['pj_tipo'] ?? null;

       $perfil = [
           'usuarios_id' => $id,
           'usuarios_email' => $usuario['usuarios_email'],
           'usuarios_imagem' => $usuario['usuarios_imagem'] ?? '',
           'usuarios_telefone' => $usuario['usuarios_telefone'],
           'usuarios_senha_hash' => '',
           'usuarios_ativo' => 1,
           'usuarios_is_admin' => (int) $usuario['usuarios_is_admin'],
           'usuarios_criado_em' => str_replace(' ', 'T', (string) $criado) . 'Z',
           'tipo' => $tipo,
           'pessoaFisica' => $pf,
           'pessoaJuridica' => $pj,
           'enderecos' => $buscar(
               'SELECT * FROM endereco
                WHERE endereco_usuarios_id = ?
                ORDER BY endereco_id'
           ),
       ];

       if ($tipo === 'Profissional') {
           $perfil['servicos'] = $buscar(
               'SELECT servicos_id, servicos_nome, servicos_data, servicos_valor,
                       servicos_tipo_cobranca, servicos_nivel_experiencia,
                       servicos_descricao, servicos_usuarios_id
                FROM servicos
                WHERE servicos_usuarios_id = ?
                ORDER BY servicos_id'
           );
       }

//    error_log(sprintf(
//        '[perfil] usuario_id=%d tipo=%s servicos=%s',
//        $id,
//        var_export($tipo, true),
//        isset($perfil['servicos']) ? (string) count($perfil['servicos']) : 'ausente'
//    ));

       return $perfil;
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

    public function listarServicoPendente($usuarioid)
    {

        $consulta = $this->db->prepare('SELECT Count(*) as totalPendente
                                    from solicitacaoServico as ss
                                    INNER JOIN servicos as s on s.servicos_id = ss.solicitacaoServico_servicos_id
                                    INNER JOIN solicitacao as so on so.solicitacao_id = ss.solicitacaoServico_solicitacao_id
                                    WHERE s.servicos_usuarios_id = :usuarioid
                                    and so.solicitacao_status = :status
                                    AND so.solicitacao_deletada_em is NULL');
        $consulta->execute(['usuarioid' => $usuarioid, 'status' => 'Pendente']);
        return (int) $consulta->fetchColumn();
    }

    public function listarServicoAtivo($usuarioid)
    {

        $consulta = $this->db->prepare('SELECT Count(*) as totalAtivo
                                    from solicitacaoServico as ss
                                    INNER JOIN servicos as s on s.servicos_id = ss.solicitacaoServico_servicos_id
                                    INNER JOIN solicitacao as so on so.solicitacao_id = ss.solicitacaoServico_solicitacao_id
                                    WHERE s.servicos_usuarios_id = :usuarioid
                                    and so.solicitacao_status = :status
                                    AND so.solicitacao_deletada_em is NULL');
        $consulta->execute(['usuarioid' => $usuarioid, 'status' => 'Ativo']);
        return (int) $consulta->fetchColumn();
    }

    //Listagem de serviços pendentes
    private function SolicitacaoPendente(int $usuarioIdLogado): array
    {
        $consulta = $this->db->prepare(
            "SELECT
                so.solicitacao_id,
                COALESCE(
                    CONCAT(pf.pf_nome, ' ', pf.pf_sobrenome),
                    pj.pj_nomeFantasia,
                    ''
                ) AS cliente_nome,
                COALESCE(e.endereco_cidade, '') AS cliente_cidade,
                COALESCE(e.endereco_uf, '') AS cliente_uf,
                COALESCE(e.endereco_rua, '') AS cliente_rua,
                COALESCE(e.endereco_bairro, '') AS cliente_bairro,
                COALESCE(e.endereco_complemento, '') AS cliente_complemento,
                COALESCE(e.endereco_numero, '') AS cliente_numero,
                e.endereco_id AS cliente_endereco_id,
                uCliente.usuarios_id AS cliente_usuarios_id,
                se.servicos_usuarios_id AS profissional_usuarios_id,
                COALESCE(uCliente.usuarios_imagem, '') AS cliente_imagem,
                COALESCE(uCliente.usuarios_telefone, '') AS cliente_telefone,
                COALESCE(uCliente.usuarios_email, '') AS cliente_email,
                COALESCE(uCliente.usuarios_imagem, '') as cliente_imagem,
                so.solicitacao_id as cliente_solicitacao_id,
                so.solicitacao_data AS cliente_solicitacao_data,
                so.solicitacao_data_atual AS cliente_solicitacao_data_atual,
                so.solicitacao_quantidade AS cliente_solicitacao_quantidade,
                COALESCE(so.solicitacao_observacao, '')
                    AS cliente_solicitacao_observacao
             FROM solicitacaoServico AS ss
             INNER JOIN servicos AS se
                 ON se.servicos_id = ss.solicitacaoServico_servicos_id
             INNER JOIN solicitacao AS so
                 ON so.solicitacao_id = ss.solicitacaoServico_solicitacao_id
             INNER JOIN usuarios AS uCliente
                 ON uCliente.usuarios_id = so.solicitacao_usuarios_id
             LEFT JOIN endereco AS e
                 ON e.endereco_usuarios_id = uCliente.usuarios_id
             LEFT JOIN pessoaFisica AS pf
                 ON pf.pf_usuarios_id = uCliente.usuarios_id
             LEFT JOIN pessoaJuridica AS pj
                 ON pj.pj_usuarios_id = uCliente.usuarios_id
             WHERE se.servicos_usuarios_id = :idLogado
               AND so.solicitacao_status = :status
               AND so.solicitacao_deletada_em IS NULL"
        );

        $consulta->execute([
            'idLogado' => $usuarioIdLogado,
            'status' => 'Pendente',
        ]);

        return $consulta->fetchAll(PDO::FETCH_ASSOC);
    }

    //Dadosd do usuarios ativos
    private function SolicitacaoProfissionalAtivo(int $usuarioIdLogado): array
    {
        $consulta = $this->db->prepare(
            "SELECT
                    so.solicitacao_id,
                    COALESCE(
                        CONCAT(pf.pf_nome, ' ', pf.pf_sobrenome),
                        pj.pj_nomeFantasia,
                        ''
                    ) AS cliente_nome,
                    COALESCE(e.endereco_cidade, '') AS cliente_cidade,
                    COALESCE(e.endereco_uf, '') AS cliente_uf,
                    COALESCE(e.endereco_rua, '') AS cliente_rua,
                    COALESCE(e.endereco_bairro, '') AS cliente_bairro,
                    COALESCE(e.endereco_complemento, '') AS cliente_complemento,
                    COALESCE(e.endereco_numero, '') AS cliente_numero,
                    e.endereco_id AS cliente_endereco_id,
                    uCliente.usuarios_id AS cliente_usuarios_id,
                    se.servicos_usuarios_id AS profissional_usuarios_id,
                    COALESCE(uCliente.usuarios_imagem, '') AS cliente_imagem,
                    COALESCE(uCliente.usuarios_telefone, '') AS cliente_telefone,
                    COALESCE(uCliente.usuarios_email, '') AS cliente_email,
                    so.solicitacao_id as cliente_solicitacao_id,
                    so.solicitacao_data AS cliente_solicitacao_data,
                    so.solicitacao_data_atual AS cliente_solicitacao_data_atual,
                    so.solicitacao_quantidade AS cliente_solicitacao_quantidade,
                    COALESCE(so.solicitacao_observacao, '')
                        AS cliente_solicitacao_observacao
                 FROM solicitacaoServico AS ss
                 INNER JOIN servicos AS se
                     ON se.servicos_id = ss.solicitacaoServico_servicos_id
                 INNER JOIN solicitacao AS so
                     ON so.solicitacao_id = ss.solicitacaoServico_solicitacao_id
                 INNER JOIN usuarios AS uCliente
                     ON uCliente.usuarios_id = so.solicitacao_usuarios_id
                 LEFT JOIN endereco AS e
                     ON e.endereco_id = so.solicitacao_endereco_id
                 LEFT JOIN pessoaFisica AS pf
                     ON pf.pf_usuarios_id = uCliente.usuarios_id
                 LEFT JOIN pessoaJuridica AS pj
                     ON pj.pj_usuarios_id = uCliente.usuarios_id
                 WHERE se.servicos_usuarios_id = :idLogado
                   AND so.solicitacao_status = :status
                   AND so.solicitacao_deletada_em IS NULL"
        );

        $consulta->execute([
            'idLogado' => $usuarioIdLogado,
            'status' => 'Ativo',
        ]);

        return $consulta->fetchAll(PDO::FETCH_ASSOC);
    }


    private function alterarSituacaoSolicitacao(?string $token, array $dados, string $status): array
    {
        $usuario = $this->usuarioDaSessao($token);
        $id = $dados['solicitacao_id'] ?? null;
        if (!is_int($id) || $id <= 0) {
            throw new ApiError(400, 'Solicitação inválida.');
        }
        $motivo = $status === 'Recusado' ? $this->texto($dados, 'motivo', 250) : null;
        $origem = $status === 'Finalizado' ? 'Ativo' : 'Pendente';

        $this->db->beginTransaction();
        try {
            $consulta = $this->db->prepare(
                'SELECT so.solicitacao_status
                 FROM solicitacao so
                 WHERE so.solicitacao_id = ?
                   AND so.solicitacao_deletada_em IS NULL
                   AND EXISTS (
                       SELECT 1 FROM solicitacaoServico ss
                       JOIN servicos se ON se.servicos_id = ss.solicitacaoServico_servicos_id
                       WHERE ss.solicitacaoServico_solicitacao_id = so.solicitacao_id
                         AND se.servicos_usuarios_id = ?
                   )
                 FOR UPDATE'
            );
            $consulta->execute([$id, (int) $usuario['usuarios_id']]);
            $atual = $consulta->fetchColumn();
            if ($atual === false) {
                throw new ApiError(404, 'Solicitação não encontrada para este profissional.');
            }
            // Repetir uma confirmação após falha de conexão mantém o resultado.
            if ($atual === $status || ($status === 'Recusado' && $atual === 'Recusada')) {
                $this->db->commit();
                return ['sucesso' => true];
            }
            if ($atual !== $origem) {
                throw new ApiError(409, 'O status da solicitação mudou. Atualize a tela.');
            }

            $conclusao = $status === 'Finalizado'
                ? (new DateTimeImmutable('now', new DateTimeZone('America/Sao_Paulo')))->format('Y-m-d')
                : null;
            $atualizar = $this->db->prepare(
                'UPDATE solicitacao
                 SET solicitacao_status = ?,
                     solicitacao_status_profissional = ?,
                     solicitacao_atualizada_em = UTC_TIMESTAMP(),
                     solicitacao_motivo = COALESCE(?, solicitacao_motivo),
                     solicitacao_conclusao = COALESCE(?, solicitacao_conclusao)
                 WHERE solicitacao_id = ?'
            );
            $atualizar->execute([$status, $status, $motivo, $conclusao, $id]);
            $this->db->commit();
            return ['sucesso' => true];
        } catch (Throwable $erro) {
            $this->db->rollBack();
            throw $erro;
        }
    }


    // função para salvar preferencia de notificações
    private function salvarPreferenciaNotificacoes(?string $token, array $dados): array
    {
        $usuario = $this->usuarioDaSessao($token);
        $ativo = $dados['ativo'] ?? null;

        if (!is_bool($ativo)) {
            throw new ApiError(400, 'O campo ativo deve ser true ou false.');
        }

        $atualizar = $this->db->prepare(
            'UPDATE usuarios SET notificacoes_ativas = ? WHERE usuarios_id = ?'
        );
        $atualizar->execute([$ativo ? 1 : 0, (int) $usuario['usuarios_id']]);

        return [200, ['notificacoes_ativas' => $ativo]];
    }
    private function salvarDispositivo(?string $token, array $dados): array
    {
        $usuario = $this->usuarioDaSessao($token);
        $fcmToken = $dados['fcm_token'] ?? null;

        if (!is_string($fcmToken) || $fcmToken === '' ||
            strlen($fcmToken) > 512 || preg_match('/[^\x21-\x7E]/', $fcmToken)) {
            throw new ApiError(400, 'Token FCM inválido.');
        }

        $id = (int) $usuario['usuarios_id'];

        $this->db->beginTransaction();
        try {
            $this->db->prepare(
                'UPDATE usuarios SET fcm_token = NULL
                 WHERE fcm_token = ? AND usuarios_id <> ?'
            )->execute([$fcmToken, $id]);

            $this->db->prepare(
                'UPDATE usuarios SET fcm_token = ? WHERE usuarios_id = ?'
            )->execute([$fcmToken, $id]);

            $this->db->commit();
        } catch (\Throwable $erro) {
            $this->db->rollBack();
            throw $erro;
        }

        return [200, ['message' => 'Dispositivo registrado.']];
    }

    private function notificarNovaSolicitacao(int $servicoId, int $solicitacaoId): void
    {
        $consulta = $this->db->prepare(
            'SELECT u.fcm_token
             FROM servicos s
             JOIN usuarios u ON u.usuarios_id = s.servicos_usuarios_id
             WHERE s.servicos_id = ?
               AND u.notificacoes_ativas = 1
               AND u.fcm_token IS NOT NULL'
        );
        $consulta->execute([$servicoId]);

        $fcmToken = $consulta->fetchColumn();

        if (!is_string($fcmToken) || $fcmToken === '') {
            error_log('[FCM] Nenhum destinatário habilitado para o serviço ' . $servicoId);
            return;
        }

        error_log('[FCM] Iniciando envio da solicitação ' . $solicitacaoId);

        $fcmToken = $consulta->fetchColumn();
        if (!is_string($fcmToken) || $fcmToken === '') {
            return;
        }

        $credenciais = \Google\Auth\ApplicationDefaultCredentials::getCredentials(
            ['https://www.googleapis.com/auth/firebase.messaging']
        );
        $autorizacao = $credenciais->fetchAuthToken();
        $accessToken = $autorizacao['access_token'] ?? null;

        if (!is_string($accessToken) || $accessToken === '') {
            throw new \RuntimeException('Autorização FCM indisponível.');
        }

        $http = new \GuzzleHttp\Client([
            'connect_timeout' => 3,
            'timeout' => 5,
        ]);

        $http->post(
            'https://fcm.googleapis.com/v1/projects/laborhub-1aea9/messages:send',
            [
                'headers' => ['Authorization' => 'Bearer ' . $accessToken],
                'json' => [
                    'message' => [
                        'token' => $fcmToken,
                        'notification' => [
                            'title' => 'Nova solicitação',
                            'body' => 'Você recebeu uma nova solicitação no LaborHub.',
                        ],
                        'data' => [
                            'solicitacao_id' => (string) $solicitacaoId,
                        ],
                    ],
                ],
            ]
        );
        error_log('[FCM] Firebase aceitou a solicitação ' . $solicitacaoId);

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
