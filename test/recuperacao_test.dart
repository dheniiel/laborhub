import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:laborhub/main.dart';
import 'package:laborhub/Repository/auth_api.dart';
import 'package:laborhub/Telas/recuperarSenha.dart';

class FakeRecovery extends RecuperacaoRepository {
  int requests = 0;
  bool fail = false;
  String? changed;
  @override
  Future<void> solicitar(String email) async {
    requests++;
    if (fail) throw const AuthException('Muitas tentativas. Aguarde.');
  }

  @override
  Future<String> validar(String email, String codigo) async {
    if (codigo != '123456') throw const AuthException('Código inválido.');
    return 'authorization';
  }

  @override
  Future<void> redefinir(
    String email,
    String token,
    String senha,
    String confirmacao,
  ) async {
    expect(token, 'authorization');
    expect(confirmacao, senha);
    changed = senha;
  }
}

void main() {
  testWidgets('login opens recovery from forgot password', (tester) async {
    await tester.pumpWidget(const LaborHUBapp());
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();
    expect(find.text('Redefinir senha'), findsOneWidget);
  });
  testWidgets('email, six digit paste, confirmation, success and back', (
    tester,
  ) async {
    final repository = FakeRecovery();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => RecuperarSenha(repository: repository),
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o email'), findsOneWidget);
    expect(repository.requests, 0);
    await tester.enterText(find.byType(TextFormField), 'cliente@example.com');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(repository.requests, 1);
    expect(find.byType(TextFormField), findsNWidgets(6));
    await tester.enterText(find.byType(TextFormField).first, '123456');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'nova senha');
    await tester.enterText(find.byType(TextFormField).last, 'diferente');
    await tester.ensureVisible(find.text('Redefinir'));
    await tester.tap(find.text('Redefinir'));
    await tester.pumpAndSettle();
    expect(find.text('As senhas não conferem.'), findsOneWidget);
    expect(repository.changed, isNull);
    await tester.enterText(find.byType(TextFormField).last, 'nova senha');
    await tester.tap(find.text('Redefinir'));
    await tester.pumpAndSettle();
    expect(repository.changed, 'nova senha');
    expect(find.text('Abrir'), findsOneWidget);
  });
  testWidgets('request failure stays on email and enables retry', (
    tester,
  ) async {
    final repository = FakeRecovery()..fail = true;
    await tester.pumpWidget(
      MaterialApp(home: RecuperarSenha(repository: repository)),
    );
    await tester.enterText(find.byType(TextFormField), 'cliente@example.com');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(find.text('Muitas tentativas. Aguarde.'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });
  test('client sends reset fields and preserves server errors', () async {
    final api = AuthApi(
      baseUrl: 'https://api.example.com',
      client: MockClient((request) async {
        expect(request.url.path, '/auth/password/reset');
        expect(jsonDecode(request.body)['resetToken'], 'token');
        return http.Response(jsonEncode({'message': 'Expirado'}), 400);
      }),
    );
    await expectLater(
      RecuperacaoRepository(api: api)
          .redefinir('a@b.com', 'token', 'password', 'password'),
      throwsA(
        isA<AuthException>().having((e) => e.mensagem, 'message', 'Expirado'),
      ),
    );
  });
}
