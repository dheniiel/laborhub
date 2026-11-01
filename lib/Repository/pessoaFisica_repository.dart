import '../Data/pessoaFisica_dao.dart';
import '../Model/pessoaFisica.dart';


class PessoaFisicaRepository {

       final PessoaFisicaDao _dao = PessoaFisicaDao();

       //Cadastro
       Future<void> Cadastrar(PessoaFisica pf) async {
         await _dao.inserir(pf);

       }



}