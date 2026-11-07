import 'auth_api.dart';
import '../Data/usuarios_dao.dart';
import '../Data/pessoaFisica_dao.dart';
import '../Data/pessoaJuridica_dao.dart';
import '../Model/usuarios.dart';

class UsuariosRepository {
  final AuthApi _api = AuthApi();
  final UsuariosDao _dao = UsuariosDao();
  final PessoaFisicaDao _pfDao = PessoaFisicaDao();
  final PessoajuridicaDao _pjDao = PessoajuridicaDao();

  //Cadastro
  Future<void> Cadastrar(Usuarios usuarios) async {
    await _api.post('auth/register', {
      'email': usuarios.usuarios_email,
      'password': usuarios.usuarios_senha_hash,
    });
  }

  //Login
  Future<Usuarios?> Autenticar(String email, String senha) async {
    final body = await _api.post('auth/login', {
      'email': email.trim(),
      'password': senha,
    });
    return Usuarios.fromMap(body);
  }
  
  Future<Usuarios?> BuscarLocal(String email) {
    return _dao.buscarPorEmail(email.trim());
  }

  Future<String?> BuscarTipo(int usuarioId) async {
    final pf = await _pfDao.buscarPorUsuario(usuarioId);
    if (pf != null) return pf.pf_tipo;

    final pj = await _pjDao.buscarPorUsuario(usuarioId);
    return pj?.pj_tipo;
  }

}
