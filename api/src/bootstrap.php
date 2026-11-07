<?php

declare(strict_types=1);

require __DIR__ . '/Smtp.php';
require __DIR__ . '/Auth.php';

final class ApiError extends Exception
{
    public function __construct(public readonly int $status, string $mensagem)
    {
        parent::__construct($mensagem);
    }
}

/** Lê uma variável de ambiente obrigatória (definida no .env e repassada pelo Docker). */
function env(string $nome, ?string $padrao = null): string
{
    $valor = getenv($nome);
    if ($valor === false || $valor === '') {
        if ($padrao !== null) {
            return $padrao;
        }
        throw new RuntimeException("Configure $nome");
    }
    return $valor;
}

function conectarBanco(): PDO
{
    $dsn = sprintf(
        'mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
        env('DB_HOST', 'mysql'),
        env('DB_PORT', '3306'),
        env('DB_NAME'),
    );
    $pdo = new PDO($dsn, env('DB_USER'), env('DB_PASSWORD'), [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
        PDO::ATTR_STRINGIFY_FETCHES => false,
    ]);
    // Datas sempre em UTC, como no dump (TIME_ZONE='+00:00').
    $pdo->exec("SET time_zone = '+00:00'");
    return $pdo;
}

function criarSmtp(): Smtp
{
    return new Smtp(
        env('SMTP_HOST'),
        (int) env('SMTP_PORT', '587'),
        env('SMTP_SECURITY', 'starttls'),
        getenv('SMTP_USER') ?: '',
        getenv('SMTP_PASSWORD') ?: '',
        env('SMTP_FROM'),
    );
}

/**
 * Envia a resposta JSON. Se $depois for informado, a conexão é encerrada
 * antes de executá-lo (usado para enviar o email sem atrasar a resposta).
 */
function responder(int $status, array $corpo, ?callable $depois = null): void
{
    $json = json_encode($corpo ?: new stdClass(), JSON_UNESCAPED_UNICODE);
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    header('X-Content-Type-Options: nosniff');

    if ($depois === null) {
        echo $json;
        return;
    }

    ignore_user_abort(true);
    set_time_limit(60);
    if (function_exists('apache_setenv')) {
        apache_setenv('no-gzip', '1');
    }
    header('Content-Length: ' . strlen($json));
    header('Connection: close');
    echo $json;
    if (function_exists('fastcgi_finish_request')) {
        fastcgi_finish_request();
    } else {
        while (ob_get_level() > 0) {
            ob_end_flush();
        }
        flush();
    }
    $depois();
}

/** Lê o corpo JSON da requisição (máximo 16 KiB). */
function lerJson(): array
{
    $corpo = file_get_contents('php://input', false, null, 0, 16385);
    if ($corpo === false || strlen($corpo) > 16384) {
        throw new ApiError(413, 'Dados muito grandes.');
    }
    if (trim($corpo) === '') {
        return [];
    }
    $dados = json_decode($corpo, true);
    // {} chega como [] no PHP; listas não vazias são rejeitadas.
    if (!is_array($dados) || ($dados !== [] && array_is_list($dados))) {
        throw new ApiError(400, 'Dados inválidos.');
    }
    return $dados;
}

/** Token do cabeçalho "Authorization: Bearer <token>", ou null. */
function lerToken(): ?string
{
    $cabecalho = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if ($cabecalho === '' && function_exists('getallheaders')) {
        $cabecalho = array_change_key_case(getallheaders())['authorization'] ?? '';
    }
    return preg_match('/^Bearer\s+(\S+)$/i', trim($cabecalho), $partes) ? $partes[1] : null;
}
