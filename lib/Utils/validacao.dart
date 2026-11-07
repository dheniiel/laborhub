

class Validacao {

  //Função usada para cadastro de pessoa fisica
  static String? nome(String? valor){
    if(valor == null || valor.trim().isEmpty) {
      return "Informe um nome!";

    }

    final contemNumero = RegExp(r'\d').hasMatch(valor);

    if(contemNumero){
      return "Seu nome não pode conter números!";
    }

    if(valor.length < 3 || valor.length >= 15) {
      return "Seu nome não possui caracter suficiente!";
    }


  }

  //Validaçao usada para cadastro de pessoa fisica
  static String? sobrenome(String? valor){
    if(valor == null || valor.trim().isEmpty) {
      return "Informe seu sobrenome!";

    }

    final contemNumero = RegExp(r'\d').hasMatch(valor);

    if(contemNumero){
      return "Seu nome não pode conter números!";
    }

    if(valor.length < 3 || valor.length >= 45) {
      return "Seu sobrenome não possui caracter suficiente!";
    }


  }


  // Validação para data de nascimento em cadastro de pessoas fisica
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


  static String? razaoSocial(String? valor){
    if(valor == null || valor.trim().isEmpty) {
      return "Informe a Razão Social!";

    }

    final contemNumero = RegExp(r'\d').hasMatch(valor);

    if(valor.length < 3 || valor.length >= 20) {
      return "Sua Razão Social não possui caracter suficiente!";
    }


  }

  static String? nomeFantasia(String? valor){
    if(valor == null || valor.trim().isEmpty) {
      return "Informe o nome fantasia!";

    }

    final contemNumero = RegExp(r'\d').hasMatch(valor);

    if(valor.length < 3 || valor.length >= 15) {
      return "O nome fanstasia não possui caracter suficiente!";
    }




  }

  static String? cnpj(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe o CNPJ';
    }

    final texto = valor.trim();

    if (!RegExp(r'^[0-9./\-\s]+$').hasMatch(texto)) {
      return 'Informe um CNPJ numérico válido';
    }

    final numeros = texto.replaceAll(RegExp(r'\D'), '');

    if (numeros.length != 14) {
      return 'O CNPJ deve ter 14 dígitos';
    }

    if (RegExp(r'^(\d)\1{13}$').hasMatch(numeros)) {
      return 'CNPJ inválido';
    }

    final digitos = numeros.split('').map(int.parse).toList();

    int calcularDigito(List<int> pesos) {
      var soma = 0;

      for (var i = 0; i < pesos.length; i++) {
        soma += digitos[i] * pesos[i];
      }

      final resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    }

    final primeiro = calcularDigito(
      [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2],
    );

    if (digitos[12] != primeiro) {
      return 'CNPJ inválido';
    }

    final segundo = calcularDigito(
      [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2],
    );

    if (digitos[13] != segundo) {
      return 'CNPJ inválido';
    }

    return null;
  }


  static String? rua(String? valor){
    if(valor == null || valor.trim().isEmpty) {
      return "Informe sua rua/avenida";

    }

    if(valor.length < 3 || valor.length >= 100) {
      return "O campo rua não possui caracter suficiente!";
    }


  }

  static String? bairro(String? valor){
    if(valor == null || valor.trim().isEmpty) {
      return "Informe seu bairro";

    }

    if(valor.length < 3 || valor.length >= 50) {
      return "O campo bairro não possui caracter suficiente!";
    }


  }

  static String? cep(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe o CEP';
    }

    if (!RegExp(r'^\d{5}-?\d{3}$').hasMatch(valor.trim())) {
      return 'Informe um CEP válido com 8 números';
    }

    return null;
  }

  static String? cidade(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe a cidade';
    }

    // Aceita letras, acentos, espaços, apóstrofos e hífens.
    if (!RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ]+(?:[ '\u2019-][A-Za-zÀ-ÖØ-öø-ÿ]+)*$")
        .hasMatch(valor.trim())) {
      return 'Informe um nome de cidade válido';
    }

    return null;
  }

  static String? uf(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe a UF';
    }

    const ufs = {
      'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF',
      'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA',
      'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS',
      'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
    };

    if (!ufs.contains(valor.trim().toUpperCase())) {
      return 'Informe uma UF válida, como GO';
    }

    return null;
  }



  static String? servicosNome(String? valor){
    if(valor == null || valor.trim().isEmpty) {
      return "Informe seu serviço!";

    }

    final contemNumero = RegExp(r'\d').hasMatch(valor);

    if(contemNumero){
      return "O campo de serviço não pode conter números!";
    }

    if(valor.length < 3 || valor.length >= 15) {
      return "O campo de serviço não possui caracter suficiente!";
    }


  }



}
