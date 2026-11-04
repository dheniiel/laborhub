import 'dart:io';

import 'package:laborhub_server/auth.dart';
import 'package:sqlite3/sqlite3.dart';

/// Run ONLY on a trusted administrator's machine, before upgrading old clients.
Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln(
      'Uso: dart run bin/import_legacy.dart backup-legado.db laborhub.sqlite',
    );
    exitCode = 64;
    return;
  }
  final source = sqlite3.open(args[0], mode: OpenMode.readOnly);
  final target = sqlite3.open(args[1]);
  try {
    final api = AuthApi(
      target,
      Platform.environment['RESET_SECRET'] ?? '',
      (_, _) async {},
    );
    final users = source.select(
      'SELECT * FROM usuarios WHERE usuarios_deletado_em IS NULL',
    );
    var imported = 0;
    for (final user in users) {
      final email = (user['usuarios_email'] as String).trim().toLowerCase();
      final password = user['usuarios_senha_hash'] as String;
      if (password == 'remote-managed') {
        throw StateError('Use um backup ANTERIOR à atualização para v2.');
      }
      final hash = await api.hashPassword(password);
      target.execute(
        'INSERT OR IGNORE INTO users(email,password,created,active) VALUES(?,?,?,?)',
        [
          email,
          hash,
          user['usuarios_criado_em'] ??
              DateTime.now().toUtc().toIso8601String(),
          user['usuarios_ativo'] == 1 ? 1 : 0,
        ],
      );
      imported += target.updatedRows;
    }
    stdout.writeln(
      '$imported contas importadas; contas existentes não foram sobrescritas.',
    );
  } finally {
    source.close();
    target.close();
  }
}
