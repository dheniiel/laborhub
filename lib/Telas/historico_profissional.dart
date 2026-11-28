import 'dart:io';

import 'package:flutter/material.dart';

import '../Model/usuarios.dart';
import '../Data/sessao_dao.dart';
import '../Repository/auth_api.dart';
import 'menuLateral.dart';

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
    this.imagemCliente = '',
    this.dataSolicitacao,
    this.dataAgendada,
    this.dataConclusao,
    this.descricao,
    this.motivoRecusa,
  });

  final int id;
  final String servico;
  final String cliente;
  final String imagemCliente;
  final DateTime data;
  final SituacaoHistoricoProfissional situacao;
  final String? detalhes;
  final DateTime? dataSolicitacao;
  final DateTime? dataAgendada;
  final DateTime? dataConclusao;
  final String? descricao;
  final String? motivoRecusa;
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

  final _api = AuthApi();
  final _sessao = SessaoDao();
  final _excluindo = <int>{};
  List<ServicoHistoricoProfissional> _servicos = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _servicos = List.of(widget.servicos);
    _carregar();
  }

  Future<Map<String, dynamic>> _consultar(
    String rota,
    Map<String, Object?> dados,
  ) async {
    final sessao = await _sessao.buscar();
    if (sessao == null ||
        sessao.usuario.usuarios_id != widget.usuario.usuarios_id) {
      throw const AuthException('Sua sessão expirou. Entre novamente.', 401);
    }
    return _api.post(rota, dados, token: sessao.token);
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resposta = await _consultar(
        'solicitacoes/historico-profissional',
        {},
      );
      final servicos = (resposta['historico'] as List).map((registro) {
        final item = Map<String, dynamic>.from(registro as Map);
        return ServicoHistoricoProfissional(
          id: item['solicitacao_id'] as int,
          servico: item['servico'] as String,
          cliente: item['cliente'] as String,
          imagemCliente: item['cliente_imagem'] as String? ?? '',
          data: DateTime.parse(item['data'] as String),
          situacao: item['situacao'] == 'Finalizado'
              ? SituacaoHistoricoProfissional.finalizado
              : SituacaoHistoricoProfissional.recusado,
          detalhes: item['detalhes'] as String?,
          dataSolicitacao: DateTime.tryParse(
            (item['data_solicitacao'] ?? item['criada_em']) as String? ?? '',
          ),
          dataAgendada: DateTime.tryParse(
            item['data_agendada'] as String? ?? '',
          ),
          dataConclusao: DateTime.tryParse(
            item['data_conclusao'] as String? ?? '',
          ),
          descricao: item['descricao'] as String?,
          motivoRecusa: item['motivo_recusa'] as String?,
        );
      }).toList();
      if (!mounted) return;
      setState(() => _servicos = servicos);
    } catch (erro) {
      if (!mounted) return;
      setState(
        () => _erro = erro is AuthException
            ? erro.mensagem
            : 'Não foi possível carregar o histórico.',
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _pesquisa = '';
  var _situacao = SituacaoHistoricoProfissional.finalizado;

  List<ServicoHistoricoProfissional> get _visiveis {
    final servicos = _servicos.where((item) {
      return item.situacao == _situacao &&
          (item.servico.toLowerCase().contains(_pesquisa) ||
              item.cliente.toLowerCase().contains(_pesquisa) ||
              [
                item.data,
                item.dataSolicitacao,
                item.dataAgendada,
                item.dataConclusao,
              ].whereType<DateTime>().any(
                (data) => _data(data).contains(_pesquisa),
              ));
    }).toList();
    return servicos..sort((a, b) => b.data.compareTo(a.data));
  }

  String _data(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  Future<void> _excluir(ServicoHistoricoProfissional item) async {
    if (_excluindo.contains(item.id)) return;
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

    if (confirmado != true || !mounted || _excluindo.contains(item.id)) return;
    setState(() => _excluindo.add(item.id));
    try {
      await _consultar('solicitacoes/historico-profissional/ocultar', {
        'solicitacao_id': item.id,
      });
      if (!mounted) return;
      setState(() => _servicos.removeWhere((servico) => servico.id == item.id));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Histórico excluído.')));
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            erro is AuthException
                ? erro.mensagem
                : 'Não foi possível excluir o histórico. Tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _excluindo.remove(item.id));
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
    final foto = File(item.imagemCliente);
    final temFoto = item.imagemCliente.isNotEmpty && foto.existsSync();
    final cor = item.situacao == SituacaoHistoricoProfissional.finalizado
        ? const Color(0xFF187342)
        : _vermelho;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: _borda),
        borderRadius: BorderRadius.circular(5),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF4F4F4),
          backgroundImage: temFoto ? FileImage(foto) : null,
          child: temFoto ? null : const Icon(Icons.person, color: _azul),
        ),
        title: Text(
          item.cliente,
          style: const TextStyle(
            fontFamily: _fonte,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Solicitado em: ${item.dataSolicitacao == null ? 'Não informada' : _data(item.dataSolicitacao!)}',
            ),
            Text(
              'Agendado para: ${item.dataAgendada == null ? 'Não informada' : _data(item.dataAgendada!)}',
            ),
            if (item.situacao == SituacaoHistoricoProfissional.finalizado)
              Text(
                'Finalizado em: ${item.dataConclusao == null ? 'Não informada' : _data(item.dataConclusao!)}',
              ),
            Text(item.situacao.rotulo, style: TextStyle(color: cor)),
            Text(
              'Descrição: ${item.descricao?.trim().isNotEmpty == true ? item.descricao!.trim() : 'Não informada'}',
            ),
            if (item.situacao == SituacaoHistoricoProfissional.recusado)
              Text(
                'Motivo da recusa: ${item.motivoRecusa?.trim().isNotEmpty == true ? item.motivoRecusa!.trim() : 'Não informado'}',
              ),
          ],
        ),
        trailing: IconButton(
          tooltip: 'Excluir histórico de ${item.servico}',
          color: _vermelho,
          icon: const Icon(Icons.delete_outline),
          onPressed: _excluindo.contains(item.id) ? null : () => _excluir(item),
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
      drawer: MenuLateral(
        onEditarPerfil: () => widget.onConfiguracoes?.call(),
        onSair: () => sairDaConta(context),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Notificações',
            onPressed: widget.onNotificacoes,
            icon: const Icon(Icons.notifications, color: Colors.black),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onConfiguracoes,
              child: CircleAvatar(
                backgroundColor: const Color(0xFFF4F4F4),
                backgroundImage: temFoto ? FileImage(imagem) : null,
                child: temFoto ? null : const Icon(Icons.person, color: _azul),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Text(
                  'Veja seus últimos serviços\nfinalizados e recusados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: _fonte, fontSize: 16),
                ),
              ),
              Container(
                width: double.infinity,
                color: _azul,
                padding: const EdgeInsets.fromLTRB(30, 16, 30, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pesquise no histórico',
                      style: TextStyle(fontFamily: _fonte, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (valor) => setState(
                        () => _pesquisa = valor.trim().toLowerCase(),
                      ),
                      style: const TextStyle(fontFamily: _fonte),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF4F4F4),
                        isDense: true,
                        hintText: 'Pesquisar',
                        suffixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  children: [
                    for (final situacao in SituacaoHistoricoProfissional.values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Semantics(
                            selected: _situacao == situacao,
                            child: OutlinedButton(
                              onPressed: () =>
                                  setState(() => _situacao = situacao),
                              style: _situacao == situacao
                                  ? _estiloBotao(Colors.white, _azul, _azul)
                                  : _estiloBotao(
                                      Colors.black,
                                      Colors.white,
                                      _azul,
                                    ),
                              child: Text(situacao.aba),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _carregando
                    ? const Center(
                        child: CircularProgressIndicator(color: _azul),
                      )
                    : _erro != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _erro!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontFamily: _fonte),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _carregar,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : visiveis.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _pesquisa.isEmpty
                                ? 'Nenhum serviço ${_situacao.rotulo.toLowerCase()}.'
                                : 'Nenhum serviço encontrado.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: _fonte,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                        itemCount: visiveis.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, index) => _card(visiveis[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _azul,
            borderRadius: BorderRadius.circular(40),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: 'Histórico',
                isSelected: true,
                onPressed: () {},
                icon: const Icon(Icons.assignment_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(48, 48),
                  shape: const CircleBorder(),
                ),
              ),
              IconButton(
                tooltip: 'Início',
                color: Colors.black,
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.home_rounded),
              ),
              IconButton(
                tooltip: 'Agendamentos',
                color: Colors.black,
                onPressed: widget.onAgendamentos,
                icon: const Icon(Icons.event_available_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
