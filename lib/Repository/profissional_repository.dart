import 'package:laborhub/Model/avaliacao.dart';

import 'auth_api.dart';
import '../Data/sessao_dao.dart';
import '../Model/profissional.dart';
import '../Model/avaliacao.dart';

class ProfissionalRepository{
  final AuthApi _api;
  final SessaoDao _dao;
  ProfissionalRepository({AuthApi? api, SessaoDao? dao})
    : _api = api ?? AuthApi(),
      _dao = dao ?? SessaoDao();

  // Serviços dos profissionais cadastrados no MySQL, via API.
  Future<List<Profissional>> Listar () async {
    final body = await _api.post('profissionais', {}, token: await _token());
    return (body['profissionais'] as List)
        .map((item) => Profissional.fromMap(Map<String, Object?>.from(item as Map)))
        .toList();
  }

  Future<List<Avaliacao>> listarAvaliacoes(int profissionalId) async {
    final body = await _api.post(
      'profissional/avaliacoes',
      {'profissional_usuarios_id': profissionalId},
      token: await _token(),

    );
      final lista = body['avaliacoes'] as List<dynamic>;

      return lista
        .map((item) => Avaliacao.fromMap(item as Map<String, dynamic>)).toList();

  }

  Future<String> _token() async {
    final sessao = await _dao.buscar();
    if (sessao == null) {
      throw const AuthException('Sua sessão expirou. Entre novamente.', 401);
    }
    return sessao.token;
  }
}