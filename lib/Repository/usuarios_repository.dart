import '../Data/usuarios_dao.dart';
import '../Model/usuarios.dart';


class UsuariosRepository {

       final UsuariosDao _dao = UsuariosDao();

       //Cadastro
       Future<void> Cadastrar(Usuarios usuarios) async {
         await _dao.inserir(usuarios);

       }



}