import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:laborhub/Repository/auth_api.dart';
import 'package:laborhub/Repository/cadastro_repository.dart';

void main() {
  test('registration sends profile to the API without local ids or hashes', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response('{"usuarios_id": 7}', 201);
    });
    final repository = CadastroRepository(
      api: AuthApi(baseUrl: 'https://api.example.com', client: client),
    );

    final id = await repository.cadastrar(
      senha: 'senha digitada pelo usuario',
      usuario: {
        'usuarios_email': 'cliente@example.com',
        // The address screen may still build a local model with a BCrypt hash.
        'usuarios_senha_hash': 'hash-calculado-no-cliente',
        'usuarios_telefone': '62999998888',
      },
      endereco: {
        'endereco_rua': 'Rua Teste',
        'endereco_cep': '74000000',
        'endereco_numero': '10',
        'endereco_cidade': 'Goiania',
        'endereco_uf': 'GO',
        'endereco_usuarios_id': 0,
      },
      pessoaFisica: {
        'pf_nome': 'Cliente',
        'pf_sobrenome': 'Teste',
        'pf_tipo': 'Cliente',
        'pf_usuarios_id': 0,
      },
    );

    expect(id, 7);
    expect(requests, hasLength(1));
    expect(requests.single.url.path, '/auth/register');
    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(body['email'], 'cliente@example.com');
    expect(body['password'], 'senha digitada pelo usuario');
    expect(body['usuario'], isNot(contains('usuarios_senha_hash')));
    expect(body['endereco'], isNot(contains('endereco_usuarios_id')));
    expect(body['pessoaFisica'], {
      'pf_nome': 'Cliente',
      'pf_sobrenome': 'Teste',
      'pf_tipo': 'Cliente',
    });
    expect(body, isNot(contains('pessoaJuridica')));
  });

  test('registration requires exactly one person type', () {
    final repository = CadastroRepository(
      api: AuthApi(baseUrl: 'https://api.example.com'),
    );
    expect(
      () => repository.cadastrar(senha: 'senha123', usuario: {}, endereco: {}),
      throwsArgumentError,
    );
  });

  test('API error message is shown to the user', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({'message': 'Email, CPF ou CNPJ já cadastrado.'}),
        409,
      ),
    );
    final repository = CadastroRepository(
      api: AuthApi(baseUrl: 'https://api.example.com', client: client),
    );
    expect(
      () => repository.cadastrar(
        senha: 'senha123',
        usuario: {'usuarios_email': 'a@example.com'},
        endereco: {},
        pessoaJuridica: {'pj_tipo': 'Cliente'},
      ),
      throwsA(
        isA<AuthException>().having(
          (e) => e.mensagem,
          'mensagem',
          'Email, CPF ou CNPJ já cadastrado.',
        ),
      ),
    );
  });
}
