import 'dart:io';

import 'package:flutter/material.dart';

import '../Model/solicitacao.dart';
import '../Repository/solicitacao_repository.dart';

// Detalhes de um serviço finalizado e avaliação do profissional (uma vez por serviço).
// Retorna true ao Histórico quando a avaliação é enviada.
class AvaliacaoServico extends StatefulWidget {
  final Solicitacao solicitacao;

  const AvaliacaoServico({super.key, required this.solicitacao});

  @override
  State<AvaliacaoServico> createState() => _AvaliacaoServicoState();
}

class _AvaliacaoServicoState extends State<AvaliacaoServico> {
  static const _maxComentario = 500;

  late final _comentarioController = TextEditingController(
    text: widget.solicitacao.avaliacao_descricao ?? '',
  );

  late int _nota = widget.solicitacao.avaliacao_notas ?? 0;
  late bool _avaliado = widget.solicitacao.avaliado;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    // Atualiza o contador de caracteres.
    _comentarioController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_nota == 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Toque em uma estrela para avaliar.')),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      await SolicitacaoRepository().avaliar(
        widget.solicitacao.solicitacao_id,
        _nota,
        _comentarioController.text.trim(),
      );
    } catch (erro) {
      if (!mounted) return;
      setState(() => _enviando = false);
      messenger.showSnackBar(
        SnackBar(content: Text('$erro'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _enviando = false;
      _avaliado = true;
    });
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Avaliação enviada com sucesso!',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final solicitacao = widget.solicitacao;
    final conclusao = solicitacao.solicitacao_conclusao;
    final caminho = solicitacao.profissional_imagem;
    final temFoto = caminho.isNotEmpty && File(caminho).existsSync();

    return PopScope(
      canPop: false,
      // Avisa o Histórico para recarregar quando houve avaliação.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_avaliado);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: const Text(
            'Detalhes de serviço',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar',
            onPressed: () => Navigator.of(context).pop(_avaliado),
          ),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 30, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Foto e dados do profissional
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 140,
                            height: 140,
                            color: const Color(0xFFF4F4F4),
                            child: temFoto
                                ? Image.file(File(caminho), fit: BoxFit.cover)
                                : const Icon(
                                    Icons.person,
                                    size: 70,
                                    color: Color(0xFF3B82F6),
                                  ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                solicitacao.profissional_nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontFamily: 'Montserrat',
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _rotuloValor(
                                'Cidade:',
                                '${solicitacao.profissional_cidade}, '
                                    '${solicitacao.profissional_uf.toUpperCase()}',
                              ),
                              _rotuloValor(
                                'Data Solicitação:',
                                _data(solicitacao.solicitacao_data_atual),
                              ),
                              _rotuloValor(
                                'Data para serviço:',
                                _data(solicitacao.solicitacao_data),
                              ),
                              if (conclusao != null)
                                _rotuloValor(
                                  'Data de conclusão:',
                                  _data(conclusao),
                                ),
                              _rotuloValor(
                                'Dias solicitados:',
                                '${solicitacao.solicitacao_quantidade} dia(s)',
                              ),
                              _rotuloValor(
                                'Contato:',
                                solicitacao.profissional_telefone,
                              ),
                              _rotuloValor(
                                'Email:',
                                solicitacao.profissional_email,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    Center(
                      child: Text(
                        _avaliado
                            ? 'Sua avaliação'
                            : 'Como foi sua experiência?',
                        style: const TextStyle(
                          fontSize: 15,
                          fontFamily: 'Montserrat',
                          color: Colors.black,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Estrelas: tocáveis até a avaliação ser enviada.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var estrela = 1; estrela <= 5; estrela++)
                          IconButton(
                            onPressed: _avaliado || _enviando
                                ? null
                                : () => setState(() => _nota = estrela),
                            tooltip: '$estrela estrela(s)',
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            icon: Icon(
                              estrela <= _nota
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 56,
                              color: estrela <= _nota
                                  ? const Color(0xFFFFC107)
                                  : const Color(0xFF616161),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: _avaliado
                          // Status de serviço já avaliado.
                          ? const Text(
                              'Serviço avaliado',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF22C55E),
                              ),
                            )
                          : const Text(
                              'Toque em uma estrela para avaliar',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'Montserrat',
                                color: Colors.black,
                              ),
                            ),
                    ),

                    const SizedBox(height: 32),

                    if (!_avaliado || _comentarioController.text.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          _avaliado ? 'Seu comentário' : 'Deixe seu comentário',
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                            color: Colors.black,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Campo de comentário com contador interno (0/500).
                      Stack(
                        children: [
                          TextField(
                            controller: _comentarioController,
                            readOnly: _avaliado || _enviando,
                            maxLength: _maxComentario,
                            minLines: 4,
                            maxLines: 4,
                            keyboardType: TextInputType.multiline,
                            cursorColor: const Color(0xFF3B82F6),
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Montserrat',
                              color: Colors.black,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Conte mais sobre sua experiência....',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Montserrat',
                                color: Color(0xFFA6A6A6),
                              ),
                              counterText: '',
                              isDense: true,
                              contentPadding: EdgeInsets.fromLTRB(7, 11, 7, 26),
                              filled: true,
                              fillColor: Colors.white,
                              border: _borda,
                              enabledBorder: _borda,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                                borderSide: BorderSide(
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 6,
                            child: Text(
                              '${_comentarioController.text.length}/$_maxComentario',
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'Montserrat',
                                color: Color(0xFF616161),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 26),

                    if (!_avaliado)
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: _enviando ? null : _enviar,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            minimumSize: const Size(136, 40),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'Montserrat',
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: _enviando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF3B82F6),
                                  ),
                                )
                              : const Text('Enviar'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _borda = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(5)),
  borderSide: BorderSide(color: Color(0xFF7F7F7F)),
);

// "Rótulo: valor" com o rótulo em negrito.
Widget _rotuloValor(String rotulo, String valor) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$rotulo ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: valor),
        ],
      ),
      style: const TextStyle(
        fontSize: 13,
        fontFamily: 'Montserrat',
        color: Colors.black,
      ),
    ),
  );
}

// 2026-05-15 -> 15/05/2026
String _data(DateTime data) {
  String doisDigitos(int numero) => numero.toString().padLeft(2, '0');
  return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year}';
}