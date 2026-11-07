import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:laborhub/Formularios/forms.dart';
import 'dart:convert';
import '../Repository/auth_api.dart';
import '../Model/endereco.dart';
import '../Utils/validacao.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../Repository/cadastro_repository.dart';
import '../Model/usuarios.dart';
import '../Model/pessoJuridica.dart';
import '../Model/pessoaFisica.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:path_provider/path_provider.dart';
import 'login.dart';


class EnderecoTela  extends StatefulWidget{

  final String email;
  final String telefone;
  final String senha;
  final Uint8List? fotoPerfil;
  final bool pessoaFisica;

  // Pessoa física.
  final String? nome;
  final String? sobrenome;
  final String? dataNascimento;
  final String? genero;
  final String? cpf;

  // Pessoa jurídica.
  final String? razaoSocial;
  final String? nomeFantasia;
  final String? dataFundacao;
  final String? cnpj;

  const EnderecoTela({
    super.key,
    required this.pessoaFisica,
    required this.email,
    required this.telefone,
    required this.senha,
    this.fotoPerfil,
    this.nome,
    this.sobrenome,
    this.dataNascimento,
    this.genero,
    this.cpf,
    this.razaoSocial,
    this.nomeFantasia,
    this.dataFundacao,
    this.cnpj,
  });


  @override
    State<EnderecoTela> createState() => _EnderecoTelaState();

}

class _EnderecoTelaState extends State<EnderecoTela> {

  final _formKey = GlobalKey<FormState>();

  final _endereco_rua = TextEditingController();
  final _endereco_bairro = TextEditingController();
  final _endereco_cep = TextEditingController();
  final _endereco_numero = TextEditingController();
  final _endereco_complemento = TextEditingController();
  final _endereco_cidade = TextEditingController();
  final _endereco_uf = TextEditingController();
  final _endereco_nome = TextEditingController();

  @override
  void dispose() {
    _endereco_rua.dispose();
    _endereco_numero.dispose();
    _endereco_bairro.dispose();
    _endereco_cep.dispose();
    _endereco_complemento.dispose();
    _endereco_cidade.dispose();
    _endereco_uf.dispose();
    super.dispose();
  }


  final _mascaraCep = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
  );

  Future<String> _salvarFotoPerfil() async {
    final foto = widget.fotoPerfil;

    // Sem foto, guarda um texto vazio no banco.
    if (foto == null || foto.isEmpty) {
      return '';
    }

    // Local de armazenamento do aplicativo.
    final diretorio = await getApplicationDocumentsDirectory();

    // Cria a pasta de fotos, caso ainda não exista.
    final pasta = Directory('${diretorio.path}/fotos_perfil');
    await pasta.create(recursive: true);

    // Nome único. Os bytes da imagem são preservados.
    final nome = 'perfil_${DateTime.now().microsecondsSinceEpoch}.img';
    final arquivo = File('${pasta.path}/$nome');

    // Salva a foto recebida da tela anterior.
    await arquivo.writeAsBytes(foto, flush: true);

    // Retorna somente o caminho para guardar no banco.
    return arquivo.path;
  }

  Future<void> _finalizarCadastro() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    String caminhoFoto = '';
    bool cadastroSalvo = false;

    try {
      // Confere os dados obrigatórios recebidos da outra tela.
      String obrigatorio(String? valor, String campo) {
        if (valor == null || valor.trim().isEmpty) {
          throw FormatException('Informe $campo.');
        }

        return valor.trim();
      }

      // Aceita nascimento em dd/MM/yyyy ou yyyy-MM-dd.
      DateTime converterNascimento(String texto) {
        final valor = texto.trim();

        int dia;
        int mes;
        int ano;

        if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(valor)) {
          final partes = valor.split('/');
          dia = int.parse(partes[0]);
          mes = int.parse(partes[1]);
          ano = int.parse(partes[2]);
        } else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(valor)) {
          final partes = valor.split('-');
          ano = int.parse(partes[0]);
          mes = int.parse(partes[1]);
          dia = int.parse(partes[2]);
        } else {
          throw const FormatException(
            'Data de nascimento inválida. Use dd/MM/yyyy.',
          );
        }

        final data = DateTime(ano, mes, dia);

        if (data.year != ano || data.month != mes || data.day != dia) {
          throw const FormatException('Data de nascimento inválida.');
        }

        return data;
      }

      PessoaFisica? pessoaFisica;
      PessoaJuridica? pessoaJuridica;

      // Cria apenas o model correspondente ao tipo escolhido.
      if (widget.pessoaFisica) {
        pessoaFisica = PessoaFisica(
          pf_nome: obrigatorio(widget.nome, 'o nome'),
          pf_sobrenome: obrigatorio(widget.sobrenome, 'o sobrenome'),
          pf_dataNascimento: converterNascimento(
            obrigatorio(widget.dataNascimento, 'a data de nascimento'),
          ),
          pf_genero: obrigatorio(widget.genero, 'o gênero'),
          pf_cpf: widget.cpf,
          pf_tipo: 'Cliente',
          pf_usuarios_id: 0,
        );
      } else {
        pessoaJuridica = PessoaJuridica(
          pj_razaoSocial: obrigatorio(widget.razaoSocial, 'a razão social'),
          pj_nomeFantasia: obrigatorio(widget.nomeFantasia, 'o nome fantasia'),
          pj_dataFundacao: obrigatorio(
            widget.dataFundacao,
            'a data de fundação',
          ),
          pj_cnpj: obrigatorio(
            widget.cnpj,
            'o CNPJ',
          ).replaceAll(RegExp(r'\D'), ''),
          pj_tipo: 'Cliente',
          pj_usuarios_id: 0,
        );
      }

      // Cria o model com os dados digitados nesta tela.
      final endereco = Endereco(
        endereco_nome: _endereco_nome.text.trim(),
        endereco_rua: _endereco_rua.text.trim(),
        endereco_bairro: _endereco_bairro.text.trim(),
        endereco_cep: _endereco_cep.text.trim(),
        endereco_complemento: _endereco_complemento.text.trim(),
        endereco_numero: _endereco_numero.text.trim(),
        endereco_descricao: null,
        endereco_cidade: _endereco_cidade.text.trim(),
        endereco_uf: _endereco_uf.text.trim().toUpperCase(),
        endereco_usuarios_id: 0,
      );

      final senhaHash = BCrypt.hashpw(
        widget.senha,
        BCrypt.gensalt(),
      );

      // Salva o arquivo da foto e recebe somente seu caminho.
      caminhoFoto = await _salvarFotoPerfil();

      final usuario = Usuarios(
        usuarios_email: widget.email.trim(),
        usuarios_imagem: caminhoFoto,
        usuarios_telefone: widget.telefone,
        usuarios_senha_hash: senhaHash,
        usuarios_ativo: true,
        usuarios_is_admin: false,
        usuarios_criado_em: DateTime.now(),
      );

      // O repository grava os dados e preenche as chaves estrangeiras.
      await CadastroRepository().cadastrar(
        senha: widget.senha,
        usuario: usuario.toMap(),
        endereco: endereco.toMap(),
        pessoaFisica: pessoaFisica?.toMap(),
        pessoaJuridica: pessoaJuridica?.toMap(),
      );

      cadastroSalvo = true;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro realizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => Login(),
        ),
            (route) => false,
      );
    } catch (erro) {
      // Se o banco falhar, remove a foto criada nesta tentativa.
      if (!cadastroSalvo && caminhoFoto.isNotEmpty) {
        try {
          await File(caminhoFoto).delete();
        } catch (_) {
          // Mantém o erro original do cadastro.
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível cadastrar: $erro'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

   @override
  Widget build(BuildContext context) {
    // TODO: implement build
     return Scaffold(
         backgroundColor: Colors.white,

         appBar: AppBar(
           backgroundColor: Colors.white,
           surfaceTintColor: Colors.transparent,
             centerTitle: true,
             title: const Text(
               'Informe seu endereço',
               style: TextStyle(
                 fontWeight: FontWeight.w600,
                 fontFamily: 'MontSerrat',
                 fontSize: 20,
                 color: Colors.black,
               ),
             ),

           leading: IconButton(
             icon: const Icon(Icons.arrow_back),
             tooltip: 'Voltar',
             onPressed: (){
               Navigator.pop(context);
             },
           ),
         ),

       body: SafeArea(
         child: Center(
           child: ConstrainedBox(
             constraints: const BoxConstraints(maxWidth: 500),
             child: SingleChildScrollView(
              child: Padding(
               padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
               child: Form(
                 key: _formKey,
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const SizedBox(height: 30),

                     const Padding(
                         padding: EdgeInsets.only(left: 12),
                         child: Text(
                           "Rua",
                           style: TextStyle(
                             fontSize: 15,
                             fontWeight: FontWeight.w600,
                           ),
                         )
                     ),
                     const SizedBox(height: 5),

                     Forms(
                       controlador: _endereco_rua,
                       tipagemValor: TextInputType.text,
                       rotulo: "Digite sua rua/avenida",
                       validador: Validacao.rua,

                     ),
                     const SizedBox(height: 24),

                     const Padding(
                         padding: EdgeInsets.only(left: 12),
                         child: Text(
                           "Bairro",
                           style: TextStyle(
                             fontSize: 15,
                             fontWeight: FontWeight.w600,
                           ),
                         )
                     ),
                     const SizedBox(height: 5),

                     Forms(
                       controlador: _endereco_bairro,
                       tipagemValor: TextInputType.text,
                       rotulo: "Digite seu bairro",
                       validador: Validacao.bairro,

                     ),
                     const SizedBox(height: 24),

                     const Padding(
                         padding: EdgeInsets.only(left: 12),
                         child: Text(
                           "Complemento",
                           style: TextStyle(
                             fontSize: 15,
                             fontWeight: FontWeight.w600,
                           ),
                         ),
                     ),
                     const SizedBox(height: 5),

                     Forms(
                       controlador: _endereco_complemento,
                       tipagemValor: TextInputType.text,
                       rotulo: "Complemento",

                     ),
                     const SizedBox(height: 24),


                     const Padding(
                       padding: EdgeInsets.only(left: 12),
                       child: Text(
                         "CEP",
                         style: TextStyle(
                           fontSize: 15,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ),
                     const SizedBox(height: 5),

                     Forms(
                       controlador: _endereco_cep,
                       tipagemValor: TextInputType.text,
                       validador: Validacao.cep,
                       formatadores: [_mascaraCep],
                       rotulo: "000000-000",

                     ),
                     const SizedBox(height: 24),

                     const Padding(
                       padding: EdgeInsets.only(left: 12),
                       child: Text(
                         "Numero",
                         style: TextStyle(
                           fontSize: 15,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ),
                     const SizedBox(height: 5),

                     Forms(
                       controlador: _endereco_numero,
                       tipagemValor: TextInputType.text,
                       rotulo: "Informe sua rua",

                     ),
                     const SizedBox(height: 24),

                     const Padding(
                       padding: EdgeInsets.only(left: 12),
                       child: Text(
                         "Cidade",
                         style: TextStyle(
                           fontSize: 15,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ),
                     const SizedBox(height: 5),

                     Forms(
                       controlador: _endereco_cidade,
                       tipagemValor: TextInputType.text,
                       rotulo: "Informe sua cidade",
                       validador: Validacao.cidade,

                     ),
                     const SizedBox(height: 24),


                     const Padding(
                       padding: EdgeInsets.only(left: 12),
                       child: Text(
                         "UF",
                         style: TextStyle(
                           fontSize: 15,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ),
                     const SizedBox(height: 5),

                     Forms(
                       controlador: _endereco_uf,
                       tipagemValor: TextInputType.text,
                       rotulo: "Ex.: GO",
                       formatadores: [
                         FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                          LengthLimitingTextInputFormatter(2),
                         ],
                       validador: Validacao.uf,

                     ),
                     const SizedBox(height: 24),

                     const Padding(
                       padding: EdgeInsets.only(left: 12),
                       child: Text(
                         "Nome do endereço",
                         style: TextStyle(
                           fontSize: 15,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ),
                     const SizedBox(height: 5),

                     Forms(
                       controlador: _endereco_cidade,
                       tipagemValor: TextInputType.text,
                       rotulo: "Ex.: Minha casa",

                     ),

                     const SizedBox(height: 54),

                     FilledButton(
                         onPressed: () async {
                           final valido = _formKey.currentState?.validate() ?? false;

                           if (!valido) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(
                                 content: Text('Erro ao preencher o formulário!'),
                               ),
                             );
                             return;
                           }

                           await _finalizarCadastro();
                         },



                       child: const Text("Finalizar"),


                       style: FilledButton.styleFrom(
                           backgroundColor: Color.fromARGB(1000, 59, 130, 246),
                           minimumSize: const Size(500, 25),
                           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                           textStyle: TextStyle(
                             fontSize: 18,
                             fontWeight: FontWeight.w500,
                           ),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadiusGeometry.circular(5),

                           )
                       ),
                     ),
                     const SizedBox(height: 40),

                     const SizedBox(
                       width: double.infinity,
                       child: Text(
                         'Direitos reservados © 2026',
                         textAlign: TextAlign.center,
                         style: TextStyle(
                           fontSize: 12,
                           color: Colors.grey,
                         ),
                       ),
                     ),

                     const SizedBox(height: 16),

                   ],
                 ),
               ),
             ),
             ),
           ),
         ),
       ),
     );
  }

}
