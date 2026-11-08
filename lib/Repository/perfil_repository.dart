import 'auth_api.dart';
import '../Data/sessao_dao.dart';
import '../Model/usuarios.dart';

class PerfilRepository {
  final AuthApi _api;
  final SessaoDao _dao;
  PerfilRepository({AuthApi? api, SessaoDao? dao})
    : _api = api ?? AuthApi(),
      _dao = dao ?? SessaoDao();

  // Dados guardados no SQLite: a tela de edição abre mesmo offline.
  Future<Map<String, Object?>> carregar() => _dao.buscarPerfil();

  // Grava no MySQL pela API e atualiza a cópia local com a resposta.
  Future<Usuarios> atualizar({
    required Map<String, Object?> usuario,
    required Map<String, Object?> endereco,
    Map<String, Object?>? pessoaFisica,
    Map<String, Object?>? pessoaJuridica,
  }) async {
    if ((pessoaFisica == null) == (pessoaJuridica == null)) {
      throw ArgumentError('Informe pessoa física ou pessoa jurídica, apenas uma.');
    }

    final sessao = await _dao.buscar();
    if (sessao == null) {
      throw const AuthException('Sua sessão expirou. Entre novamente.', 401);
    }

    final body = await _api.post('auth/profile', {
      'usuario': usuario,
      'endereco': endereco,
      if (pessoaFisica != null) 'pessoaFisica': pessoaFisica,
      if (pessoaJuridica != null) 'pessoaJuridica': pessoaJuridica,
    }, token: sessao.token);

    await _dao.salvar(sessao.token, body);
    return Usuarios.fromMap(body);
  }
}