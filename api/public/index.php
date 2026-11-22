<?php

declare(strict_types=1);

require dirname(__DIR__) . '/src/bootstrap.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new ApiError(405, 'Método não permitido.');
    }
    $rota = trim((string) parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH), '/');

    $auth = new Auth(conectarBanco(), env('APP_SECRET'), function (string $email, string $codigo): void {
        criarSmtp()->enviar(
            $email,
            'Código para redefinir sua senha',
            "Seu código é $codigo. Ele expira em 10 minutos e permite até 5 tentativas.\n\n"
            . 'Se você não solicitou a recuperação, ignore este email.',
        );
    });

    $ip = $_SERVER['REMOTE_ADDR'] ?? 'desconhecido';
    $token = lerToken();
    $auth->limitarAcesso($rota, $ip, $token);
    $resultado = $auth->processar($rota, lerJson(), $ip, $token);
    responder($resultado[0], $resultado[1], $resultado[2] ?? null);
} catch (ApiError $erro) {
    responder($erro->status, ['message' => $erro->getMessage()]);
} catch (Throwable $erro) {
    // Registra só o tipo e o local: mensagens podem conter dados pessoais ou credenciais.
    error_log(sprintf('LaborHub API: %s (%s) em %s:%d', $erro::class, $erro->getCode(), $erro->getFile(), $erro->getLine()));
    responder(500, ['message' => 'Não foi possível concluir. Tente novamente.']);
}


