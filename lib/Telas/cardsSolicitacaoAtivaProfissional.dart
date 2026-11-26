import 'package:flutter/material.dart';
import 'dart:io';
import 'detalheSolicitacaoServico.dart';
import '../Repository/solicitacao_repository.dart';
import 'package:laborhub/Formularios/forms.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';

class CardsSolicitacaoAtivaProfissional extends StatelessWidget {

  final String nome;
  final String endereco;
  final String dataSolicitacao;
  final String dataServico;
  final int dias;
  final String? imagemUrl;
  final String? descricao;
  final int idSolicitacao;
  final String telefone;
  final Future<void> Function() onAtualizar;
  // final  onVer;
  final _mascaraValor = CurrencyTextInputFormatter.currency(
    locale: 'pt_BR',
    decimalDigits: 2,
    symbol: 'R\$',
  );


   CardsSolicitacaoAtivaProfissional ({
    super.key,
    required this.nome,
    required this.endereco,
    required this.dataSolicitacao,
    required this.dataServico,
    required this.dias,
    // required this.onVer,
    this.imagemUrl,
    this.descricao,
     required this.idSolicitacao,
     required this.onAtualizar,
     required this.telefone,
  });

  final agora = DateTime.now();

  Future<void> finalizarSolicitacao(
      int solicitacaoId,
      double valorServico, [
        String? descricao,
      ]) async {
    final texto = descricao?.trim();

    await SolicitacaoRepository().finalizarSolicitacao(
      solicitacaoId,
      valorServico,
      texto == null || texto.isEmpty ? null : texto,
    );
  }

  String _formatarData(String valor) {
    final data = DateTime.tryParse(valor);

    if (data == null) return 'Não informada';

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    final caminho = imagemUrl ?? '';
    final temFoto = caminho.isNotEmpty && File(caminho).existsSync();
    return
      Align(
        alignment: Alignment.topCenter,
          child: Container(
            width: 320,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),

          // Alocação da imagem de perfil do solicitante
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: temFoto
                    ? FileImage(File(caminho))
                    : null,
                child: temFoto
                    ? null
                    : const Icon(Icons.person, color: Colors.grey),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 3),


                    _informacao('Data solicitada: ', _formatarData(dataSolicitacao)),
                    _informacao('Data para serviço: ', _formatarData(dataServico)),
                    _informacao('Dias solicitados: ', '$dias dias(s)'),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () => _verDetalhesServico(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          minimumSize: const Size(100, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text('Ver detalhes'),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),

        ),

      );


  }
    Widget _informacao(String titulo, String valor) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: titulo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: valor),
          ],
        ),
        style: const TextStyle(fontSize: 11.5),
      );

    }


  Future<void> _verDetalhesServico(BuildContext context) async {
    final valorController = TextEditingController();
    final descricaoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    double? lerValorServico(String? texto) {
      final valor = (texto ?? '')
          .trim()
          .replaceFirst(RegExp(r'^R\$\s*'), '');

      // Aceita 1250,50 e 1.250,50.
      if (!RegExp(r'^(?:\d+|\d{1,3}(?:\.\d{3})+)(?:,\d{1,2})?$')
          .hasMatch(valor)) {
        return null;
      }

      final numero = double.tryParse(
        valor.replaceAll('.', '').replaceAll(',', '.'),
      );

      if (numero == null || numero > 99999999.99) return null;
      return numero;
    }

    var enviando = false;
    String? erroEnvio;
    Future<dynamic>? fechamento;

    final finalizou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      builder: (sheetContext) {
        fechamento = ModalRoute.of(sheetContext)?.completed;

        return StatefulBuilder(
          builder: (sheetContext, atualizarSheet) {
            return PopScope(
              canPop: !enviando,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    24 + MediaQuery.of(sheetContext).viewInsets.bottom,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Detalhes do serviço',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Cliente: $nome'),
                        Text('Endereço: $endereco'),
                        Text("Telefone: $telefone"),
                        Text("Data solicitada:  ${_formatarData(dataSolicitacao)}"),
                        Text("Data para serviço: ${_formatarData(dataServico)}", textAlign: TextAlign.justify,),
                        const SizedBox(height: 4),
                        Text("Descrição: $descricao"),
                        const SizedBox(height: 24),

                        const Text(
                          'Valor final',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Forms(
                          controlador: valorController,
                          tipagemValor: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          formatadores: [_mascaraValor],
                          rotulo: "R\$ 0,00",
                          validador: (texto) => lerValorServico(texto) == null
                              ? 'Informe o valor aplicado ao serviço.'
                              : null,
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Descrição da conclusão (opcional)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Forms(
                          controlador: descricaoController,
                          tipagemValor: TextInputType.multiline,
                          rotulo: 'Descreva o serviço realizado',
                          validador: (_) => null,
                          maxLinha: 5,
                        ),

                        if (erroEnvio != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            erroEnvio!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                        const SizedBox(height: 24),

                        FilledButton(
                          onPressed: enviando
                              ? null
                              : () async {
                            debugPrint('[Finalizar] Botão pressionado');

                            final formulario = formKey.currentState;
                            if (formulario == null) {
                              debugPrint('[Finalizar] formKey não está ligada ao Form');
                              return;
                            }

                            if (!formulario.validate()) {
                              debugPrint('[Finalizar] Validação do formulário falhou');
                              return;
                            }

                            final valorServico = lerValorServico(valorController.text);
                            if (valorServico == null) {
                              debugPrint('[Finalizar] Valor inválido: "${valorController.text}"');
                              return;
                            }

                            final descricao = descricaoController.text.trim();

                            atualizarSheet(() {
                              enviando = true;
                              erroEnvio = null;
                            });

                            try {
                              debugPrint('[Finalizar] Chamando a API');
                              await finalizarSolicitacao(
                                idSolicitacao,
                                valorServico,
                                descricao.isEmpty ? null : descricao,
                              );
                              debugPrint('[Finalizar] API retornou sem erro');

                              if (!sheetContext.mounted) return;
                              Navigator.of(sheetContext).pop(true);
                            } catch (erro) {
                              debugPrint('[Finalizar] Erro ao finalizar: $erro');
                              if (!sheetContext.mounted) return;

                              atualizarSheet(() {
                                enviando = false;
                                erroEnvio = 'Não foi possível finalizar o serviço.';
                              });
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            minimumSize: const Size(100, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Text(enviando ? 'Finalizando...' : 'Finalizar'),
                        ),
                        TextButton(
                          onPressed: enviando
                              ? null
                              : () => Navigator.of(sheetContext).pop(false),
                          child: const Text('Voltar'),
                        ),
                      ],
                    ),

                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await fechamento;
    valorController.dispose();
    descricaoController.dispose();

    if (finalizou == true && context.mounted) {
      await onAtualizar();
    }
  }

}