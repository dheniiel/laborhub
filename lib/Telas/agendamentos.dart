import 'dart:io';

import 'package:flutter/material.dart';

import '../Model/solicitacao.dart';
import '../Model/usuarios.dart';
import '../Repository/solicitacao_repository.dart';
import 'editarPerfil.dart';
import 'historico.dart';
import 'encontrarProfissionais.dart';
import 'homeCliente.dart' show HomeCliente;
import 'menuLateral.dart';

class Agendamentos extends StatefulWidget {
  final Usuarios usuario;
  final bool _profissional;
  final VoidCallback? onHistorico;

  const Agendamentos({super.key, required this.usuario})
    : _profissional = false,
      onHistorico = null;

  const Agendamentos.profissional({
    super.key,
    required this.usuario,
    required this.onHistorico,
  }) : _profissional = true;

  @override
  State<Agendamentos> createState() => _AgendamentosState();
}

class _AgendamentosState extends State<Agendamentos> {
  static const _meses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  static const _semana = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

  final SolicitacaoRepository _repository = SolicitacaoRepository();

  List<Solicitacao> _solicitacoes = [];
  bool _carregando = true;
  bool _falhaAoCarregar = false;

  // Mês exibido (sempre no dia 1).
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);

  // Cópia do usuário que pode mudar após editar o perfil.
  late Usuarios _usuario = widget.usuario;

  // Permite abrir a barra lateral pelo ícone do cabeçalho.
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _carregarSolicitacoes();
  }

  Future<void> _carregarSolicitacoes() async {
    try {
      final solicitacoes = widget._profissional
          ? await _repository.listarAgendamentosProfissional()
          : await _repository.Listar();
      if (!mounted) return;
      setState(() => _solicitacoes = solicitacoes);
    } catch (_) {
      if (!mounted) return;
      if (widget._profissional) {
        setState(() => _falhaAoCarregar = true);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar os agendamentos.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _tentarNovamente() {
    setState(() {
      _falhaAoCarregar = false;
      _carregando = true;
    });
    _carregarSolicitacoes();
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
  void _abrirProfissionais() => Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (context) => EncontrarProfissionais(usuario: _usuario),
    ),
  );

  void _abrirHistorico() => Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => Historico(usuario: _usuario)),
  );

  // Limpa a pilha e abre a Home levando o usuário (atualizado, se o perfil foi editado).
  void _voltarParaHome() => Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => HomeCliente(usuario: _usuario)),
    (route) => false,
  );

  void _mudarMes(int quantidade) {
    // DateTime ajusta a virada de ano (mês 13 -> janeiro do ano seguinte).
    setState(() => _mes = DateTime(_mes.year, _mes.month + quantidade));
  }

  bool _mesmoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Solicitados no dia (agendados).
  List<Solicitacao> _agendados(DateTime dia) => _solicitacoes
      .where(
        (solicitacao) =>
            (!widget._profissional ||
                solicitacao.solicitacao_status == 'Ativo') &&
            _mesmoDia(solicitacao.solicitacao_data, dia),
      )
      .toList();

  // Concluídos no dia (executados).
  List<Solicitacao> _executados(DateTime dia) => _solicitacoes.where((
    solicitacao,
  ) {
    if (widget._profissional) {
      return solicitacao.solicitacao_status == 'Finalizado' &&
          _mesmoDia(
            solicitacao.solicitacao_conclusao ?? solicitacao.solicitacao_data,
            dia,
          );
    }
    final conclusao = solicitacao.solicitacao_conclusao;
    return conclusao != null && _mesmoDia(conclusao, dia);
  }).toList();

  bool _temServico(DateTime dia) =>
      _agendados(dia).isNotEmpty || _executados(dia).isNotEmpty;

  // Modal com os serviços do dia selecionado.
  void _abrirDia(DateTime dia) {
    final agendados = _agendados(dia);
    final executados = _executados(dia);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            Text(
              'Serviços em ${_data(dia)}',
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),

            if (agendados.isNotEmpty) ...[
              const SizedBox(height: 20),
              _TituloSecao(
                texto: widget._profissional ? 'Aceitos' : 'Agendados',
              ),
              const SizedBox(height: 10),
              for (final solicitacao in agendados)
                _CardServico(
                  solicitacao: solicitacao,
                  executado: false,
                  profissional: widget._profissional,
                ),
            ],

            if (executados.isNotEmpty) ...[
              const SizedBox(height: 20),
              _TituloSecao(
                texto: widget._profissional ? 'Finalizados' : 'Executados',
              ),
              const SizedBox(height: 10),
              for (final solicitacao in executados)
                _CardServico(
                  solicitacao: solicitacao,
                  executado: true,
                  profissional: widget._profissional,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dia(int numero) {
    final dia = DateTime(_mes.year, _mes.month, numero);
    final temServico = _temServico(dia);
    final hoje = _mesmoDia(dia, DateTime.now());

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: temServico ? () => _abrirDia(dia) : null,
      child: Container(
        margin: const EdgeInsets.all(4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: temServico ? const Color(0xFF3B82F6) : null,
          border: hoje && !temServico
              ? Border.all(color: const Color(0xFF3B82F6), width: 1.5)
              : null,
        ),
        child: Text(
          '$numero',
          style: TextStyle(
            fontSize: 15,
            fontFamily: 'Montserrat',
            fontWeight: temServico || hoje ? FontWeight.w700 : FontWeight.w400,
            color: temServico
                ? Colors.white
                : hoje
                ? const Color(0xFF3B82F6)
                : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _calendario() {
    final diasNoMes = DateTime(_mes.year, _mes.month + 1, 0).day;
    final inicio =
        DateTime(_mes.year, _mes.month, 1).weekday % 7; // domingo = 0

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Column(
        children: [
          // Mês e navegação
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 30),
                color: const Color(0xFF3B82F6),
                tooltip: 'Mês anterior',
                onPressed: () => _mudarMes(-1),
              ),
              Expanded(
                child: Text(
                  '${_meses[_mes.month - 1]} ${_mes.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 30),
                color: const Color(0xFF3B82F6),
                tooltip: 'Próximo mês',
                onPressed: () => _mudarMes(1),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Dias da semana
          Row(
            children: [
              for (final dia in _semana)
                Expanded(
                  child: Text(
                    dia,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7F7F7F),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          // Grade do mês: 7 colunas que ocupam toda a largura disponível.
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < inicio; i++) const SizedBox.shrink(),
              for (var dia = 1; dia <= diasNoMes; dia++) _dia(dia),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget._profissional,
      // O voltar do sistema também devolve o usuário para a Home.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !widget._profissional) _voltarParaHome();
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

                  Expanded(
                    child: _carregando
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF3B82F6),
                            ),
                          )
                        : _falhaAoCarregar
                        ? Center(
                            child: TextButton(
                              onPressed: _tentarNovamente,
                              child: const Text(
                                'Não foi possível carregar os agendamentos. Tentar novamente',
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            child: Column(
                              children: [
                                Text(
                                  widget._profissional
                                      ? 'Acompanhe seus serviços\naceitos e finalizados'
                                      : 'Acompanhe seus serviços\nagendados e executados',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                _calendario(),

                                const SizedBox(height: 16),

                                // Legenda
                                Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF3B82F6),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Dias com serviços. Toque para ver os detalhes.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Montserrat',
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                  ),

                  // Barra inferior (Agendamentos selecionado)
                  Container(
                    decoration: widget._profissional
                        ? const BoxDecoration(color: Color(0xFFEFF6FF))
                        : const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFFD9D9D9)),
                            ),
                          ),
                    padding: const EdgeInsets.fromLTRB(44, 4, 44, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.assignment_outlined, size: 38),
                          color: const Color(0xFF424242),
                          tooltip: 'Histórico',
                          onPressed: widget._profissional
                              ? widget.onHistorico
                              : _abrirHistorico,
                        ),
                        IconButton(
                          icon: const Icon(Icons.home, size: 38),
                          color: const Color(0xFF424242),
                          tooltip: 'Início',
                          onPressed: widget._profissional
                              ? () => Navigator.maybePop(context)
                              : _voltarParaHome,
                        ),

                        if (!widget._profissional)
                          IconButton(
                            icon: const Icon(Icons.engineering, size: 38),
                            color: const Color(0xFF424242),
                            tooltip: 'Profissionais',
                            onPressed: _abrirProfissionais,
                          ),

                        IconButton(
                          icon: const Icon(Icons.event_available, size: 38),
                          color: const Color(0xFF3B82F6),
                          tooltip: 'Agendamentos',
                          onPressed: () {
                            // Já está em Agendamentos
                          },
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

class _TituloSecao extends StatelessWidget {
  final String texto;

  const _TituloSecao({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w600,
        color: Color(0xFF3B82F6),
      ),
    );
  }
}

class _CardServico extends StatelessWidget {
  final Solicitacao solicitacao;
  final bool executado; // true: mostra a data de conclusão

  final bool profissional;

  const _CardServico({
    required this.solicitacao,
    required this.executado,
    required this.profissional,
  });

  static const _estiloPequeno = TextStyle(
    fontSize: 11.5,
    fontFamily: 'Montserrat',
    color: Colors.black,
  );

  @override
  Widget build(BuildContext context) {
    // Mesmas cores de status do Histórico.
    final corStatus = switch (solicitacao.solicitacao_status) {
      'Finalizado' => const Color(0xFF22C55E),
      'Ativo' => const Color(0xFF3B82F6),
      'Pendente' => const Color(0xFFF97316),
      _ => const Color(0xFFEF4444),
    };
    final motivo = solicitacao.solicitacao_motivo;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(
            caminho: profissional
                ? solicitacao.clienteImagem ?? ''
                : solicitacao.profissional_imagem,
            raio: 22,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profissional
                            ? solicitacao.clienteNome ?? 'Cliente'
                            : solicitacao.profissional_nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Montserrat',
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      profissional && solicitacao.solicitacao_status == 'Ativo'
                          ? 'Aceito'
                          : solicitacao.solicitacao_status,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        color: corStatus,
                      ),
                    ),
                  ],
                ),

                Text(
                  profissional
                      ? solicitacao.servicosNome ?? ''
                      : solicitacao.profissional_profissao,
                  style: _estiloPequeno,
                ),

                const SizedBox(height: 8),

                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            executado &&
                                solicitacao.solicitacao_conclusao != null
                            ? 'Concluído em:  '
                            : profissional
                            ? 'Agendado para:  '
                            : 'Solicitado em:  ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: _data(
                          executado
                              ? solicitacao.solicitacao_conclusao ??
                                    solicitacao.solicitacao_data
                              : solicitacao.solicitacao_data,
                        ),
                      ),
                    ],
                  ),
                  style: _estiloPequeno,
                ),

                if (motivo != null) ...[
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Motivo:  ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: motivo),
                      ],
                    ),
                    style: _estiloPequeno,
                  ),
                ],

                const SizedBox(height: 8),

                Text(
                  'R\$ ${_moeda(solicitacao.servicos_valor)} - Total',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ),
        ],
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

// 2026-05-15 -> 15/05/2026
String _data(DateTime data) {
  String doisDigitos(int numero) => numero.toString().padLeft(2, '0');
  return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year}';
}

// 549.99 -> 549,99
String _moeda(double valor) => valor.toStringAsFixed(2).replaceAll('.', ',');
