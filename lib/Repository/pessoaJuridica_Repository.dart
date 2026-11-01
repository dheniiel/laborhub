import '../Data/pessoaJuridica_dao.dart';
import '../Model/pessoaJuridica.dart';


class UsuariosRepository {

       final PessoaJuridicaDao _dao = PessoaJuridicaDao();

       //Cadastro
       Future<void> Cadastrar(PessoaJuridica pj) async {
         await _dao.inserir(pj);

       }



}