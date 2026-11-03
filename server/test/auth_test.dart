import 'dart:convert';
import 'dart:io';

import 'package:laborhub_server/auth.dart';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Database db;
  late AuthApi api;
  late DateTime time;
  late List<String> sent;
  const email = 'cliente@example.com';
  Future<Response> post(
    String path, [
    Map<String, dynamic> fields = const {},
    String ip = 'test',
  ]) => api.call(
    Request(
      'POST',
      Uri.parse('https://api.example.com/auth/$path'),
      body: jsonEncode({'email': email, ...fields}),
      context: {'clientIp': ip},
    ),
  );
  Future<String> verify() async {
    final response = await post('password/verify', {'code': sent.last});
    expect(response.statusCode, 200);
    return (jsonDecode(await response.readAsString()) as Map)['resetToken']
        as String;
  }

  Future<void> request() async {
    expect((await post('password/request')).statusCode, 202);
    await Future<void>.delayed(Duration.zero);
  }

  Map<String, String> reset(String token) => {
    'resetToken': token,
    'password': 'nova senha segura',
    'confirmation': 'nova senha segura',
  };

  setUp(() async {
    db = sqlite3.openInMemory();
    time = DateTime.utc(2026, 11, 3);
    sent = [];
    api = AuthApi(
      db,
      'a' * 32,
      (email, code) async {
        sent.add(code);
      },
      clock: () => time,
      passwordIterations: 10,
    );
    expect(
      (await post('register', {'password': 'senha antiga'})).statusCode,
      201,
    );
  });
  tearDown(() => db.close());

  test('full flow changes login, hashes secrets and prevents reuse', () async {
    await request();
    expect(sent.single, matches(r'^\d{6}$'));
    final stored = db.select('SELECT * FROM resets').single;
    expect(stored['code'], isNot(sent.single));
    expect(
      db.select('SELECT password FROM users').single['password'],
      isNot('senha antiga'),
    );
    final token = await verify();
    expect(
      db.select('SELECT * FROM resets').single['grant_hash'],
      isNot(token),
    );
    expect(
      (await post('password/verify', {'code': sent.last})).statusCode,
      400,
    );
    expect((await post('password/reset', reset(token))).statusCode, 200);
    expect((await post('password/reset', reset(token))).statusCode, 400);
    expect((await post('login', {'password': 'senha antiga'})).statusCode, 401);
    expect(
      (await post('login', {'password': 'nova senha segura'})).statusCode,
      200,
    );
  });
  test('five wrong codes lock the challenge', () async {
    await request();
    final wrong = sent.last == '000000' ? '111111' : '000000';
    for (var i = 0; i < 5; i++) {
      expect((await post('password/verify', {'code': wrong})).statusCode, 400);
    }
    expect(
      (await post('password/verify', {'code': sent.last})).statusCode,
      400,
    );
  });
  test('code and grant expiry use exclusive deadline', () async {
    await request();
    time = time.add(const Duration(minutes: 10));
    expect(
      (await post('password/verify', {'code': sent.last})).statusCode,
      400,
    );
    await request();
    final token = await verify();
    time = time.add(const Duration(minutes: 5));
    expect((await post('password/reset', reset(token))).statusCode, 400);
  });
  test('resend throttles and invalidates previous authorization', () async {
    await request();
    final token = await verify();
    expect((await post('password/request')).statusCode, 429);
    time = time.add(const Duration(seconds: 60));
    await request();
    expect((await post('password/reset', reset(token))).statusCode, 400);
  });
  test(
    'unknown and inactive accounts receive same response without mail',
    () async {
      final missing = await post('password/request', {
        'email': 'missing@example.com',
      });
      final known = await post('password/request');
      expect(await missing.readAsString(), await known.readAsString());
      expect(missing.statusCode, known.statusCode);
      await Future<void>.delayed(Duration.zero);
      expect(sent.length, 1);
      db.execute('UPDATE users SET active=0');
      time = time.add(const Duration(seconds: 60));
      await request();
      expect(sent.length, 1);
    },
  );
  test('confirmation and password policy do not consume token', () async {
    await request();
    final token = await verify();
    expect(
      (await post('password/reset', {
        ...reset(token),
        'confirmation': 'other',
      })).statusCode,
      400,
    );
    expect(
      (await post('password/reset', {
        ...reset(token),
        'password': '123',
        'confirmation': '123',
      })).statusCode,
      400,
    );
    expect((await post('password/reset', reset(token))).statusCode, 200);
  });
  test('simultaneous resets can consume a grant only once', () async {
    await request();
    final token = await verify();
    final responses = await Future.wait([
      post('password/reset', reset(token)),
      post('password/reset', reset(token)),
    ]);
    expect(responses.map((r) => r.statusCode).toList()..sort(), [200, 400]);
  });
  test('authorization is bound to the email', () async {
    await request();
    final token = await verify();
    expect(
      (await post('password/reset', {
        ...reset(token),
        'email': 'other@example.com',
      })).statusCode,
      400,
    );
  });
  test('limits survive service reconstruction and other IPs', () async {
    await request();
    api = AuthApi(
      db,
      'a' * 32,
      (email, code) async {},
      clock: () => time,
      passwordIterations: 10,
    );
    expect((await post('password/request', {}, 'other-ip')).statusCode, 429);
  });
  test('invalid JSON and oversized requests are rejected', () async {
    expect(
      (await api.call(
        Request('POST', Uri.parse('https://api.test/auth/login'), body: '{'),
      )).statusCode,
      400,
    );
    expect((await post('login', {'password': 'a' * 5000})).statusCode, 413);
  });
  test('SMTP failure removes the challenge', () async {
    api = AuthApi(
      db,
      'a' * 32,
      (email, code) async {
        throw Exception('SMTP');
      },
      clock: () => time,
      passwordIterations: 10,
    );
    await request();
    expect(db.select('SELECT * FROM resets'), isEmpty);
  });

  test('registration retries require the existing password', () async {
    expect(
      (await post('register', {'password': 'senha antiga'})).statusCode,
      200,
    );
    expect(
      (await post('register', {'password': 'outra senha'})).statusCode,
      409,
    );
    expect(db.select('SELECT * FROM users').length, 1);
  });

  test(
    'accounts, challenges and limits survive closing the database',
    () async {
      final directory = Directory.systemTemp.createTempSync('laborhub-auth-');
      final path = '${directory.path}/auth.sqlite';
      var persistent = sqlite3.open(path);
      try {
        var service = AuthApi(
          persistent,
          'a' * 32,
          (_, _) async {},
          clock: () => time,
          passwordIterations: 10,
        );
        persistent.execute(
          'INSERT INTO users(email,password,created) VALUES(?,?,?)',
          [
            email,
            await service.hashPassword('senha antiga'),
            time.toIso8601String(),
          ],
        );
        persistent.execute(
          'INSERT INTO resets(email,code,expires) VALUES(?,?,?)',
          [email, service.digest('$email:code:123456'), service.now + 600],
        );
        service.limit('persisted', 1, 60);
        persistent.close();
        persistent = sqlite3.open(path);
        service = AuthApi(
          persistent,
          'a' * 32,
          (_, _) async {},
          clock: () => time,
          passwordIterations: 10,
        );
        expect(
          persistent.select('SELECT email FROM users').single['email'],
          email,
        );
        expect(
          () => service.limit('persisted', 1, 60),
          throwsA(isA<ApiError>()),
        );
        final response = await service.call(
          Request(
            'POST',
            Uri.parse('https://api.test/auth/password/verify'),
            body: jsonEncode({'email': email, 'code': '123456'}),
          ),
        );
        expect(response.statusCode, 200);
      } finally {
        persistent.close();
        directory.deleteSync(recursive: true);
      }
    },
  );

  test('resend invalidates the old code', () async {
    await request();
    final previousHash = db.select('SELECT code FROM resets').single['code'];
    time = time.add(const Duration(seconds: 60));
    await request();
    // Extremely rare identical random codes are valid by design; the stored
    // challenge always corresponds solely to the last delivery.
    final current = db.select('SELECT code FROM resets').single['code'];
    expect(current, api.digest('$email:code:${sent.last}'));
    if (current != previousHash) {
      expect(
        (await post('password/verify', {'code': sent.first})).statusCode,
        400,
      );
    }
    expect(
      (await post('password/verify', {'code': sent.last})).statusCode,
      200,
    );
  });
}
