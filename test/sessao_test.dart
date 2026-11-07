import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:laborhub/Data/app_database.dart';
import 'package:laborhub/Repository/auth_api.dart';
import 'package:laborhub/Repository/sessao_repository.dart';
import 'package:laborhub/Repository/usuarios_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Resposta da API em /auth/login (com token) e /auth/session (sem token).
Map<String, Object?> resposta({String? token, Duration validade = const Duration(days: 30)}) => {
  'usuarios_id': 1,
  'usuarios_email': 'cliente@example.com',
  'usuarios_imagem': '',
  'usuarios_telefone': '62999998888',
  'usuarios_senha_hash': '',
  'usuarios_ativo': 1,
  'usuarios_is_admin': 0,
  'usuarios_criado_em': '2026-11-07T18:00:00Z',
  'tipo': 'Cliente',
  'pessoaFisica': {
    'pf_id': 1,
    'pf_nome': 'Ana',
    'pf_sobrenome': 'Silva',
    'pf_dataNascimento': '2000-01-31',
    'pf_genero': 'Feminino',
    'pf_cpf': '52998224725',
    'pf_tipo': 'Cliente',
    'pf_usuarios_id': 1,
  },
  'pessoaJuridica': null,
  'enderecos': [
    {
      'endereco_id': 1,
      'endereco_nome': 'Principal',
      'endereco_rua': 'Rua A',
      'endereco_bairro': 'Centro',
      'endereco_cep': '74000000',
      'endereco_complemento': null,
      'endereco_numero': '10',
      'endereco_descricao': null,
      'endereco_cidade': 'Goiânia',
      'endereco_uf': 'GO',
      'endereco_usuarios_id': 1,
    },
  ],
  if (token != null) 'token': token,
  'sessao_expira_em': DateTime.now().toUtc().add(validade).toIso8601String(),
};

AuthApi api(MockClientHandler handler) =>
    AuthApi(baseUrl: 'https://api.example.com', client: MockClient(handler));

// Simula falta de conexão.
final offline = api((_) async => throw const SocketException('offline'));

Future<void> entrar({Duration validade = const Duration(days: 30)}) =>
    UsuariosRepository(
      api: api((_) async => http.Response(
        jsonEncode(resposta(token: 'token-1', validade: validade)),
        200,
      )),
    ).Autenticar('cliente@example.com', 'senha123');

void main() {
  late Directory diretorio;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    diretorio = await Directory.systemTemp.createTemp('laborhub-sessao-');
    await databaseFactory.setDatabasesPath(diretorio.path);
  });

  tearDown(() async {
    await AppDatabase.instance.fechar();
    await diretorio.delete(recursive: true);
  });

  test('login saves session and profile in SQLite for offline use', () async {
    await entrar();

    final sessao = await SessaoRepository(api: offline).restaurar();
    expect(sessao!.token, 'token-1');
    expect(sessao.tipo, 'Cliente');
    expect(sessao.usuario.usuarios_email, 'cliente@example.com');

    final db = await AppDatabase.instance.database;
    expect((await db.query('pessoaFisica')).single['pf_cpf'], '52998224725');
    expect((await db.query('endereco')).single['endereco_cidade'], 'Goiânia');
  });

  test('validation sends bearer token and refreshes local data', () async {
    await entrar();
    final requests = <http.Request>[];
    final repository = SessaoRepository(
      api: api((request) async {
        requests.add(request);
        final dados = resposta()..['usuarios_telefone'] = '62988887777';
        return http.Response(jsonEncode(dados), 200);
      }),
    );

    final sessao = await repository.validar((await repository.restaurar())!);

    expect(requests.single.url.path, '/auth/session');
    expect(requests.single.headers['Authorization'], 'Bearer token-1');
    expect(sessao!.token, 'token-1');
    expect(sessao.usuario.usuarios_telefone, '62988887777');
  });

  test('offline validation keeps the local session', () async {
    await entrar();
    final repository = SessaoRepository(api: offline);

    final sessao = await repository.validar((await repository.restaurar())!);

    expect(sessao, isNotNull);
    expect(await repository.restaurar(), isNotNull);
  });

  test('401 from the API clears the local session and data', () async {
    await entrar();
    final repository = SessaoRepository(
      api: api((_) async => http.Response(
        '{"message":"Sessão inválida ou expirada. Entre novamente."}',
        401,
      )),
    );

    expect(await repository.validar((await repository.restaurar())!), isNull);
    expect(await repository.restaurar(), isNull);
    final db = await AppDatabase.instance.database;
    expect(await db.query('usuarios'), isEmpty);
  });

  test('expired local session is discarded without network', () async {
    await entrar(validade: const Duration(seconds: -1));
    expect(await SessaoRepository(api: offline).restaurar(), isNull);
  });

  test('logout calls the API and clears local data, even offline', () async {
    await entrar();
    final requests = <http.Request>[];
    await SessaoRepository(
      api: api((request) async {
        requests.add(request);
        return http.Response('{"message":"Sessão encerrada."}', 200);
      }),
    ).sair();
    expect(requests.single.url.path, '/auth/logout');
    expect(await SessaoRepository(api: offline).restaurar(), isNull);

    await entrar();
    await SessaoRepository(api: offline).sair();
    expect(await SessaoRepository(api: offline).restaurar(), isNull);
  });
}
