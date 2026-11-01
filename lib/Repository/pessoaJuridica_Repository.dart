import '../Data/pessoaJuridica_dao.dart';
import '../Model/pessoJuridica.dart';


class UsuariosRepository {

       final PessoajuridicaDao _dao = PessoajuridicaDao();

       //Cadastro
       Future<void> Cadastrar(PessoaJuridica pj) async {
         await _dao.inserir(pj);

       }



}