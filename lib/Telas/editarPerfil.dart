import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:path_provider/path_provider.dart';

import '../Formularios/forms.dart';
import '../Model/usuarios.dart';
import '../Repository/perfil_repository.dart';
import '../Utils/validacao.dart';


class EditarPerfil extends StatefulWidget {
  // Usuário da sessão, recebido da HomeCliente.
  final Usuarios usuario;

  const EditarPerfil({super.key, required this.usuario});

  @override
  State<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends State<EditarPerfil> {
  static const _generos = ['Masculino', 'Feminino', 'Outro'];

  final _formKey = GlobalKey<FormState>();
  final PerfilRepository _repository = PerfilRepository();

  Uint8List? _foto; // nova foto escolhida; só é gravada ao salvar
  bool _carregando = true;
  bool _salvando = false;

  Map<String, Object?>? _pessoaFisica;
  Map<String, Object?>? _endereco;

  final _pf_nome = TextEditingController();
  final _pf_sobrenome = TextEditingController();
  final _pf_dataNascimento = TextEditingController();
  String? _generoSelecionado;

  final _pj_razaoSocial = TextEditingController();
  final _pj_nomeFantasia = TextEditingController();
  final _pj_dataFundacao = TextEditingController();

  final _usuarios_telefone = TextEditingController();

  final _endereco_nome = TextEditingController();
  final _endereco_rua = TextEditingController();
  final _endereco_bairro = TextEditingController();
  final _endereco_cep = TextEditingController();
  final _endereco_complemento = TextEditingController();
  final _endereco_numero = TextEditingController();
  final _endereco_cidade = TextEditingController();
  final _endereco_uf = TextEditingController();

  final _mascaraData = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final _mascaraCep = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool get _ehPessoaFisica => _pessoaFisica != null;

  @override
  void initState() {
    super.initState();
    _usuarios_telefone.text = widget.usuario.usuarios_telefone ?? '';
    _carregarPerfil();
  }

  @override
  void dispose() {
    for (final controlador in [
      _pf_nome, _pf_sobrenome, _pf_dataNascimento,
      _pj_razaoSocial, _pj_nomeFantasia, _pj_dataFundacao,
      _usuarios_telefone,
      _endereco_nome, _endereco_rua, _endereco_bairro, _endereco_cep,
      _endereco_complemento, _endereco_numero, _endereco_cidade, _endereco_uf,
    ]) {
      controlador.dispose();
    }
    super.dispose();
  }

  String _texto(Object? valor) => (valor as String?) ?? '';

  // 2000-01-31 (banco) -> 31/01/2000 (formulário)
  String _dataTela(Object? valor) {
    final data = DateTime.tryParse(_texto(valor));
    if (data == null) return '';
    String doisDigitos(int numero) => numero.toString().padLeft(2, '0');
    return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year}';
  }

  Future<void> _carregarPerfil() async {
    try {
      final perfil = await _repository.carregar();
      final pf = perfil['pessoaFisica'] as Map<String, Object?>?;
      final pj = perfil['pessoaJuridica'] as Map<String, Object?>?;
      final endereco = perfil['endereco'] as Map<String, Object?>?;
      if (!mounted) return;

      setState(() {
        _pessoaFisica = pf;
        _endereco = endereco;

        if (pf != null) {
          _pf_nome.text = _texto(pf['pf_nome']);
          _pf_sobrenome.text = _texto(pf['pf_sobrenome']);
          _pf_dataNascimento.text = _dataTela(pf['pf_dataNascimento']);
          final genero = pf['pf_genero'] as String?;
          _generoSelecionado = _generos.contains(genero) ? genero : null;
        }

        if (pj != null) {
          _pj_razaoSocial.text = _texto(pj['pj_razaoSocial']);
          _pj_nomeFantasia.text = _texto(pj['pj_nomeFantasia']);
          _pj_dataFundacao.text = _dataTela(pj['pj_dataFundacao']);
        }

        if (endereco != null) {
          _endereco_nome.text = _texto(endereco['endereco_nome']);
          _endereco_rua.text = _texto(endereco['endereco_rua']);
          _endereco_bairro.text = _texto(endereco['endereco_bairro']);
          _endereco_cep.text = _mascaraCep.maskText(
            _texto(endereco['endereco_cep']).replaceAll(RegExp(r'\D'), ''),
          );
          _endereco_complemento.text = _texto(endereco['endereco_complemento']);
          _endereco_numero.text = _texto(endereco['endereco_numero']);
          _endereco_cidade.text = _texto(endereco['endereco_cidade']);
          _endereco_uf.text = _texto(endereco['endereco_uf']);
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível carregar seus dados.')),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // Mesma lógica de cliente.dart.
  Future<void> _selecionarFoto() async {
    try {
      final arquivo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (arquivo == null) return;

      final bytes = await arquivo.readAsBytes();
      if (!mounted) return;
      setState(() => _foto = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a imagem.')),
      );
    }
  }

  // Mesma lógica de enderecoTela.dart: retorna o caminho do arquivo.
  Future<String> _salvarFotoPerfil() async {
    final foto = _foto;
    if (foto == null || foto.isEmpty) return '';

    final diretorio = await getApplicationDocumentsDirectory();
    final pasta = Directory('${diretorio.path}/fotos_perfil');
    await pasta.create(recursive: true);

    final nome = 'perfil_${DateTime.now().microsecondsSinceEpoch}.img';
    final arquivo = File('${pasta.path}/$nome');
    await arquivo.writeAsBytes(foto, flush: true);
    return arquivo.path;
  }

  // Foto nova (memória) ou a atual (arquivo salvo no cadastro).
  ImageProvider? get _imagemPerfil {
    if (_foto != null) return MemoryImage(_foto!);
    final caminho = widget.usuario.usuarios_imagem;
    if (caminho.isNotEmpty && File(caminho).existsSync()) {
      return FileImage(File(caminho));
    }
    return null;
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao preencher o formulário!')),
      );
      return;
    }

    if (_endereco == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Endereço não encontrado. Entre novamente.')),
      );
      return;
    }

    setState(() => _salvando = true);
    String novaFoto = '';

    try {
      novaFoto = await _salvarFotoPerfil();

      final usuario = await _repository.atualizar(
        usuario: {
          'usuarios_imagem':
              novaFoto.isNotEmpty ? novaFoto : widget.usuario.usuarios_imagem,
          'usuarios_telefone': _usuarios_telefone.text.trim(),
        },
        endereco: {
          'endereco_id': _endereco!['endereco_id'],
          'endereco_nome': _endereco_nome.text.trim(),
          'endereco_rua': _endereco_rua.text.trim(),
          'endereco_bairro': _endereco_bairro.text.trim(),
          'endereco_cep': _endereco_cep.text.trim(),
          'endereco_complemento': _endereco_complemento.text.trim(),
          'endereco_numero': _endereco_numero.text.trim(),
          'endereco_cidade': _endereco_cidade.text.trim(),
          'endereco_uf': _endereco_uf.text.trim().toUpperCase(),
        },
        pessoaFisica: _ehPessoaFisica
            ? {
                'pf_nome': _pf_nome.text.trim(),
                'pf_sobrenome': _pf_sobrenome.text.trim(),
                'pf_dataNascimento': _pf_dataNascimento.text.trim(),
                'pf_genero': _generoSelecionado,
              }
            : null,
        pessoaJuridica: !_ehPessoaFisica
            ? {
                'pj_razaoSocial': _pj_razaoSocial.text.trim(),
                'pj_nomeFantasia': _pj_nomeFantasia.text.trim(),
                'pj_dataFundacao': _pj_dataFundacao.text.trim(),
              }
            : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      // Devolve o usuário atualizado para a Home trocar o avatar.
      Navigator.pop(context, usuario);
    } catch (erro) {
      // Se a API falhar, remove a foto criada nesta tentativa.
      if (novaFoto.isNotEmpty) {
        try {
          await File(novaFoto).delete();
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível salvar: $erro'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  // Rótulo no mesmo estilo das telas de cadastro.
  Widget _rotulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Editar perfil',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _carregando
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
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
                                  backgroundColor: const Color(0xFF3B82F6),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.white,
                                    backgroundImage: _imagemPerfil,
                                    child: _imagemPerfil == null
                                        ? const Icon(Icons.person, size: 100, color: Color(0xFF3B82F6))
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_ehPessoaFisica) ...[
                                  _rotulo('Nome'),
                                  const SizedBox(height: 5),
                                  Forms(
                                    controlador: _pf_nome,
                                    tipagemValor: TextInputType.text,
                                    rotulo: 'Digite seu nome',
                                    validador: Validacao.nome,
                                  ),
                                  const SizedBox(height: 24),
                                  _rotulo('Sobrenome'),
                                  const SizedBox(height: 5),
                                  Forms(
                                    controlador: _pf_sobrenome,
                                    tipagemValor: TextInputType.text,
                                    rotulo: 'Digite seu sobrenome',
                                    validador: Validacao.sobrenome,
                                  ),
                                  const SizedBox(height: 24),
                                  _rotulo('Data Nascimento'),
                                  const SizedBox(height: 5),
                                  Forms(
                                    controlador: _pf_dataNascimento,
                                    tipagemValor: TextInputType.datetime,
                                    rotulo: 'dd/mm/YYYY',
                                    formatadores: [_mascaraData],
                                    validador: Validacao.data,
                                  ),
                                  const SizedBox(height: 24),
                                  _rotulo('Gênero'),
                                  const SizedBox(height: 5),
                                  Forms.select(
                                    rotulo: 'Selecione',
                                    opcao: _generos,
                                    valorInicial: _generoSelecionado,
                                    validador: (valor) =>
                                        valor == null ? 'Selecione seu gênero!' : null,
                                    onChanged: (valor) {
                                      setState(() => _generoSelecionado = valor);
                                    },
                                  ),
                                ] else ...[
                                  _rotulo('Razão Social'),
                                  const SizedBox(height: 5),
                                  Forms(
                                    controlador: _pj_razaoSocial,
                                    tipagemValor: TextInputType.text,
                                    rotulo: 'Digite sua razão social',
                                    validador: Validacao.razaoSocial,
                                  ),
                                  const SizedBox(height: 24),
                                  _rotulo('Nome fantasia'),
                                  const SizedBox(height: 5),
                                  Forms(
                                    controlador: _pj_nomeFantasia,
                                    tipagemValor: TextInputType.text,
                                    rotulo: 'Digite o nome fantasia',
                                    validador: Validacao.nomeFantasia,
                                  ),
                                  const SizedBox(height: 24),
                                  _rotulo('Data Fundação'),
                                  const SizedBox(height: 5),
                                  Forms(
                                    controlador: _pj_dataFundacao,
                                    tipagemValor: TextInputType.datetime,
                                    rotulo: 'dd/mm/YYYY',
                                    formatadores: [_mascaraData],
                                    validador: Validacao.data,
                                  ),
                                ],
                                const SizedBox(height: 24),
                                _rotulo('Telefone/Celular'),
                                const SizedBox(height: 5),
                                Forms(
                                  controlador: _usuarios_telefone,
                                  tipagemValor: TextInputType.phone,
                                  rotulo: '(99) 99999-9999',
                                  formatadores: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(11),
                                  ],
                                  validador: Validacao.telefone,
                                ),
                                const SizedBox(height: 40),
                                const Text(
                                  'Endereço',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _rotulo('Rua'),
                                const SizedBox(height: 5),
                                Forms(
                                  controlador: _endereco_rua,
                                  tipagemValor: TextInputType.text,
                                  rotulo: 'Digite sua rua/avenida',
                                  validador: Validacao.rua,
                                ),
                                const SizedBox(height: 24),
                                _rotulo('Bairro'),
                                const SizedBox(height: 5),
                                Forms(
                                  controlador: _endereco_bairro,
                                  tipagemValor: TextInputType.text,
                                  rotulo: 'Digite seu bairro',
                                  validador: Validacao.bairro,
                                ),
                                const SizedBox(height: 24),
                                _rotulo('Complemento'),
                                const SizedBox(height: 5),
                                Forms(
                                  controlador: _endereco_complemento,
                                  tipagemValor: TextInputType.text,
                                  rotulo: 'Complemento',
                                ),
                                const SizedBox(height: 24),
                                _rotulo('CEP'),
                                const SizedBox(height: 5),
                                Forms(
                                  controlador: _endereco_cep,
                                  tipagemValor: TextInputType.text,
                                  rotulo: '00000-000',
                                  formatadores: [_mascaraCep],
                                  validador: Validacao.cep,
                                ),
                                const SizedBox(height: 24),
                                _rotulo('Número'),
                                const SizedBox(height: 5),
                                Forms(
                                  controlador: _endereco_numero,
                                  tipagemValor: TextInputType.text,
                                  rotulo: 'Número',
                                ),
                                const SizedBox(height: 24),
                                _rotulo('Cidade'),
                                const SizedBox(height: 5),
                                Forms(
                                  controlador: _endereco_cidade,
                                  tipagemValor: TextInputType.text,
                                  rotulo: 'Informe sua cidade',
                                  validador: Validacao.cidade,
                                ),
                                const SizedBox(height: 24),
                                _rotulo('UF'),
                                const SizedBox(height: 5),
                                Forms(
                                  controlador: _endereco_uf,
                                  tipagemValor: TextInputType.text,
                                  rotulo: 'Ex.: GO',
                                  formatadores: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                                    LengthLimitingTextInputFormatter(2),
                                  ],
                                  validador: Validacao.uf,
                                ),
                                const SizedBox(height: 24),
                                _rotulo('Nome do endereço'),
                                const SizedBox(height: 5),
                                Forms(
                                  controlador: _endereco_nome,
                                  tipagemValor: TextInputType.text,
                                  rotulo: 'Ex.: Minha casa',
                                ),
                                const SizedBox(height: 54),
                                FilledButton(
                                  onPressed: _salvando ? null : _salvar,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    minimumSize: const Size(500, 25),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  ),
                                  child: Text(_salvando ? 'Salvando...' : 'Salvar'),
                                ),
                                const SizedBox(height: 40),
                                const SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    'Direitos reservados © 2026',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
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