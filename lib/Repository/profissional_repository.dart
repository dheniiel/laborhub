import 'auth_api.dart';
import '../Data/sessao_dao.dart';
import '../Model/profissional.dart';

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

  Future<String> _token() async {
    final sessao = await _dao.buscar();
    if (sessao == null) {
      throw const AuthException('Sua sessão expirou. Entre novamente.', 401);
    }
    return sessao.token;
  }
}