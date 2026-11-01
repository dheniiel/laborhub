import '../Data/endereco_dao.dart';
import '../Model/endereco.dart';


class EnderecoRepository {

       final EnderecoDao _dao = EnderecoDao();

       //Cadastro
       Future<void> Cadastrar(Endereco endereco) async {
         await _dao.inserir(endereco);

       }



}