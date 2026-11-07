import 'auth_api.dart';
import '../Data/sessao_dao.dart';
import '../Model/usuarios.dart';

class UsuariosRepository {
  final AuthApi _api;
  final SessaoDao _sessaoDao;
  UsuariosRepository({AuthApi? api, SessaoDao? sessaoDao})
    : _api = api ?? AuthApi(),
      _sessaoDao = sessaoDao ?? SessaoDao();

  //Login: valida na API, abre a sessão e guarda usuário e perfil no SQLite para uso offline.
  Future<(Usuarios, String?)> Autenticar(String email, String senha) async {
    final body = await _api.post('auth/login', {
      'email': email.trim(),
      'password': senha,
    });
    await _sessaoDao.salvar(body['token'] as String, body);
    return (Usuarios.fromMap(body), body['tipo'] as String?);
  }
}
