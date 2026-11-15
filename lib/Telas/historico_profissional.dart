import 'dart:io';

import 'package:flutter/material.dart';

import '../Model/usuarios.dart';

enum SituacaoHistoricoProfissional {
  finalizado('Finalizados', 'Finalizado'),
  recusado('Recusados', 'Recusado');

  const SituacaoHistoricoProfissional(this.aba, this.rotulo);

  final String aba;
  final String rotulo;
}

class ServicoHistoricoProfissional {
  const ServicoHistoricoProfissional({
    required this.id,
    required this.servico,
    required this.cliente,
    required this.data,
    required this.situacao,
    this.detalhes,
  });

  final int id;
  final String servico;
  final String cliente;
  final DateTime data;
  final SituacaoHistoricoProfissional situacao;
  final String? detalhes;
}

class HistoricoProfissional extends StatefulWidget {
  const HistoricoProfissional({
    super.key,
    required this.usuario,
    required this.servicos,
    this.onNotificacoes,
    this.onConfiguracoes,
    this.onAgendamentos,
  });

  final Usuarios usuario;
  final List<ServicoHistoricoProfissional> servicos;
  final VoidCallback? onNotificacoes;
  final VoidCallback? onConfiguracoes;
  final VoidCallback? onAgendamentos;

  @override
  State<HistoricoProfissional> createState() => _HistoricoProfissionalState();
}

class _HistoricoProfissionalState extends State<HistoricoProfissional> {
  static const _azul = Color(0xFF3B82F6);
  static const _vermelho = Color(0xFFC9202F);
  static const _borda = Color(0xFFD9D9D9);
  static const _fonte = 'MontSerrat';

  final _ocultos = <int>{};
  String _pesquisa = '';
  var _situacao = SituacaoHistoricoProfissional.finalizado;

  List<ServicoHistoricoProfissional> get _visiveis {
    final servicos = widget.servicos.where((item) {
      return !_ocultos.contains(item.id) &&
          item.situacao == _situacao &&
          (item.servico.toLowerCase().contains(_pesquisa) ||
              item.cliente.toLowerCase().contains(_pesquisa) ||
              _data(item.data).contains(_pesquisa));
    }).toList();
    return servicos..sort((a, b) => b.data.compareTo(a.data));
  }

  String _data(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  Future<void> _excluir(ServicoHistoricoProfissional item) async {
    final descricao = item.situacao == SituacaoHistoricoProfissional.finalizado
        ? 'Ao excluir este histórico, você não poderá mais consultar os '
              'detalhes deste serviço pelo histórico. Tem certeza?'
        : 'Ao excluir este histórico, você perderá o acesso aos detalhes '
              'desta solicitação recusada pelo histórico. Tem certeza?';
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _borda,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _azul),
          borderRadius: BorderRadius.circular(8),
        ),
        titlePadding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Deseja excluir histórico',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _fonte,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Fechar',
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        content: Text(descricao, style: const TextStyle(fontFamily: _fonte)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: _estiloBotao(Colors.black, Colors.white, Colors.black),
                  child: const Text('Não'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: _estiloBotao(Colors.white, _azul, _azul),
                  child: const Text('Sim'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmado == true && mounted) {
      setState(() => _ocultos.add(item.id));
    }
  }

  ButtonStyle _estiloBotao(Color texto, Color fundo, Color borda) {
    return OutlinedButton.styleFrom(
      foregroundColor: texto,
      backgroundColor: fundo,
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      side: BorderSide(color: borda),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      textStyle: const TextStyle(fontFamily: _fonte),
    );
  }

  Widget _card(ServicoHistoricoProfissional item) {
    final cor = item.situacao == SituacaoHistoricoProfissional.finalizado
        ? const Color(0xFF187342)
        : _vermelho;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: _borda),
        borderRadius: BorderRadius.circular(5),
      ),
      child: ListTile(
        title: Text(
          item.servico,
          style: const TextStyle(
            fontFamily: _fonte,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.cliente),
            Text(_data(item.data)),
            Text(item.situacao.rotulo, style: TextStyle(color: cor)),
            if (item.detalhes case final String detalhes
                when detalhes.isNotEmpty)
              Text(detalhes),
          ],
        ),
        trailing: IconButton(
          tooltip: 'Excluir histórico de ${item.servico}',
          color: _vermelho,
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _excluir(item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visiveis = _visiveis;
    final imagem = File(widget.usuario.usuarios_imagem);
    final temFoto =
        widget.usuario.usuarios_imagem.isNotEmpty && imagem.existsSync();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: CircleAvatar(
          backgroundColor: const Color(0xFFEFF6FF),
          backgroundImage: temFoto ? FileImage(imagem) : null,
          child: temFoto ? null : const Icon(Icons.person, color: _azul),
        ),
        actions: [
          IconButton(
            tooltip: 'Notificações',
            onPressed: widget.onNotificacoes,
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            tooltip: 'Configurações',
            onPressed: widget.onConfiguracoes,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(34, 32, 34, 20),
            children: [
              const Text(
                'Veja seus últimos serviços finalizados e recusados.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: _fonte, fontSize: 16),
              ),
              const SizedBox(height: 36),
              const Text(
                'Pesquise no histórico',
                style: TextStyle(fontFamily: _fonte, fontSize: 14),
              ),
              const SizedBox(height: 6),
              TextField(
                onChanged: (valor) =>
                    setState(() => _pesquisa = valor.trim().toLowerCase()),
                style: const TextStyle(fontFamily: _fonte),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  hintText: 'Pesquisar',
                  suffixIcon: const Icon(Icons.search),
                  suffixIconConstraints: const BoxConstraints(minWidth: 38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                children: [
                  for (final situacao in SituacaoHistoricoProfissional.values)
                    Semantics(
                      selected: _situacao == situacao,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _situacao = situacao),
                        style: _situacao == situacao
                            ? _estiloBotao(Colors.white, _azul, _azul)
                            : _estiloBotao(Colors.black, Colors.white, _azul),
                        child: Text(situacao.aba),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (visiveis.isEmpty)
                Text(
                  _pesquisa.isEmpty
                      ? 'Nenhum serviço ${_situacao.rotulo.toLowerCase()}.'
                      : 'Nenhum serviço encontrado.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: _fonte),
                ),
              for (final item in visiveis)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _card(item),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: const Color(0xFFEFF6FF),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Semantics(
                selected: true,
                label: 'Histórico',
                child: const Tooltip(
                  message: 'Histórico',
                  excludeFromSemantics: true,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: _azul,
                      size: 38,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Início',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.home, size: 36),
              ),
              IconButton(
                tooltip: 'Agendamentos',
                onPressed: widget.onAgendamentos,
                icon: const Icon(Icons.event_available, size: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
