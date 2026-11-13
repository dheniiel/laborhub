import 'dart:convert';

import 'package:http/http.dart' as http;

class CepRepository {
  final http.Client _client;
  CepRepository({http.Client? client}) : _client = client ?? http.Client();

  // Busca o endereço no ViaCEP. Retorna null se o CEP não existir ou se falhar.
  Future<Map<String, dynamic>?> buscar(String cep) async {
    final numeros = cep.replaceAll(RegExp(r'\D'), '');
    if (numeros.length != 8) return null;

    try {
      final response = await _client
          .get(Uri.parse('https://viacep.com.br/ws/$numeros/json/'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      // CEP com formato válido mas inexistente: o ViaCEP responde {"erro": true}.
      if (body['erro'] != null) return null;

      return body;
    } catch (_) {
      return null;
    }
  }
}