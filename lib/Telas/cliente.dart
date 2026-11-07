import 'dart:typed_data';

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:laborhub/Formularios/forms.dart';
import 'package:laborhub/Model/endereco.dart';
import '../Utils/validacao.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'enderecoTela.dart';

import '../Model/pessoaFisica.dart';
import '../Model/pessoJuridica.dart';
import '../Model/usuarios.dart';
import '../Repository/pessoaFisica_repository.dart';
import '../Repository/pessoaJuridica_Repository.dart';
import '../Repository/usuarios_repository.dart';

class Cliente extends StatefulWidget {
  const Cliente({super.key});

  @override
  State<Cliente> createState() => _ClienteTelas();
}

class _ClienteTelas extends State<Cliente> {
  Uint8List? _foto; //para foto de perfil
  bool _pessoaFisica = true; // para mudar o botao ao escolher o tipo de usuario

  final _formKey = GlobalKey<FormState>();
  final _pf_nome = TextEditingController();
  final _pf_sobrenome = TextEditingController();
  final _pf_dataNascimento = TextEditingController();
  final _pf_genero = TextEditingController();
  final _pf_cpf  = TextEditingController();
  final _pf_tipo = TextEditingController();
  final _pf_usuarios_id = TextEditingController();
  final _pj_razaoSocial = TextEditingController();
  final _pj_nomeFantasia = TextEditingController();
  final _pj_dataFundacao = TextEditingController();
  final _pj_cnpj = TextEditingController();
  final _pj_tipo = TextEditingController();
  final _pj_usuarios_id = TextEditingController();
  final _usuarios_email = TextEditingController();
  final _usuarios_imagem = TextEditingController();
  final _usuarios_telefone = TextEditingController();
  final _usuarios_senha_hash = TextEditingController();
  late bool _usuarios_ativo;
  late bool _usuarios_is_admin;
  late DateTime _usuarios_criado_em;

  String? _generoSelecionado;

  final _mascaraCpf = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final _mascaraData = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final _mascaraCNPJ = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {'#': RegExp(r'[0-9]')},
  );


  Future<String?> _salvarFotoPerfil() async {
    final foto = _foto;

    if (foto == null) {
      return null;
    }

    final diretorio = await getApplicationDocumentsDirectory();

    final pasta = Directory(
      p.join(diretorio.path, 'fotos_perfil'),
    );

    await pasta.create(recursive: true);

    final nomeArquivo =
        'perfil_${DateTime.now().microsecondsSinceEpoch}.jpg';

    final arquivo = File(
      p.join(pasta.path, nomeArquivo),
    );

    await arquivo.writeAsBytes(foto, flush: true);

    return nomeArquivo;
  }


  Future<void> _selecionarFoto() async {
    try {
      final arquivo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (arquivo == null) {
        return;
      }

      final bytes = await arquivo.readAsBytes();

      if (!mounted) return;

      setState(() {
        _foto = bytes;
      });
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível abrir a imagem.")),
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
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Form(
                  key: _formKey,
                   child: Column(
                  children: [
                    // const Spacer(flex: 2),
                    const SizedBox(height: 10),
                    const Text(
                      'Foto de perfil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 65,
                          backgroundColor: Color.fromARGB(1000, 59, 130, 246),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: _foto != null
                                ? MemoryImage(_foto!)
                                : null,
                            child: _foto == null
                                ? Icon(
                                    Icons.person,
                                    size: 100,
                                    color: Color.fromARGB(1000, 59, 130, 246),
                                  )
                                : null,
                          ),
                        ),

                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: IconButton.filled(
                            onPressed: _selecionarFoto,
                            icon: const Icon(Icons.edit),
                            tooltip: 'Alterar foto',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 50),

                    // Botoes
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        //   Pessoa fisica
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _pessoaFisica = true;
                              });
                            },

                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0,40),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              backgroundColor: _pessoaFisica
                                  ? Color.fromARGB(1000, 59, 130, 246)
                                  : Colors.white,
                              foregroundColor: _pessoaFisica
                                  ? Colors.white
                                  : Colors.black,
                              side: const BorderSide(color: Color.fromARGB(1000, 59, 130, 246)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),

                              )
                            ),
                            child: const Text("Pessoa Física"),
                          ),
                        ),

                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _pessoaFisica = false;
                              });
                            },

                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0,40),
                                backgroundColor: !_pessoaFisica
                                    ? Color.fromARGB(1000, 59, 130, 246)
                                    : Colors.white,
                                foregroundColor: !_pessoaFisica
                                    ? Colors.white
                                    : Colors.black,
                                side: const BorderSide(color: Color.fromARGB(1000, 59, 130, 246)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),

                                )
                            ),
                            child: const Text("Pessoa Jurídica"),
                          ),
                        ),

                      ],
                    ),

                        const SizedBox(height: 50),

                        if(_pessoaFisica == true) ...{
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Text(
                                  "Nome",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              ),
                              const SizedBox(height: 5),

                              Forms(
                                controlador: _pf_nome,
                                tipagemValor: TextInputType.text,
                                rotulo: "Digite seu nome",
                                validador: Validacao.nome,

                              ),
                              const SizedBox(height: 24),

                              const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text(
                                    "Sobrenome",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                              ),

                              const SizedBox(height: 5),

                              Forms(
                                controlador: _pf_sobrenome,
                                tipagemValor: TextInputType.text,
                                rotulo: "Digite seu sobrenome",
                                validador: Validacao.sobrenome,

                              ),

                              const SizedBox(height: 24),

                              const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text(
                                    "Data Nascimento",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                              ),

                              const SizedBox(height: 5),

                              Forms(
                                controlador: _pf_dataNascimento,
                                tipagemValor: TextInputType.datetime,
                                rotulo: "dd/mm/YYYY",
                                formatadores: [_mascaraData],
                                validador: Validacao.data,

                              ),

                              const SizedBox(height: 24),

                              const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text(
                                    "Gênero",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                              ),

                              const SizedBox(height: 5),

                             Forms.select(
                               rotulo: "Selecione",
                               opcao: [
                                 'Masculino',
                                 'Feminino',
                                 'Outro',
                               ],
                               onChanged: (valor){
                                 setState(() {
                                   _generoSelecionado = valor;
                                 });
                               },
                             ),

                              const SizedBox(height: 24),

                              const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text(
                                    "CPF",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                              ),

                              const SizedBox(height: 5),

                              Forms(
                                controlador: _pf_cpf,
                                tipagemValor: TextInputType.text,
                                rotulo: "000.000.000-00",
                                formatadores: [_mascaraCpf],
                                validador: Validacao.cpf,

                              ),
                              const SizedBox(height: 24),

                              const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text(
                                    "Telefone/Celular",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                              ),

                              const SizedBox(height: 5),

                              Forms(
                                controlador: _usuarios_telefone,
                                tipagemValor: TextInputType.phone,
                                rotulo: "(99) 99999-9999",
                                formatadores: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(11),
                                ],
                                validador: Validacao.telefone,

                              ),
                              const SizedBox(height: 24),

                              const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text(
                                    "Email",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                              ),

                              const SizedBox(height: 5),

                              Forms(
                                controlador: _usuarios_email,
                                tipagemValor: TextInputType.text,
                                rotulo: "email@gmail.com",
                                validador: Validacao.email,

                              ),

                              const SizedBox(height: 24),


                              const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text(
                                    "Senha",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                              ),

                              const SizedBox(height: 5),

                              Forms(
                                controlador: _usuarios_senha_hash,
                                tipagemValor: TextInputType.visiblePassword,
                                rotulo: "Sua senha",
                                ocultarTexto: true,
                                validador: Validacao.senha,

                              ),

                              const SizedBox(height: 54),

                              FilledButton(
                                  onPressed: () async {
                                    final valido = _formKey.currentState?.validate() ?? false;

                                    if(!valido) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Erro ao preencher o formulario!")),
                                      );
                                    }

                                    if(_generoSelecionado == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Selecione seu gênero!")),
                                      );
                                    }

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EnderecoTela(
                                          pessoaFisica: _pessoaFisica,

                                          email: _usuarios_email.text.trim(),
                                          telefone: _usuarios_telefone.text.trim(),
                                          senha: _usuarios_senha_hash.text,
                                          fotoPerfil: _foto,

                                          nome: _pessoaFisica ? _pf_nome.text.trim() : null,
                                          sobrenome: _pessoaFisica ? _pf_sobrenome.text.trim() : null,
                                          dataNascimento:
                                          _pessoaFisica ? _pf_dataNascimento.text.trim() : null,
                                          genero: _pessoaFisica ? _generoSelecionado : null,
                                          cpf: _pessoaFisica ? _mascaraCpf.getUnmaskedText() : null,

                                          razaoSocial:
                                          !_pessoaFisica ? _pj_razaoSocial.text.trim() : null,
                                          nomeFantasia:
                                          !_pessoaFisica ? _pj_nomeFantasia.text.trim() : null,
                                          dataFundacao:
                                          !_pessoaFisica ? _pj_dataFundacao.text.trim() : null,
                                          cnpj: !_pessoaFisica
                                              ? _pj_cnpj.text.replaceAll(RegExp(r'\D'), '')
                                              : null,
                                        ),
                                      ),
                                    );
                                  },

                                  child: const Text("Avançar"),


                                style: FilledButton.styleFrom(
                                  backgroundColor: Color.fromARGB(1000, 59, 130, 246),
                                  minimumSize: const Size(500, 25),
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  textStyle: TextStyle(
                                    fontSize: 20,
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



                        } else ... {

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text(
                                    "Razão Social",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                              ),
                              const SizedBox(height: 5),

                              Forms(
                                controlador: _pj_razaoSocial,
                                tipagemValor: TextInputType.text,
                                rotulo: "Digite sua razão social",
                                validador: Validacao.razaoSocial,

                              ),
                              const SizedBox(height: 24),

                              const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text(
                                    "Nome fantasia",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                              ),

                              const SizedBox(height: 5),

                              Forms(
                                controlador: _pj_nomeFantasia,
                                tipagemValor: TextInputType.text,
                                rotulo: "Digite o nome fantasia",
                                validador: Validacao.nomeFantasia,

                              ),

                              const SizedBox(height: 24),

                              const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text(
                                    "Data Fundação",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                              ),

                              const SizedBox(height: 5),

                              Forms(
                                controlador: _pj_dataFundacao,
                                tipagemValor: TextInputType.datetime,
                                rotulo: "dd/mm/YYYY",
                                formatadores: [_mascaraData],
                                validador: Validacao.data,

                              ),

                              const SizedBox(height: 24),

                              const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text(
                                    "CNPJ",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                              ),

                              const SizedBox(height: 5),

                              Forms(
                                controlador: _pj_cnpj,
                                tipagemValor: TextInputType.text,
                                rotulo: "00.000.000/0000-00",
                                formatadores: [_mascaraCNPJ],
                                validador: Validacao.cnpj,

                              ),
                              const SizedBox(height: 24),

                              const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text(
                                    "Telefone/Celular",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                              ),

                              const SizedBox(height: 5),

                              Forms(
                                controlador: _usuarios_telefone,
                                tipagemValor: TextInputType.phone,
                                rotulo: "(99) 99999-9999",
                                formatadores: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(11),
                                ],
                                validador: Validacao.telefone,

                              ),
                              const SizedBox(height: 24),

                              const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text(
                                    "Email",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                              ),

                              const SizedBox(height: 5),

                              Forms(
                                controlador: _usuarios_email,
                                tipagemValor: TextInputType.text,
                                rotulo: "email@gmail.com",
                                validador: Validacao.email,

                              ),

                              const SizedBox(height: 24),


                              const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text(
                                    "Senha",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                              ),

                              const SizedBox(height: 5),

                              Forms(
                                controlador: _usuarios_senha_hash,
                                tipagemValor: TextInputType.visiblePassword,
                                rotulo: "Sua senha",
                                ocultarTexto: true,
                                validador: Validacao.senha,

                              ),

                              const SizedBox(height: 54),

                              FilledButton(
                                onPressed: () async {
                                  final valido = _formKey.currentState?.validate() ?? false;

                                  if(!valido) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Erro ao preencher o formulario!")),
                                    );
                                  }

                                  if(_generoSelecionado == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Selecione seu gênero!")),
                                    );
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EnderecoTela(
                                        pessoaFisica: _pessoaFisica,

                                        email: _usuarios_email.text.trim(),
                                        telefone: _usuarios_telefone.text.trim(),
                                        senha: _usuarios_senha_hash.text,
                                        fotoPerfil: _foto,

                                        nome: _pessoaFisica ? _pf_nome.text.trim() : null,
                                        sobrenome: _pessoaFisica ? _pf_sobrenome.text.trim() : null,
                                        dataNascimento:
                                        _pessoaFisica ? _pf_dataNascimento.text.trim() : null,
                                        genero: _pessoaFisica ? _generoSelecionado : null,
                                        cpf: _pessoaFisica ? _mascaraCpf.getUnmaskedText() : null,

                                        razaoSocial:
                                        !_pessoaFisica ? _pj_razaoSocial.text.trim() : null,
                                        nomeFantasia:
                                        !_pessoaFisica ? _pj_nomeFantasia.text.trim() : null,
                                        dataFundacao:
                                        !_pessoaFisica ? _pj_dataFundacao.text.trim() : null,
                                        cnpj: !_pessoaFisica
                                            ? _pj_cnpj.text.replaceAll(RegExp(r'\D'), '')
                                            : null,
                                      ),
                                    ),
                                  );
                                },

                                child: const Text("Avançar"),


                                style: FilledButton.styleFrom(
                                    backgroundColor: Color.fromARGB(1000, 59, 130, 246),
                                    minimumSize: const Size(500, 35),
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    textStyle: TextStyle(
                                      fontSize: 20,
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


                        }
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
