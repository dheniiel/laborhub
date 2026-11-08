import 'auth_api.dart';
import '../Data/sessao_dao.dart';
import '../Model/solicitacao.dart';

class SolicitacaoRepository {
  final AuthApi _api;
  final SessaoDao _dao;
  SolicitacaoRepository({AuthApi? api, SessaoDao? dao})
    : _api = api ?? AuthApi(),
      _dao = dao ?? SessaoDao();

  // Solicitações do cliente logado (MySQL, via API).
  Future<List<Solicitacao>> Listar() async {
    final body = await _api.post('solicitacoes', {}, token: await _token());
    return (body['solicitacoes'] as List)
        .map((item) => Solicitacao.fromMap(Map<String, Object?>.from(item as Map)))
        .toList();
  }

  // Cancela no banco; a tela remove o item da lista após o sucesso.
  Future<void> cancelar(int solicitacaoId) async {
    await _api.post(
      'solicitacoes/cancelar',
      {'solicitacao_id': solicitacaoId},
      token: await _token(),
    );
  }

  Future<String> _token() async {
    final sessao = await _dao.buscar();
    if (sessao == null) {
      throw const AuthException('Sua sessão expirou. Entre novamente.', 401);
    }
    return sessao.token;
  }
}