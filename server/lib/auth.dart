import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

typedef SendCode = Future<void> Function(String email, String code);

class ApiError implements Exception {
  final int status;
  final String message;
  ApiError(this.status, this.message);
}

class AuthApi {
  final Database db;
  final String secret;
  final SendCode sendCode;
  final DateTime Function() clock;
  final int passwordIterations;
  final _random = Random.secure();
  AuthApi(
    this.db,
    this.secret,
    this.sendCode, {
    DateTime Function()? clock,
    this.passwordIterations = 600000,
  }) : clock = clock ?? DateTime.now {
    if (secret.length < 32)
      throw ArgumentError('RESET_SECRET: mínimo 32 caracteres');
    db.execute('PRAGMA journal_mode=WAL; PRAGMA busy_timeout=5000;');
    db.execute('''CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY, email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL, created TEXT NOT NULL,
      active INTEGER NOT NULL DEFAULT 1)''');
    db.execute('''CREATE TABLE IF NOT EXISTS resets (
      email TEXT PRIMARY KEY, code TEXT, grant_hash TEXT, expires INTEGER NOT NULL,
      attempts INTEGER NOT NULL DEFAULT 0)''');
    db.execute('''CREATE TABLE IF NOT EXISTS limits (
      key TEXT PRIMARY KEY, start INTEGER NOT NULL, count INTEGER NOT NULL)''');
  }

  int get now => clock().millisecondsSinceEpoch ~/ 1000;
  String digest(String value) => crypto.Hmac(
    crypto.sha256,
    utf8.encode(secret),
  ).convert(utf8.encode(value)).toString();
  String token() =>
      base64Url.encode(List.generate(32, (_) => _random.nextInt(256)));
  bool equal(String a, String b) {
    var diff = a.length ^ b.length;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ (i < b.length ? b.codeUnitAt(i) : 0);
    }
    return diff == 0;
  }

  Future<String> hashPassword(String password, [String? salt]) async {
    salt ??= token();
    final key = await Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: passwordIterations,
      bits: 256,
    ).deriveKeyFromPassword(password: password, nonce: utf8.encode(salt));
    return '$salt:${base64.encode(await key.extractBytes())}';
  }

  void limit(String key, int max, int seconds) {
    final hashed = digest('limit:$key');
    db.execute('DELETE FROM limits WHERE start < ?', [now - 3600]);
    db.execute(
      '''INSERT INTO limits(key,start,count) VALUES(?,?,1)
      ON CONFLICT(key) DO UPDATE SET
      count=CASE WHEN start <= ? THEN 1 ELSE count+1 END,
      start=CASE WHEN start <= ? THEN excluded.start ELSE start END''',
      [hashed, now, now - seconds, now - seconds],
    );
    if ((db.select('SELECT count FROM limits WHERE key=?', [
              hashed,
            ]).single['count']
            as int) >
        max) {
      throw ApiError(429, 'Muitas tentativas. Aguarde e tente novamente.');
    }
  }

  String field(Map<String, dynamic> body, String key, {int max = 254}) {
    final value = body[key];
    if (value is! String || value.isEmpty || value.length > max) {
      throw ApiError(400, 'Dados inválidos.');
    }
    return value;
  }

  Response json(int status, Map<String, dynamic> body) => Response(
    status,
    body: jsonEncode(body),
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    },
  );

  Future<Response> call(Request request) async {
    try {
      if (request.method != 'POST')
        return json(405, {'message': 'Método não permitido.'});
      final ip = request.context['clientIp'] as String? ?? 'unknown';
      limit('ip:$ip', 60, 900);
      final bytes = <int>[];
      await for (final chunk in request.read()) {
        bytes.addAll(chunk);
        if (bytes.length > 4096) throw ApiError(413, 'Dados muito grandes.');
      }
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>)
        throw ApiError(400, 'Dados inválidos.');
      final email = field(decoded, 'email').trim().toLowerCase();
      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
        throw ApiError(400, 'Informe um email válido.');
      }
      final path = request.url.path;
      if (path == 'auth/register') {
        limit('register:$ip', 5, 3600);
        final password = field(decoded, 'password', max: 128);
        validatePassword(password);
        final hash = await hashPassword(password);
        db.execute(
          'INSERT OR IGNORE INTO users(email,password,created) VALUES(?,?,?)',
          [email, hash, clock().toUtc().toIso8601String()],
        );
        if (db.updatedRows == 0) {
          final existing = db.select(
            'SELECT password FROM users WHERE email=? AND active=1',
            [email],
          );
          if (existing.isEmpty)
            throw ApiError(409, 'Não foi possível cadastrar este email.');
          final stored = existing.single['password'] as String;
          if (!equal(
            await hashPassword(password, stored.split(':').first),
            stored,
          )) {
            throw ApiError(409, 'Não foi possível cadastrar este email.');
          }
          return json(200, {});
        }
        return json(201, {});
      }
      if (path == 'auth/login') {
        limit('login:$email', 10, 900);
        final password = field(decoded, 'password', max: 128);
        final rows = db.select(
          'SELECT * FROM users WHERE email=? AND active=1',
          [email],
        );
        final stored = rows.isEmpty
            ? '${digest("dummy")}:${digest("dummy-hash")}'
            : rows.single['password'] as String;
        final computed = await hashPassword(password, stored.split(':').first);
        if (rows.isEmpty || !equal(computed, stored))
          throw ApiError(401, 'Email ou senha inválidos.');
        // Recheck after the asynchronous KDF: a reset may have changed the password.
        final current = db.select(
          'SELECT * FROM users WHERE email=? AND password=? AND active=1',
          [email, stored],
        );
        if (current.isEmpty) throw ApiError(401, 'Email ou senha inválidos.');
        final user = current.single;
        return json(200, {
          'usuarios_id': user['id'],
          'usuarios_email': email,
          'usuarios_imagem': '',
          'usuarios_telefone': null,
          'usuarios_senha_hash': '',
          'usuarios_ativo': 1,
          'usuarios_is_admin': 0,
          'usuarios_criado_em': user['created'],
        });
      }
      if (path == 'auth/password/request') {
        limit('send-ip:$ip', 10, 3600);
        // Same response and limits for existing and unknown accounts.
        limit('send-hour:$email', 5, 3600);
        limit('send-minute:$email', 1, 60);
        db.execute('DELETE FROM resets WHERE expires <= ?', [now]);
        final code = _random.nextInt(1000000).toString().padLeft(6, '0');
        final hash = digest('$email:code:$code');
        db.execute(
          'INSERT OR REPLACE INTO resets(email,code,expires) VALUES(?,?,?)',
          [email, hash, now + 600],
        );
        final user = db.select(
          'SELECT id FROM users WHERE email=? AND active=1',
          [email],
        );
        if (user.isNotEmpty) {
          // Delivery runs separately so SMTP latency/failure cannot reveal account existence.
          Future<void>(() async {
            try {
              await sendCode(email, code);
            } catch (_) {
              db.execute('DELETE FROM resets WHERE email=? AND code=?', [
                email,
                hash,
              ]);
              // Never log the address, code or SMTP exception (may contain credentials).
              print(
                'Falha na entrega de email de recuperação. Verifique o SMTP.',
              );
            }
          });
        }
        return json(202, {
          'message': 'Se o email estiver cadastrado, você receberá um código.',
        });
      }
      if (path == 'auth/password/verify') {
        final code = field(decoded, 'code', max: 6);
        if (!RegExp(r'^\d{6}$').hasMatch(code))
          throw ApiError(400, 'Informe os seis dígitos.');
        final rows = db.select('SELECT * FROM resets WHERE email=?', [email]);
        if (rows.isEmpty) invalidCode();
        final reset = rows.single;
        if (reset['expires'] as int <= now ||
            reset['attempts'] as int >= 5 ||
            reset['code'] == null)
          invalidCode();
        db.execute('UPDATE resets SET attempts=attempts+1 WHERE email=?', [
          email,
        ]);
        if (!equal(digest('$email:code:$code'), reset['code'] as String) ||
            db.select('SELECT id FROM users WHERE email=? AND active=1', [
              email,
            ]).isEmpty)
          invalidCode();
        final grant = token();
        db.execute(
          'UPDATE resets SET code=NULL,grant_hash=?,expires=? WHERE email=?',
          [digest('$email:grant:$grant'), now + 300, email],
        );
        return json(200, {'resetToken': grant});
      }
      if (path == 'auth/password/reset') {
        final grant = field(decoded, 'resetToken', max: 100);
        final password = field(decoded, 'password', max: 128);
        if (password != field(decoded, 'confirmation', max: 128))
          throw ApiError(400, 'As senhas não conferem.');
        validatePassword(password);
        final grantHash = digest('$email:grant:$grant');
        if (db.select(
          'SELECT email FROM resets WHERE email=? AND grant_hash=? AND expires>?',
          [email, grantHash, now],
        ).isEmpty)
          invalidCode();
        final hash = await hashPassword(password);
        // Atomic single-use consumption, including requests racing during the KDF.
        db.execute('BEGIN IMMEDIATE');
        try {
          db.execute(
            'DELETE FROM resets WHERE email=? AND grant_hash=? AND expires>?',
            [email, grantHash, now],
          );
          if (db.updatedRows != 1) invalidCode();
          db.execute('UPDATE users SET password=? WHERE email=? AND active=1', [
            hash,
            email,
          ]);
          if (db.updatedRows != 1) invalidCode();
          db.execute('COMMIT');
        } catch (_) {
          db.execute('ROLLBACK');
          rethrow;
        }
        return json(200, {'message': 'Senha redefinida com sucesso.'});
      }
      return json(404, {'message': 'Rota não encontrada.'});
    } on ApiError catch (error) {
      return json(error.status, {'message': error.message});
    } on FormatException {
      return json(400, {'message': 'Dados inválidos.'});
    } catch (_) {
      return json(500, {
        'message': 'Não foi possível concluir. Tente novamente.',
      });
    }
  }

  Never invalidCode() => throw ApiError(
    400,
    'Código ou autorização inválidos ou expirados. Solicite outro código.',
  );
  void validatePassword(String password) {
    if (password.trim().isEmpty ||
        password.length < 7 ||
        password.length > 128) {
      throw ApiError(400, 'A senha deve ter de 7 a 128 caracteres.');
    }
  }
}
