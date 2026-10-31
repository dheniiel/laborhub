import '../Data/PessoaFisica_dao.dart';
import '../Model/PessoaFisica.dart';


class PessoaFisicaRepository {

       final PessoaFisicaDao _dao = PessoaFisicaDao();

       //Cadastro
       Future<void> Cadastrar(PessoaFisica pf) async {
         await _dao.inserir(pf);

       }



}