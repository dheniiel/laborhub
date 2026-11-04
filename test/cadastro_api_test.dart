import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:laborhub/Data/app_database.dart';
import 'package:laborhub/Repository/auth_api.dart';
import 'package:laborhub/Repository/cadastro_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('registration sends entered password and keeps credentials out of local SQLite', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final directory = await Directory.systemTemp.createTemp(
      'laborhub-cadastro-',
    );
    await databaseFactory.setDatabasesPath(directory.path);
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response('{}', 201);
    });
    final repository = CadastroRepository(
      api: AuthApi(baseUrl: 'https://api.example.com', client: client),
    );
    final db = await AppDatabase.instance.database;
    try {
      final id = await repository.cadastrar(
        senha: 'senha digitada pelo usuario',
        usuario: {
          'usuarios_email': 'cliente@example.com',
          // The address screen may still build a local model with a BCrypt hash.
          'usuarios_senha_hash': 'hash-calculado-no-cliente',
          'usuarios_ativo': 1,
          'usuarios_criado_em': DateTime.now().toIso8601String(),
        },
        endereco: {
          'endereco_nome': 'Principal',
          'endereco_rua': 'Rua Teste',
          'endereco_cep': '74000000',
          'endereco_numero': '10',
          'endereco_cidade': 'Goiania',
          'endereco_uf': 'GO',
        },
        pessoaFisica: {'pf_nome': 'Cliente', 'pf_sobrenome': 'Teste'},
      );
      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/auth/register');
      expect(jsonDecode(requests.single.body), {
        'email': 'cliente@example.com',
        'password': 'senha digitada pelo usuario',
      });
      final users = await db.query(
        'usuarios',
        where: 'usuarios_id = ?',
        whereArgs: [id],
      );
      expect(users.single['usuarios_senha_hash'], 'remote-managed');
      expect((await db.query('endereco')).single['endereco_usuarios_id'], id);
    } finally {
      client.close();
      await db.close();
      await directory.delete(recursive: true);
    }
  });
}
