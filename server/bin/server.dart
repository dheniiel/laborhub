import 'dart:io';

import 'package:laborhub_server/auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:sqlite3/sqlite3.dart';

Future<void> main() async {
  final env = Platform.environment;
  String required(String name) {
    final value = env[name];
    if (value == null || value.isEmpty) throw StateError('Configure $name');
    return value;
  }

  final secret = required('RESET_SECRET');
  final from = required('SMTP_FROM');
  final smtp = SmtpServer(
    required('SMTP_HOST'),
    port: int.parse(env['SMTP_PORT'] ?? '587'),
    username: required('SMTP_USER'),
    password: required('SMTP_PASSWORD'),
    ssl: env['SMTP_SSL'] == 'true',
    allowInsecure: false,
  );
  final database = sqlite3.open(env['DATABASE_PATH'] ?? 'laborhub.sqlite');
  final api = AuthApi(database, secret, (email, code) async {
    await send(
      Message()
        ..from = Address(from, 'LaborHub')
        ..recipients.add(email)
        ..subject = 'Código para redefinir sua senha'
        ..text =
            'Seu código é $code. Ele expira em 10 minutos e permite até 5 tentativas. '
            'Se você não solicitou a recuperação, ignore este email.',
      smtp,
    ).timeout(const Duration(seconds: 20));
  });
  final server = await io.serve(
    (Request request) {
      final connection =
          request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
      return api.call(
        request.change(
          context: {'clientIp': connection?.remoteAddress.address ?? 'unknown'},
        ),
      );
    },
    env['HOST'] ?? '127.0.0.1',
    int.parse(env['PORT'] ?? '8080'),
  );
  server.idleTimeout = const Duration(seconds: 30);
  print('LaborHub API na porta ${server.port}');
}
