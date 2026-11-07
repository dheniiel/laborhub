<?php

declare(strict_types=1);

/**
 * Cliente SMTP mínimo, sem dependências externas.
 * Segurança: "starttls" (porta 587), "ssl" (porta 465) ou "none" (somente o Mailpit local).
 * Autenticação nunca é enviada sem TLS.
 */
final class Smtp
{
    public function __construct(
        private string $host,
        private int $porta,
        private string $seguranca,
        private string $usuario,
        private string $senha,
        private string $remetente,
        private string $nomeRemetente = 'LaborHub',
    ) {
        if (!in_array($seguranca, ['starttls', 'ssl', 'none'], true)) {
            throw new InvalidArgumentException('SMTP_SECURITY deve ser starttls, ssl ou none');
        }
        if ($seguranca === 'none' && $usuario !== '') {
            throw new InvalidArgumentException('Autenticação SMTP exige starttls ou ssl');
        }
    }

    public function enviar(string $para, string $assunto, string $texto): void
    {
        if (!filter_var($para, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException('Destinatário inválido');
        }
        $contexto = stream_context_create(['ssl' => [
            'verify_peer' => true,
            'verify_peer_name' => true,
            'peer_name' => $this->host,
        ]]);
        $prefixo = $this->seguranca === 'ssl' ? 'ssl://' : 'tcp://';
        $conexao = @stream_socket_client(
            "$prefixo{$this->host}:{$this->porta}",
            $codigoErro,
            $mensagemErro,
            15,
            STREAM_CLIENT_CONNECT,
            $contexto,
        );
        if ($conexao === false) {
            throw new RuntimeException('Não foi possível conectar ao SMTP');
        }
        stream_set_timeout($conexao, 20);

        try {
            $this->esperar($conexao, [220]);
            $this->comando($conexao, 'EHLO laborhub', [250]);
            if ($this->seguranca === 'starttls') {
                $this->comando($conexao, 'STARTTLS', [220]);
                $metodo = STREAM_CRYPTO_METHOD_TLSv1_2_CLIENT | STREAM_CRYPTO_METHOD_TLSv1_3_CLIENT;
                if (stream_socket_enable_crypto($conexao, true, $metodo) !== true) {
                    throw new RuntimeException('Falha ao iniciar TLS');
                }
                $this->comando($conexao, 'EHLO laborhub', [250]);
            }
            if ($this->usuario !== '') {
                $this->comando($conexao, 'AUTH LOGIN', [334]);
                $this->comando($conexao, base64_encode($this->usuario), [334]);
                $this->comando($conexao, base64_encode($this->senha), [235]);
            }
            $this->comando($conexao, "MAIL FROM:<{$this->remetente}>", [250]);
            $this->comando($conexao, "RCPT TO:<$para>", [250, 251]);
            $this->comando($conexao, 'DATA', [354]);

            $cabecalhos = [
                'Date: ' . date(DATE_RFC2822),
                'Message-ID: <' . bin2hex(random_bytes(16)) . '@' . substr(strrchr($this->remetente, '@'), 1) . '>',
                'From: =?UTF-8?B?' . base64_encode($this->nomeRemetente) . "?= <{$this->remetente}>",
                "To: <$para>",
                'Subject: =?UTF-8?B?' . base64_encode($assunto) . '?=',
                'MIME-Version: 1.0',
                'Content-Type: text/plain; charset=UTF-8',
                'Content-Transfer-Encoding: base64',
            ];
            // Corpo em base64: nenhuma linha começa com ".", dispensando dot-stuffing.
            $mensagem = implode("\r\n", $cabecalhos) . "\r\n\r\n"
                . rtrim(chunk_split(base64_encode($texto), 76, "\r\n")) . "\r\n.";
            $this->comando($conexao, $mensagem, [250]);
            $this->comando($conexao, 'QUIT', [221]);
        } finally {
            fclose($conexao);
        }
    }

    /** @param resource $conexao */
    private function comando($conexao, string $linha, array $esperados): void
    {
        if (fwrite($conexao, $linha . "\r\n") === false) {
            throw new RuntimeException('Falha ao escrever no SMTP');
        }
        $this->esperar($conexao, $esperados);
    }

    /** @param resource $conexao */
    private function esperar($conexao, array $esperados): void
    {
        do {
            $linha = fgets($conexao, 1024);
            if ($linha === false) {
                throw new RuntimeException('Conexão SMTP encerrada');
            }
        } while (isset($linha[3]) && $linha[3] === '-');

        if (!in_array((int) substr($linha, 0, 3), $esperados, true)) {
            // Não inclui a resposta: ela pode ecoar dados da autenticação.
            throw new RuntimeException('SMTP recusou o comando (' . substr($linha, 0, 3) . ')');
        }
    }
}
