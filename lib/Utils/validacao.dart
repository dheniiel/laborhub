

class Validacao {

  //Função usada em Telas->Clientes (Tela de cadastro)
  static String? nome(String? valor){
    if(valor == null || valor.trim().isEmpty) {
      return "Informe um nome!";

    }

    if(RegExp('r[0-9]').hasMatch(valor)){
      return "Seu nome não pode conter números!";
    }

    if(valor.length < 3 || valor.length >= 15) {
      return "Seu nome não possui caracter suficiente!";
    }


  }

  //Validaçao usada em Telas->Clientes (TELA DE CADASTRO)
  static String? sobrenome(String? valor){
    if(valor == null || valor.trim().isEmpty) {
      return "Informe seu sobrenome!";

    }

    if(RegExp('r[0-9]').hasMatch(valor)){
      return "Seu sobrenome não pode conter números!";
    }

    if(valor.length < 3 || valor.length >= 45) {
      return "Seu sobrenome não possui caracter suficiente!";
    }


  }


  // Validação para data de nasccimente Usada em cadastro de clientes
  static String? data(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe sua data de nascimento!';
    }

    final texto = valor.trim();

    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(texto)) {
      return 'Use o formato dd/mm/aaaa.';
    }

    final partes = texto.split('/');
    final dia = int.parse(partes[0]);
    final mes = int.parse(partes[1]);
    final ano = int.parse(partes[2]);

    final nascimento = DateTime(ano, mes, dia);

    // DateTime ajusta datas inválidas; por isso conferimos os valores.
    if (nascimento.day != dia ||
        nascimento.month != mes ||
        nascimento.year != ano) {
      return 'Data inválida!';
    }

    final hoje = DateTime.now();

    if (nascimento.isAfter(hoje)) {
      return 'A data de nascimento não pode estar no futuro.';
    }

    var idade = hoje.year - nascimento.year;

    if (hoje.month < mes ||
        (hoje.month == mes && hoje.day < dia)) {
      idade--;
    }

    if (idade < 16) {
      return 'É necessário ter pelo menos 16 anos.';
    }

    if (idade >= 100) {
      return 'A idade deve ser inferior a 100 anos.';
    }

    return null;
  }

  // Validaçao de CPF usada em tela de cadastro de usuario
  static String? cpf(String? valor) {
    final cpf = (valor ?? '').replaceAll(RegExp(r'\D'), '');

    if (cpf.isEmpty) {
      return 'Informe o CPF.';
    }

    if (cpf.length != 11) {
      return 'O CPF deve conter 11 números.';
    }

    // Rejeita sequências como 111.111.111-11.
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
      return 'CPF inválido.';
    }

    final numeros = cpf.split('').map(int.parse).toList();

    for (var tamanho = 9; tamanho <= 10; tamanho++) {
      var soma = 0;

      for (var i = 0; i < tamanho; i++) {
        soma += numeros[i] * (tamanho + 1 - i);
      }

      var digito = (soma * 10) % 11;

      if (digito == 10) digito = 0;

      if (numeros[tamanho] != digito) {
        return 'CPF inválido.';
      }
    }

    return null;
  }
  //Validação usada em tela de cadastro
  static String? telefone(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe o telefone';
    }

    final numeros = valor.replaceAll(RegExp(r'\D'), '');

    // DDD + fixo com 8 dígitos ou celular com 9 dígitos.
    final formato = RegExp(r'^[1-9]{2}(?:[2-5]\d{7}|9\d{8})$');

    if (!formato.hasMatch(numeros)) {
      return 'Informe um telefone válido com DDD';
    }

    return null;
  }

  static String? email(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe o email';
    }

    final email = valor.trim();
    final formato = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (!formato.hasMatch(email)) {
      return 'Informe um email válido';
    }

    return null;
  }


  static String? senha(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe uma senha';
    }

   if(valor.length <= 6){
     return "Sua senha precisa ter mais 6 caracteres!";
   }

    return null;
  }


}
