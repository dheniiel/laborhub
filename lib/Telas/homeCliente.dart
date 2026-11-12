import 'dart:io';

import 'package:flutter/material.dart';

import '../Formularios/forms.dart';
import '../Model/profissional.dart';
import '../Model/usuarios.dart';
import '../Repository/profissional_repository.dart';
import '../Repository/sessao_repository.dart';
import 'login.dart';
import 'perfilProfissional.dart';
import 'editarPerfil.dart';
import 'historico.dart';
import 'agendamentos.dart';
import 'detalhesUsuario.dart';


class HomeCliente extends StatefulWidget {
  // Usuário da sessão (API ou cópia offline no SQLite), já confirmado como Cliente pelo Login.
  final Usuarios usuario;

  const HomeCliente({super.key, required this.usuario});

  @override
  State<HomeCliente> createState() => _HomeClienteState();
}

class _HomeClienteState extends State<HomeCliente> {
  final _pesquisaController = TextEditingController();
  final ProfissionalRepository _repository = ProfissionalRepository();
  final SessaoRepository _sessao = SessaoRepository();

  List<Profissional> _profissionais = [];
  bool _carregando = true;
  
    // Cópia do usuário que pode mudar após editar o perfil.
  late Usuarios _usuario = widget.usuario;

  // Abre a edição e, ao voltar com dados salvos, atualiza o cabeçalho.
  Future<void> _abrirEdicaoPerfil() async {
    final atualizado = await Navigator.of(context).push<Usuarios>(
      MaterialPageRoute(builder: (context) => EditarPerfil(usuario: _usuario)),
    );
    if (atualizado != null && mounted) {
      setState(() => _usuario = atualizado);
    }
  }

    // Abre o Histórico; ao voltar, atualiza o usuário caso o perfil tenha sido editado lá.
  Future<void> _abrirHistorico() async {
    final atualizado = await Navigator.of(context).push<Usuarios>(
      MaterialPageRoute(builder: (context) => Historico(usuario: _usuario)),
    );
    if (atualizado != null && mounted) {
      setState(() => _usuario = atualizado);
    }
  }

   // Abre Agendamentos; ao voltar, atualiza o usuário caso o perfil tenha sido editado lá.
  Future<void> _abrirAgendamentos() async {
    final atualizado = await Navigator.of(context).push<Usuarios>(
      MaterialPageRoute(builder: (context) => Agendamentos(usuario: _usuario)),
    );
    if (atualizado != null && mounted) {
      setState(() => _usuario = atualizado);
    }
  }

  @override
  void initState() {
    super.initState();
    // Refaz o filtro a cada letra digitada.
    _pesquisaController.addListener(() => setState(() {}));
    _carregarProfissionais();
    _validarSessao();
  }

  // Confere a sessão na API ao abrir. Sem conexão, continua com os dados do SQLite.
  Future<void> _validarSessao() async {
    try {
      final sessao = await _sessao.restaurar();
      final valida = sessao == null ? null : await _sessao.validar(sessao);
      if (valida == null) _voltarAoLogin('Sua sessão expirou. Entre novamente.');
    } catch (_) {
      // Erro no banco local: mantém a tela; a próxima abertura tenta de novo.
    }
  }

  Future<void> _sair() async {
    try {
      await _sessao.sair();
    } catch (_) {
      // Mesmo com erro local, volta ao login.
    }
    _voltarAoLogin(null);
  }

  void _voltarAoLogin(String? mensagem) {
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
    if (mensagem != null) {
      mensageiro.showSnackBar(SnackBar(content: Text(mensagem)));
    }
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  Future<void> _carregarProfissionais() async {
    try {
      final profissionais = await _repository.Listar();
      if (!mounted) return;
      setState(() => _profissionais = profissionais);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar os profissionais.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // Filtra por nome ou profissão.
  List<Profissional> get _filtrados {
    final termo = _pesquisaController.text.trim().toLowerCase();
    if (termo.isEmpty) return _profissionais;

    return _profissionais.where((profissional) {
      return profissional.profissional_nome.toLowerCase().contains(termo) ||
          profissional.profissional_profissao.toLowerCase().contains(termo);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final profissionais = _filtrados;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // Cabeçalho
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 12, 0),
                  child: Row(
                    children: [
                      Tooltip(
                        message: 'Meu perfil',
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _abrirEdicaoPerfil,
                          child: _Avatar(
                            caminho: _usuario.usuarios_imagem, // antes: widget.usuario.usuarios_imagem
                            raio: 23,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.notifications, size: 25),
                        color: Colors.black,
                        tooltip: 'Notificações',
                        onPressed: () {
                          // Navegação para tela de notificações
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, size: 25),
                        color: Colors.black,
                        tooltip: 'Configurações',
                        onPressed: _abrirEdicaoPerfil,
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, size: 25),
                        color: Colors.black,
                        tooltip: 'Sair',
                        onPressed: _sair,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  'Busque profissionais\npróximo a você',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w400,
                    color: Colors.black,

                  ),
                ),

                const SizedBox(height: 18),

                // Faixa de pesquisa
                Container(
                  width: double.infinity,
                  color: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.fromLTRB(40, 16, 40, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Text(
                          'Pesquise por um profissional',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Forms(
                        controlador: _pesquisaController,
                        tipagemValor: TextInputType.text,
                        rotulo: 'Pesquisar',
                      ),
                    ],
                  ),
                ),

                // Lista de profissionais
                Expanded(
                  child: _carregando
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF3B82F6),
                          ),
                        )
                      : profissionais.isEmpty
                          ? const Center(
                              child: Text(
                                'Nenhum profissional encontrado',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: 'Montserrat',
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(24, 30, 24, 16),
                              itemCount: profissionais.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 24),
                              itemBuilder: (context, indice) =>
                                  _CardProfissional(
                                    profissional: profissionais[indice],
                                  ),
                            ),
                ),

                // Barra inferior
                Padding(
                  padding: const EdgeInsets.fromLTRB(44, 4, 44, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.assignment_outlined, size: 38),
                        color: const Color(0xFF424242),
                        tooltip: 'Histórico',
                        onPressed: _abrirHistorico,
                      ),

                      IconButton(
                        icon: const Icon(Icons.home, size: 38),
                        color: const Color(0xFF3B82F6),
                        tooltip: 'Início',
                        onPressed: () {
                        // Já está na Home
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.event_available, size: 38),
                        color: const Color(0xFF424242),
                        tooltip: 'Agendamentos',
                        onPressed: _abrirAgendamentos,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _CardProfissional extends StatelessWidget {

  final Profissional profissional;

  const _CardProfissional({required this.profissional});

  static const _estiloPequeno = TextStyle(
    fontSize: 10.5,
    fontFamily: 'Montserrat',
    color: Colors.black,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 310),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 6, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFFD9D9D9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _Avatar(
                      caminho: profissional.profissional_imagem,
                      raio: 34,
                    ),
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            profissional.profissional_profissao,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Montserrat',
                              color: Colors.black,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          profissional.profissional_nome,
                          style: const TextStyle(
                            fontSize: 17,
                            fontFamily: 'Montserrat',
                            color: Colors.black,
                          ),
                        ),

                        Text(
                          '${profissional.profissional_cidade}, ${profissional.profissional_uf}',
                          style: _estiloPequeno,
                        ),

                        const SizedBox(height: 2),

                        Row(
                          children: [
                            for (var i = 0; i < 5; i++)
                              Icon(
                                i < profissional.profissional_avaliacao.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 20,
                                color: const Color(0xFFFFC107),
                              ),

                            const SizedBox(width: 10),

                            Flexible(
                              child: Text(
                                '${profissional.profissional_avaliacao.toStringAsFixed(1)} (${_milhar(profissional.profissional_total_avaliacoes)})',
                                style: _estiloPequeno,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Observação',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      profissional.profissional_observacao,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontFamily: 'Montserrat',

                        height: 1.4,
                        // color: Colors.black,
                        fontWeight: FontWeight.normal,

                      ),
                    ),

                    const SizedBox(height: 26),

                    Row(
                      children: [
                        if(profissional.profissional_tipo_cobranca == 'Negociar') ... [
                          Expanded(
                            child: Text(
                                "A negociar",
                              style: TextStyle(
                                fontSize: 19,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF22C55E),

                              ),
                            ),
                          ),

                        ] else ... [
                          Expanded(
                            child: Text(
                              'R\$ ${_moeda(profissional.profissional_preco)} - ${profissional.profissional_tipo_cobranca}',
                              style: const TextStyle(
                                fontSize: 19,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                          ),

                        ],


                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DetalhesUsuario(profissional: profissional),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            minimumSize: const Size(90, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            textStyle: const TextStyle(fontSize: 16, fontFamily: 'Montserrat'),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          ),
                          child: const Text('Perfil'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _Avatar extends StatelessWidget {

  final String caminho;
  final double raio;

  const _Avatar({required this.caminho, required this.raio});

  @override
  Widget build(BuildContext context) {
    // A foto é salva como caminho de arquivo no cadastro (EnderecoTela).
    final temFoto = caminho.isNotEmpty && File(caminho).existsSync();

    return CircleAvatar(
      radius: raio,
      backgroundColor: const Color(0xFFF4F4F4),
      backgroundImage: temFoto ? FileImage(File(caminho)) : null,
      child: temFoto
          ? null
          : Icon(
              Icons.person,
              size: raio * 1.4,
              color: const Color(0xFF3B82F6),
            ),
    );
  }
}


// 11890 -> 11.890
String _milhar(int valor) {
  final digitos = valor.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digitos[i]);
  }
  return buffer.toString();
}

// 149.99 -> 149,99 (sem depender do pacote intl)
String _moeda(double valor) {
  final centavos = (valor * 100).round();
  return '${_milhar(centavos ~/ 100)},${(centavos % 100).toString().padLeft(2, '0')}';
}