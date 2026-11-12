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
import '../Repository/cadastroProfissional_repository.dart';
import '../Model/usuarios.dart';
import '../Model/pessoJuridica.dart';
import '../Model/pessoaFisica.dart';
import '../Model/servico.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:path_provider/path_provider.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'login.dart';


class ServicoTela  extends StatefulWidget{

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

  final String endereco_rua;
  final String endereco_bairro;
  final String endereco_cep;
  final String endereco_numero;
  final String endereco_complemento;
  final String endereco_cidade;
  final String endereco_uf;
  final String endereco_nome;

  const ServicoTela({
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
    required this.endereco_rua,
    required this.endereco_bairro,
    required this.endereco_cep,
    required this.endereco_numero,
    required this.endereco_complemento,
    required this.endereco_cidade,
    required this.endereco_uf,
    required this.endereco_nome,
  });


  @override
  State<ServicoTela> createState() => _ServicoTelaState();

}

class _ServicoTelaState extends State<ServicoTela> {

  final _formKey = GlobalKey<FormState>();

  final _servicos_nome = TextEditingController();
  final _servicos_data = TextEditingController();
  final _servicos_valor = TextEditingController();
  final _servicos_tipo_cobranca = TextEditingController();
  final _servicos_nivel_experiencia = TextEditingController();
  final _servicos_descricao = TextEditingController();

   String? _servicoDataSelecionado;
   String? _servicoValor;
   String? _nivelCobranca;

  @override
  void dispose() {
    _servicos_nome.dispose();
    _servicos_data.dispose();
    _servicos_valor.dispose();
    _servicos_tipo_cobranca.dispose();
    _servicos_nivel_experiencia.dispose();
    _servicos_descricao.dispose();
    super.dispose();
  }


  final _mascaraCep = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final _mascaraValor = CurrencyTextInputFormatter.currency(
    locale: 'pt_BR',
    decimalDigits: 2,
    symbol: 'R\$',
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
          pf_tipo: 'Profissional',
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
          pj_tipo: 'Profissional',
          pj_usuarios_id: 0,
        );
      }

      // Cria o model com os dados digitados nesta tela.
      final endereco = Endereco(
        endereco_nome: widget.endereco_nome.trim(),
        endereco_rua:  widget.endereco_rua.trim(),
        endereco_bairro: widget.endereco_bairro.trim(),
        endereco_cep: widget.endereco_cep.trim(),
        endereco_complemento: widget.endereco_complemento.trim(),
        endereco_numero: widget.endereco_numero.trim(),
        endereco_descricao: null,
        endereco_cidade: widget.endereco_cidade.trim(),
        endereco_uf: widget.endereco_uf.trim().toUpperCase(),
        endereco_usuarios_id: 0,
      );

      if ((_servicoDataSelecionado ?? '').trim().isEmpty ||
          (_servicoValor ?? '').trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Selecione os dias de serviço e o tipo de cobrança.',
            ),
          ),
        );
        return;
      }



      final servico = Servico(
    servicos_nome: _servicos_nome.text.trim(),
        servicos_data: _servicoDataSelecionado ?? '',
        servicos_valor: _servicoValor == 'Negociar'
            ? 0.0
            : _mascaraValor.getUnformattedValue().toDouble(),
        servicos_tipo_cobranca: _servicoValor ?? '',
        servicos_nivel_experiencia: _nivelCobranca ?? '',
        servicos_descricao: _servicos_descricao.text.trim(),
        servicos_usuarios_id: 0,
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
      await CadastroProfissionalRepository().cadastrar(
        senha: widget.senha,
        usuario: usuario.toMap(),
        endereco: endereco.toMap(),
        servico: servico.toMap(),
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
          'Informe seu serviço',
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
                            "Serviços nome",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                      ),
                      const SizedBox(height: 5),

                      Forms(
                        controlador: _servicos_nome,
                        tipagemValor: TextInputType.text,
                        rotulo: "Ex.: Pedreiro, pintor...",
                        validador: Validacao.servicosNome,

                      ),
                      const SizedBox(height: 24),

                      const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text(
                            "Data de serviços",
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
                          'Segunda à sexta',
                          'Segunda à Sábado',
                          'Finais de semana',
                          'Todos os dias',
                        ],
                        onChanged: (valor){
                          setState(() {
                            _servicoDataSelecionado = valor;
                          });

                        },
                      ),

                      const SizedBox(height: 24),


                      const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text(
                            "Tipo de cobrança",
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
                          'Total',
                          'Negociar',
                          'Diária',
                          'Hora',
                        ],
                        onChanged: (valor){
                          setState(() {
                            _servicoValor = valor;
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      if(_servicoValor != 'Negociar')... [
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text(
                            "Valor do serviço",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),

                        Forms(
                          controlador: _servicos_valor,
                          tipagemValor: TextInputType.number,
                          formatadores: [_mascaraValor],
                          rotulo: "R\$ 0,00",

                        ),
                        const SizedBox(height: 24),

                      ],
                      const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text(
                            "Nível de expêriencia",
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
                          'Iniciante',
                          'Intermediário',
                          'Avançado',
                        ],
                        onChanged: (valor){
                          setState(() {
                            _nivelCobranca = valor;
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Text(
                          "Descrição",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),

                      Forms(
                        controlador: _servicos_descricao,
                        tipagemValor: TextInputType.multiline,
                        rotulo: "Descreva mais sobre seu serviço (opcional)",
                        maxLinha: 5 ,

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
