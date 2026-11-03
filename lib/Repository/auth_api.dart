import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthException implements Exception {
  final String mensagem;
  const AuthException(this.mensagem);
  @override
  String toString() => mensagem;
}

class AuthApi {
  final http.Client _client;
  final String baseUrl;
  AuthApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL');

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, String> data,
  ) async {
    final uri = Uri.tryParse(baseUrl);
    const local = bool.fromEnvironment('ALLOW_LOCAL_HTTP');
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && !(local && uri.scheme == 'http'))) {
      throw const AuthException(
        'Configure o endereço seguro da API do LaborHub.',
      );
    }
    try {
      final response = await _client
          .post(
            Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 30));
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        throw AuthException(
          body['message'] as String? ?? 'Não foi possível concluir.',
        );
      }
      return body;
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Não foi possível conectar. Verifique sua conexão e tente novamente.',
      );
    }
  }
}

class RecuperacaoRepository {
  final AuthApi api;
  RecuperacaoRepository({AuthApi? api}) : api = api ?? AuthApi();
  Future<void> solicitar(String email) async {
    await api.post('auth/password/request', {'email': email.trim()});
  }

  Future<String> validar(String email, String codigo) async {
    final body = await api.post('auth/password/verify', {
      'email': email.trim(),
      'code': codigo,
    });
    return body['resetToken'] as String;
  }

  Future<void> redefinir(
    String email,
    String token,
    String senha,
    String confirmacao,
  ) async {
    await api.post('auth/password/reset', {
      'email': email.trim(),
      'resetToken': token,
      'password': senha,
      'confirmation': confirmacao,
    });
  }
}
