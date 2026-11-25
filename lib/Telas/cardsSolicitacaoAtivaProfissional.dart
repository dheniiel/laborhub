import 'package:flutter/material.dart';
import 'dart:io';
import 'detalheSolicitacaoServico.dart';
import '../Repository/solicitacao_repository.dart';

class CardsSolicitacaoAtivaProfissional extends StatelessWidget {

  final String nome;
  final String endereco;
  final String dataSolicitacao;
  final String dataServico;
  final int dias;
  final String? imagemUrl;
  final String? descricao;
  final int idSolicitacao;
  final Future<void> Function() onAtualizar;
  // final  onVer;


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
  });

  final agora = DateTime.now();


  Future<void> finalizarSolicitacao (int solicitacaoId) async {

    await SolicitacaoRepository().finalizarSolicitacao(
      solicitacaoId,

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
                        onPressed: () async {
                          bool enviando = false;
                          final messenger = ScaffoldMessenger.of(context);

                         final finalizou =  await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (dialogContext) {
                              return StatefulBuilder(
                                builder: (modalContext, setStateModal) {
                                  return PopScope(
                                    canPop: !enviando,
                                    child: AlertDialog(
                                      backgroundColor: Colors.white,
                                      title: const Text(
                                        'Finalizar solicitação',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      content: const Text(
                                        'Deseja realmente finalizar esta solicitação?',
                                        textAlign: TextAlign.center,

                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: enviando
                                              ? null
                                              : () => Navigator.of(dialogContext).pop(),
                                          child: const Text('Não'),
                                        ),
                                        FilledButton(
                                          onPressed: enviando
                                              ? null
                                              : () async {
                                            setStateModal(() {
                                              enviando = true;
                                            });

                                            try {
                                              await finalizarSolicitacao(
                                                idSolicitacao
                                              );
                                            } catch (erro, stackTrace) {
                                              if (!modalContext.mounted) return;

                                              setStateModal(() {
                                                enviando = false;
                                              });

                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Não foi possível finalizar: $erro',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );

                                              debugPrint('ERRO AO RECUSAR: $erro');
                                              debugPrintStack(stackTrace: stackTrace);
                                              return;
                                            }

                                            if (!dialogContext.mounted ||
                                                !context.mounted) {
                                              return;
                                            }

                                            Navigator.of(dialogContext).pop(true);

                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Solicitação finalizada com sucesso!',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );

                                          },
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(0xFF3B82F6),
                                            minimumSize: const Size(100, 40),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                          ),
                                          child: enviando
                                              ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                              : const Text('Sim'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                          if (finalizou == true && context.mounted) {
                            await onAtualizar();
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xff3b82f6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)
                          ),
                        ),
                        child: const Text('Finalizar'),
                      ),
                    )

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

}