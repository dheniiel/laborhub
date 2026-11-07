import 'auth_api.dart';
import '../Data/sessao_dao.dart';
import '../Model/sessao.dart';

class SessaoRepository {
  final AuthApi _api;
  final SessaoDao _dao;
  SessaoRepository({AuthApi? api, SessaoDao? dao})
    : _api = api ?? AuthApi(),
      _dao = dao ?? SessaoDao();

  // Sessão guardada no SQLite, sem acessar a rede: permite abrir o app offline.
  Future<Sessao?> restaurar() async {
    final sessao = await _dao.buscar();
    if (sessao == null) return null;
    if (sessao.expirada) {
      await _dao.limpar();
      return null;
    }
    return sessao;
  }

  // Confere a sessão na API e atualiza a cópia local.
  // Sem conexão, mantém a sessão local; com 401 (expirada, encerrada ou senha trocada), apaga.
  Future<Sessao?> validar(Sessao sessao) async {
    try {
      final body = await _api.post('auth/session', {}, token: sessao.token);
      await _dao.salvar(sessao.token, body);
      return await _dao.buscar();
    } on AuthException catch (erro) {
      if (erro.status == 401) {
        await _dao.limpar();
        return null;
      }
      return sessao;
    }
  }

  // Encerra a sessão na API (quando houver conexão) e apaga os dados do aparelho.
  Future<void> sair() async {
    final sessao = await _dao.buscar();
    try {
      if (sessao != null) {
        await _api.post('auth/logout', {}, token: sessao.token);
      }
    } on AuthException {
      // Offline: os dados locais são apagados mesmo assim; o token expira no servidor.
    } finally {
      await _dao.limpar();
    }
  }
}
