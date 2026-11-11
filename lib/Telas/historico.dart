import 'dart:io';

import 'package:flutter/material.dart';

import '../Formularios/forms.dart';
import '../Model/solicitacao.dart';
import '../Model/usuarios.dart';
import '../Repository/solicitacao_repository.dart';
import 'editarPerfil.dart';
import 'agendamentos.dart';


class Historico extends StatefulWidget {
  // Usuário da sessão, recebido da HomeCliente.
  final Usuarios usuario;

  const Historico({super.key, required this.usuario});

  @override
  State<Historico> createState() => _HistoricoState();
}

class _HistoricoState extends State<Historico> {
  final _pesquisaController = TextEditingController();
  final SolicitacaoRepository _repository = SolicitacaoRepository();

  List<Solicitacao> _solicitacoes = [];
  bool _carregando = true;
  String _secao = 'Finalizado'; // Finalizado, Pendente ou Recusado

  // Cópia do usuário que pode mudar após editar o perfil.
  late Usuarios _usuario = widget.usuario;

  @override
  void initState() {
    super.initState();
    // Refaz o filtro a cada letra digitada.
    _pesquisaController.addListener(() => setState(() {}));
    _carregarSolicitacoes();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  Future<void> _carregarSolicitacoes() async {
    try {
      final solicitacoes = await _repository.Listar();
      if (!mounted) return;
      setState(() => _solicitacoes = solicitacoes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível carregar o histórico.')),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // Seção selecionada + pesquisa por nome ou profissão.
  List<Solicitacao> get _filtradas {
    final termo = _pesquisaController.text.trim().toLowerCase();

    return _solicitacoes.where((solicitacao) {
      if (solicitacao.solicitacao_status != _secao) return false;
      if (termo.isEmpty) return true;
      return solicitacao.profissional_nome.toLowerCase().contains(termo) ||
          solicitacao.profissional_profissao.toLowerCase().contains(termo);
    }).toList();
  }

  Future<void> _abrirEdicaoPerfil() async {
    final atualizado = await Navigator.of(context).push<Usuarios>(
      MaterialPageRoute(builder: (context) => EditarPerfil(usuario: _usuario)),
    );
    if (atualizado != null && mounted) {
      setState(() => _usuario = atualizado);
    }
  }

  Future<void> _abrirAgendamentos() async {
    final atualizado = await Navigator.of(context).push<Usuarios>(
      MaterialPageRoute(
        builder: (context) => Agendamentos(usuario: _usuario),
      ),
    );

    if (atualizado != null && mounted) {
      setState(() => _usuario = atualizado);
    }
  }


  // Volta para a Home levando o usuário (atualizado, se o perfil foi editado).
  void _voltarParaHome() => Navigator.pop(context, _usuario);

  Future<void> _cancelar(Solicitacao solicitacao) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar solicitação'),
        content: Text(
          'Deseja cancelar a solicitação para ${solicitacao.profissional_nome}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _repository.cancelar(solicitacao.solicitacao_id);
      if (!mounted) return;
      setState(() => _solicitacoes.remove(solicitacao));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação cancelada.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível cancelar a solicitação.')),
      );
    }
  }

  void _detalhar(Solicitacao solicitacao) {
    final conclusao = solicitacao.solicitacao_conclusao;
    final motivo = solicitacao.solicitacao_motivo;
    final observacao = solicitacao.solicitacao_observacao;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              solicitacao.profissional_nome,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Text(
              solicitacao.profissional_profissao,
              style: const TextStyle(fontSize: 14, fontFamily: 'Montserrat'),
            ),
            const SizedBox(height: 16),
            _rotuloValor('Status:', solicitacao.solicitacao_status, 14),
            _rotuloValor('Data solicitação:', _data(solicitacao.solicitacao_data), 14),
            if (conclusao != null)
              _rotuloValor('Data conclusão:', _data(conclusao), 14),
            _rotuloValor('Valor:', 'R\$ ${_moeda(solicitacao.servicos_valor)} - Total', 14),
            if (motivo != null) _rotuloValor('Motivo:', motivo, 14),
            if (observacao != null) _rotuloValor('Observação:', observacao, 14),
          ],
        ),
      ),
    );
  }

  // Botão de seção: mesmo estilo do seletor Pessoa Física/Jurídica do cadastro.
  Widget _botaoSecao(String status, String rotulo) {
    final selecionado = _secao == status;

    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _secao = status),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          backgroundColor: selecionado ? const Color(0xFF3B82F6) : Colors.white,
          foregroundColor: selecionado ? Colors.white : Colors.black,
          side: const BorderSide(color: Color(0xFF3B82F6)),
          textStyle: const TextStyle(fontSize: 14, fontFamily: 'Montserrat'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: Text(rotulo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final solicitacoes = _filtradas;

    return PopScope(
      canPop: false,
      // O voltar do sistema também devolve o usuário para a Home.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _voltarParaHome();
      },
      child: Scaffold(
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
                            child: _Avatar(caminho: _usuario.usuarios_imagem, raio: 23),
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Veja suas solicitações finalizadas,\npendentes e recusadas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Pesquisa e seções
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Text(
                            'Pesquise no histórico',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Montserrat',
                              color: Colors.black,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Forms(
                          controlador: _pesquisaController,
                          tipagemValor: TextInputType.text,
                          rotulo: 'Pesquisar',
                          icone: Icons.search,
                        ),

                        const SizedBox(height: 38),

                        Row(
                          children: [
                            _botaoSecao('Finalizado', 'Finalizado'),
                            const SizedBox(width: 8),
                            _botaoSecao('Pendente', 'Pendentes'),
                            const SizedBox(width: 8),
                            _botaoSecao('Recusado', 'Recusados'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Lista da seção selecionada
                  Expanded(
                    child: _carregando
                        ? const Center(
                            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                          )
                        : solicitacoes.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nenhuma solicitação encontrada',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'Montserrat',
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(40, 38, 40, 16),
                                itemCount: solicitacoes.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 16),
                                itemBuilder: (context, indice) {
                                  final solicitacao = solicitacoes[indice];
                                  return _CardSolicitacao(
                                    solicitacao: solicitacao,
                                    // Pendente: cancelar. Finalizado/Recusado: detalhar.
                                    onAcao: solicitacao.solicitacao_status == 'Pendente'
                                        ? () => _cancelar(solicitacao)
                                        : () => _detalhar(solicitacao),
                                  );
                                },
                              ),
                  ),

                  // Barra inferior (Histórico selecionado)
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
                          color: const Color(0xFF3B82F6),
                          tooltip: 'Histórico',
                          onPressed: () {
                            // Já está no Histórico
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.home, size: 38),
                          color: const Color(0xFF424242),
                          tooltip: 'Início',
                          onPressed: _voltarParaHome,
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


class _CardSolicitacao extends StatelessWidget {

  final Solicitacao solicitacao;
  final VoidCallback onAcao; // Detalhar ou Cancelar

  const _CardSolicitacao({required this.solicitacao, required this.onAcao});

  @override
  Widget build(BuildContext context) {
    // Cor do botão, texto de destaque, cor do destaque e rótulo do botão por status.
    final (corBotao, destaque, corDestaque, acao) = switch (solicitacao.solicitacao_status) {
      'Finalizado' => (
          const Color(0xFF3B82F6),
          'R\$${_moeda(solicitacao.servicos_valor)} - Total',
          const Color(0xFF22C55E),
          'Detalhar',
        ),
      'Pendente' => (
          const Color(0xFFF97316),
          'Pendente',
          const Color(0xFFF97316),
          'Cancelar',
        ),
      _ => (
          const Color(0xFFEF4444),
          'Recusado',
          const Color(0xFFEF4444),
          'Detalhar',
        ),
    };

    final conclusao = solicitacao.solicitacao_conclusao;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _Avatar(caminho: solicitacao.profissional_imagem, raio: 23),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  solicitacao.profissional_nome,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Montserrat',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  solicitacao.profissional_profissao,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontFamily: 'Montserrat',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                _rotuloValor('Data solicitação:', _data(solicitacao.solicitacao_data), 10.5),
                if (conclusao != null)
                  _rotuloValor('Data conclusão:', _data(conclusao), 10.5),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                destaque,
                style: TextStyle(
                  fontSize: 11.5,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  color: corDestaque,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAcao,
                style: FilledButton.styleFrom(
                  backgroundColor: corBotao,
                  minimumSize: const Size(88, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(fontSize: 14, fontFamily: 'Montserrat'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ),
                child: Text(acao),
              ),
            ],
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
          : Icon(Icons.person, size: raio * 1.4, color: const Color(0xFF3B82F6)),
    );
  }
}


// "Rótulo: valor" com o rótulo em negrito.
Widget _rotuloValor(String rotulo, String valor, double tamanho) {
  return Padding(
    padding: EdgeInsets.only(bottom: tamanho > 12 ? 8 : 0),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$rotulo  ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: valor),
        ],
      ),
      style: TextStyle(fontSize: tamanho, fontFamily: 'Montserrat', color: Colors.black),
    ),
  );
}

// 2026-05-15 -> 15/05/2026
String _data(DateTime data) {
  String doisDigitos(int numero) => numero.toString().padLeft(2, '0');
  return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year}';
}

// 549.99 -> 549,99
String _moeda(double valor) => valor.toStringAsFixed(2).replaceAll('.', ',');