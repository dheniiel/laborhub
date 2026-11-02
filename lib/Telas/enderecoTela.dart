import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:laborhub/Formularios/forms.dart';
import 'package:laborhub/Model/endereco.dart';
import '../Utils/validacao.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../Repository/cadastro_repository.dart';



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

  Future<void> _finalizarCadastro() async {
    // Dados comuns:
    final email = widget.email;
    final telefone = widget.telefone;
    final senha = widget.senha;
    final foto = widget.fotoPerfil;

    // Endereço:
    final rua = _endereco_rua.text.trim();
    final numero = _endereco_numero.text.trim();
    final bairro = _endereco_bairro.text.trim();
    final cep = _mascaraCep.getUnmaskedText();
    final complemento = _endereco_complemento.text.trim();
    final cidade = _endereco_cidade.text.trim();
    final uf = _endereco_uf.text.trim().toUpperCase();

    if (widget.pessoaFisica) {
      // Dados da pessoa física:
      final nome = widget.nome;
      final sobrenome = widget.sobrenome;
      final nascimento = widget.dataNascimento;
      final genero = widget.genero;
      final cpf = widget.cpf;

      // Montar o model PessoaFisica.
    } else {
      // Dados da pessoa jurídica:
      final razaoSocial = widget.razaoSocial;
      final nomeFantasia = widget.nomeFantasia;
      final dataFundacao = widget.dataFundacao;
      final cnpj = widget.cnpj;

      // Montar o model PessoaJuridica.
    }

    final repository = CadastroRepository();

    final usuarioId = await repository.cadastrar(
      usuario: usuario.toMap(),
      endereco: endereco.toMap(),
      pessoaFisica: widget.pessoaFisica
          ? pessoaFisica.toMap()
          : null,
      pessoaJuridica: !widget.pessoaFisica
          ? pessoaJuridica.toMap()
          : null,
    );
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
                           padding: EdgeInsets.all(20),
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