import '../Data/usuarios_dao.dart';
import '../Model/usuarios.dart';


class UsuariosRepository {

       final UsuariosDao _dao = UsuariosDao();

       //Cadastro
       Future<void> Cadastrar(Usuarios usuarios) async {
         await _dao.inserir(usuarios);

       }

      //Login
      Future<Usuarios?> Autenticar(String email, String senha) async {
        final usuario = await _dao.buscarPorEmail(email.trim());

        if (usuario == null) return null;
        if (!usuario.usuarios_ativo) return null;

        if (usuario.usuarios_senha_hash != senha) return null;

        return usuario;

      }


}