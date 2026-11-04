import 'auth_api.dart';
import '../Model/usuarios.dart';

class UsuariosRepository {
  final AuthApi _api = AuthApi();

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
}
