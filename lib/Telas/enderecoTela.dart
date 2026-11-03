import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:laborhub/Formularios/forms.dart';
import 'dart:convert';
import '../Repository/auth_api.dart';
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
  bool _salvando = false;

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
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      await CadastroRepository().cadastrar(
        usuario: {
          'usuarios_email': widget.email.trim().toLowerCase(),
          'usuarios_telefone': widget.telefone,
          'usuarios_senha_hash': widget.senha,
          'usuarios_imagem': widget.fotoPerfil == null
              ? ''
              : base64Encode(widget.fotoPerfil!),
          'usuarios_ativo': 1,
          'usuarios_is_admin': 0,
          'usuarios_criado_em': DateTime.now().toUtc().toIso8601String(),
        },
        endereco: {
          'endereco_nome': 'Principal',
          'endereco_rua': _endereco_rua.text.trim(),
          'endereco_numero': _endereco_numero.text.trim(),
          'endereco_bairro': _endereco_bairro.text.trim(),
          'endereco_cep': _mascaraCep.getUnmaskedText(),
          'endereco_complemento': _endereco_complemento.text.trim(),
          'endereco_cidade': _endereco_cidade.text.trim(),
          'endereco_uf': _endereco_uf.text.trim().toUpperCase(),
        },
        pessoaFisica: widget.pessoaFisica
            ? {
                'pf_nome': widget.nome,
                'pf_sobrenome': widget.sobrenome,
                'pf_dataNascimento': widget.dataNascimento,
                'pf_genero': widget.genero,
                'pf_cpf': widget.cpf,
                'pf_tipo': 'cliente',
              }
            : null,
        pessoaJuridica: !widget.pessoaFisica
            ? {
                'pj_razaoSocial': widget.razaoSocial,
                'pj_nomeFantasia': widget.nomeFantasia,
                'pj_dataFundacao': widget.dataFundacao,
                'pj_cnpj': widget.cnpj,
                'pj_tipo': 'cliente',
              }
            : null,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro realizado. Entre com seu email e senha.'),
        ),
      );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is AuthException
                  ? error.mensagem
                  : 'Não foi possível cadastrar. Tente novamente.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _salvando = false);
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

                     const SizedBox(height: 54),

                     FilledButton(
                         onPressed: _salvando ? null : () async {
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
