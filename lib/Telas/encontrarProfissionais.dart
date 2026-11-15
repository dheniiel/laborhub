import 'dart:io';

import 'package:flutter/material.dart';

import '../Formularios/forms.dart';
import '../Model/profissional.dart';
import '../Model/usuarios.dart';
import '../Repository/profissional_repository.dart';
import 'agendamentos.dart';
import 'editarPerfil.dart';
import 'historico.dart';
import 'homeCliente.dart' show CardProfissional, HomeCliente;
import 'menuLateral.dart';

class EncontrarProfissionais extends StatefulWidget {
  // Usuário da sessão, recebido da HomeCliente.
  final Usuarios usuario;

  const EncontrarProfissionais({super.key, required this.usuario});

  @override
  State<EncontrarProfissionais> createState() => _EncontrarProfissionaisState();
}

class _EncontrarProfissionaisState extends State<EncontrarProfissionais> {
  static const _todos = 'Todos';

  // Mesmos níveis do cadastro de serviço (servico.dart).
  static const _niveis = [_todos, 'Iniciante', 'Intermediário', 'Avançado'];

  // Opção do filtro -> nota mínima.
  static const _avaliacoes = {
    _todos: 0.0,
    'A partir de 4,5': 4.5,
    'A partir de 4,0': 4.0,
    'A partir de 3,0': 3.0,
    'A partir de 2,0': 2.0,
  };

  final ProfissionalRepository _repository = ProfissionalRepository();

  List<Profissional> _profissionais = [];
  bool _carregando = true;

  // Filtros aplicados.
  String _categoria = _todos;
  String _cidade = _todos;
  String _avaliacao = _todos;
  String _nivel = _todos;

  // Cópia do usuário que pode mudar após editar o perfil.
  late Usuarios _usuario = widget.usuario;

  // Permite abrir a barra lateral pelo ícone do cabeçalho.
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _carregarProfissionais();
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

  // Somente os profissionais que atendem a todos os filtros.
  List<Profissional> get _filtrados {
    return _profissionais.where((profissional) {
      if (_categoria != _todos &&
          profissional.profissional_profissao != _categoria)
        return false;
      if (_cidade != _todos && profissional.profissional_cidade != _cidade) {
        return false;
      }
      if (_nivel != _todos && profissional.profissional_experiencia != _nivel) {
        return false;
      }
      return profissional.profissional_avaliacao >= _avaliacoes[_avaliacao]!;
    }).toList();
  }

  // Quantidade de filtros em uso (aparece no botão Filtrar).
  int get _ativos => [
    _categoria,
    _cidade,
    _avaliacao,
    _nivel,
  ].where((filtro) => filtro != _todos).length;

  // "Todos" + valores distintos vindos dos profissionais carregados.
  List<String> _opcoes(Iterable<String> valores) {
    final lista = valores.where((valor) => valor.isNotEmpty).toSet().toList()
      ..sort();
    return [_todos, ...lista];
  }

  Future<void> _abrirEdicaoPerfil() async {
    final atualizado = await Navigator.of(context).push<Usuarios>(
      MaterialPageRoute(builder: (context) => EditarPerfil(usuario: _usuario)),
    );
    if (atualizado != null && mounted) {
      setState(() => _usuario = atualizado);
    }
  }

  // Troca de aba: substitui a tela atual para não empilhar.
  void _abrirHistorico() => Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => Historico(usuario: _usuario)),
  );

  void _abrirAgendamentos() => Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => Agendamentos(usuario: _usuario)),
  );

  // Limpa a pilha e abre a Home levando o usuário (atualizado, se o perfil foi editado).
  void _voltarParaHome() => Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => HomeCliente(usuario: _usuario)),
    (route) => false,
  );

  // Modal de filtros: mesmo padrão do modal de solicitação (DetalhesUsuario).
  Future<void> _abrirFiltros() async {
    // Rascunho: só é aplicado ao tocar em "Filtrar".
    var categoria = _categoria;
    var cidade = _cidade;
    var avaliacao = _avaliacao;
    var nivel = _nivel;

    // true = aplicar, false = limpar, null = fechou sem escolher.
    final aplicar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtrar profissionais',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 30),

                _campoFiltro(
                  'Categoria',
                  _opcoes(_profissionais.map((p) => p.profissional_profissao)),
                  categoria,
                  (valor) => categoria = valor,
                ),
                _campoFiltro(
                  'Cidade',
                  _opcoes(_profissionais.map((p) => p.profissional_cidade)),
                  cidade,
                  (valor) => cidade = valor,
                ),
                _campoFiltro(
                  'Avaliação',
                  _avaliacoes.keys.toList(),
                  avaliacao,
                  (valor) => avaliacao = valor,
                ),
                _campoFiltro('Nível', _niveis, nivel, (valor) => nivel = valor),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Limpar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        minimumSize: const Size(100, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: const Text('Filtrar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (aplicar == null || !mounted) return;

    setState(() {
      _categoria = aplicar ? categoria : _todos;
      _cidade = aplicar ? cidade : _todos;
      _avaliacao = aplicar ? avaliacao : _todos;
      _nivel = aplicar ? nivel : _todos;
    });
  }

  // Rótulo + select do modal.
  Widget _campoFiltro(
    String rotulo,
    List<String> opcoes,
    String valor,
    ValueChanged<String> aoMudar,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        Forms.select(
          rotulo: _todos,
          opcao: opcoes,
          valorInicial: valor,
          onChanged: (selecionado) => aoMudar(selecionado ?? _todos),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profissionais = _filtrados;

    return PopScope(
      canPop: false,
      // O voltar do sistema também devolve o usuário para a Home.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _voltarParaHome();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer: MenuLateral(
          onEditarPerfil: _abrirEdicaoPerfil,
          onSair: () => sairDaConta(context),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  // Cabeçalho
                  // Cabeçalho
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, size: 25),
                          color: Colors.black,
                          tooltip: 'Menu',
                          onPressed: () =>
                              _scaffoldKey.currentState?.openDrawer(),
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
                        const SizedBox(width: 4),
                        _Avatar(caminho: _usuario.usuarios_imagem, raio: 23),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Profissionais de confiança\npara qualquer serviço',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Botão Filtrar, alinhado à direita dos cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 310),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: _carregando ? null : _abrirFiltros,
                            icon: const Icon(Icons.filter_list, size: 20),
                            label: Text(
                              _ativos == 0 ? 'Filtrar' : 'Filtrar ($_ativos)',
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(114, 30),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              backgroundColor: const Color(0xFFEFF6FF),
                              foregroundColor: const Color(0xFF3B82F6),
                              side: const BorderSide(color: Color(0xFF3B82F6)),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Lista de profissionais filtrados
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
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                            itemCount: profissionais.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 24),
                            itemBuilder: (context, indice) => CardProfissional(
                              profissional: profissionais[indice],
                            ),
                          ),
                  ),

                  // Barra inferior (Profissionais selecionado)
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFD9D9D9))),
                    ),
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
                          color: const Color(0xFF424242),
                          tooltip: 'Início',
                          onPressed: _voltarParaHome,
                        ),
                        IconButton(
                          icon: const Icon(Icons.engineering, size: 38),
                          color: const Color(0xFF3B82F6),
                          tooltip: 'Profissionais',
                          onPressed: () {
                            // Já está em Profissionais
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
      ),
    );
  }
}

// Mesmo avatar da HomeCliente (a classe de lá é privada).
class _Avatar extends StatelessWidget {
  final String caminho;
  final double raio;

  const _Avatar({required this.caminho, required this.raio});

  @override
  Widget build(BuildContext context) {
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
