import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:laborhub/Formularios/forms.dart';
import 'package:laborhub/Model/profissional.dart';
import 'package:laborhub/Model/solicitacaoProfissional.dart';
import '../Model/servico.dart';
import '../Model/pessoJuridica.dart';
import '../Model/pessoaFisica.dart';
import '../Model/usuarios.dart';
import '../Utils/validacao.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../Repository/solicitacao_repository.dart';




class  DetalhesSolicitacaoServico extends StatefulWidget{
  final Map<String, dynamic> solicitacao;

  const DetalhesSolicitacaoServico({super.key, required this.solicitacao});


  @override
  State<DetalhesSolicitacaoServico> createState() => _DetalhesUsuarioProfissional();


}


class _DetalhesUsuarioProfissional extends State<DetalhesSolicitacaoServico> {

  final _formKey = GlobalKey<FormState>();
  final _servicos_data = TextEditingController();
  final _servicos_quantidade = TextEditingController();
  final _solicitacao_observacao = TextEditingController();

  String _formatarData(String valor) {
    final data = DateTime.tryParse(valor);

    if (data == null) return 'Não informada';

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  Future<void> _enviarSolicitacao(int clienteId) async {
    if(!(_formKey.currentState?.validate() ?? false)) return;

    final textoData = _servicos_data.text.trim(); //transofmrando dateTime para String

    final partes = textoData.split('/');
    final dataServico = DateTime(
      int.parse(partes[2]),
      int.parse(partes[1]),
      int.parse(partes[0]),
    );

    final agora = DateTime.now();

  // await SolicitacaoRepository().enviarSolicitacao(
  //     solicitacao_data: dataServico,
  //     solicitacao_data_atual: agora,
  //     solicitacao_quantidade: int.parse(_servicos_quantidade.text.trim()),
  //     solicitacao_observacao: _solicitacao_observacao.text.trim(),
  //     solicitacao_criada_em: agora,
  //     solicitacao_endereco_id: widget.profissional.profissional_endereco_id,
  //     solicitacao_usuarios_id: clienteId,
  //     servicos_id: widget.profissional.profissional_servicos_id,
  // );


  }


  @override
  void initState() {
    super.initState();

    _servicos_data.text =
        widget.solicitacao['cliente_solicitacao_data']?.toString() ?? '';

    _servicos_quantidade.text =
        widget.solicitacao['cliente_solicitacao_quantidade']?.toString() ?? '';

    _solicitacao_observacao.text =
        widget.solicitacao['cliente_solicitacao_observacao']?.toString() ?? '';
  }



  final _mascaraData = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp(r'[0-9]')},
  );





  @override
  Widget build(BuildContext context) {

    final caminho = widget.solicitacao['cliente_imagem'] ?? '';
    final temFoto = caminho.isNotEmpty && File(caminho).existsSync();

    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Serviço Pendente',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'MontSerrat',
            fontSize: 20,
            color: Colors.black,
          ),
        ),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
          onPressed: (){
            Navigator.pop(context);
          },
        ),
      ),



      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16), // Arredonda os cantos.
                  child: Container(
                    width: 120,  // Define a largura.
                    height: 150, // Define a altura.
                    color: Colors.white,
                    child: temFoto
                        ? Image.file(File(caminho), fit: BoxFit.cover)
                        : const Icon(Icons.person, size: 60),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Texto do nome
                      Text(
                          widget.solicitacao['cliente_nome']?.toString() ?? 'Sem nome',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,

                        ),
                      ),

                      const SizedBox(height: 4),

                      // Campo de localização
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Endereço: ',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                    text:
                                    '${widget.solicitacao['cliente_rua'] ?? ''} '
                                        '${widget.solicitacao['cliente_complemento'] ?? ''} - '
                                        '${widget.solicitacao['cliente_bairro'] ?? ''}',
                                  ),
                                ],
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),

                      // CIDADE

                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Cidade: ',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                    text:
                                    '${widget.solicitacao['cliente_cidade'] ?? ''} '
                                        '${widget.solicitacao['cliente_uf'] ?? ''} - '
                                  ),
                                ],
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),


                      // Data solicitacao
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Data Solicitadada: ',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                      text:
                                      _formatarData(widget.solicitacao['cliente_solicitacao_data_atual'])
                                  ),
                                ],
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),


                      // Data para serviço
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Data para serviço: ',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                      text:
                                      _formatarData(widget.solicitacao['cliente_solicitacao_data'])
                                  ),
                                ],
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),


                      // Quantidade de dias
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Dias solicitados: ',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                      text: '${widget.solicitacao['cliente_solicitacao_quantidade']} dia(s)'
                                  ),
                                ],
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),


                    ],
                  ),
                )
              ],

            ),

            const SizedBox(height: 20),

            // Row de descrição
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Descrição',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),


                    ],
                  ),
                )
              ],

            ),

            const SizedBox(height: 20),





            const SizedBox(height: 160),

        // FilledButton(
        //   onPressed: () async {
        //     bool enviando = false;
        //     final messenger = ScaffoldMessenger.of(context);
        //
        //     await showDialog<void>(
        //       context: context,
        //       barrierDismissible: false,
        //       builder: (dialogContext) {
        //         return StatefulBuilder(
        //           builder: (modalContext, setStateModal) {
        //             return PopScope(
        //               canPop: !enviando,
        //               child: Dialog(
        //                 backgroundColor: Colors.white,
        //                 insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        //                 child: SizedBox(
        //                   width: 500,
        //                   child: SingleChildScrollView(
        //                     padding: const EdgeInsets.all(20),
        //                     child: Form(
        //                       key: _formKey,
        //                       child: Column(
        //                         mainAxisSize: MainAxisSize.min,
        //                         crossAxisAlignment: CrossAxisAlignment.start,
        //                         children: [
        //                           const Text(
        //                             'Solicitação de Serviço',
        //                             style: TextStyle(
        //                               fontSize: 20,
        //                               fontWeight: FontWeight.w600,
        //                             ),
        //                           ),
        //                           const SizedBox(height: 30),
        //
        //                           const Text(
        //                             'Data para serviço',
        //                             style: TextStyle(
        //                               fontSize: 15,
        //                               fontWeight: FontWeight.w600,
        //                             ),
        //                           ),
        //                           const SizedBox(height: 5),
        //
        //                           Forms(
        //                             controlador: _servicos_data,
        //                             tipagemValor: TextInputType.datetime,
        //                             rotulo: 'dd/mm/aaaa',
        //                             formatadores: [_mascaraData],
        //                             validador: Validacao.servicosData,
        //                           ),
        //                           const SizedBox(height: 24),
        //
        //                           const Text(
        //                             'Quantidade de dias',
        //                             style: TextStyle(
        //                               fontSize: 15,
        //                               fontWeight: FontWeight.w600,
        //                             ),
        //                           ),
        //                           const SizedBox(height: 5),
        //
        //                           Forms(
        //                             controlador: _servicos_quantidade,
        //                             tipagemValor: TextInputType.number,
        //                             rotulo: 'Quantidade de dias',
        //                             validador: Validacao.quantidade,
        //                           ),
        //                           const SizedBox(height: 24),
        //
        //                           const Text(
        //                             'Observação',
        //                             style: TextStyle(
        //                               fontSize: 15,
        //                               fontWeight: FontWeight.w600,
        //                             ),
        //                           ),
        //                           const SizedBox(height: 5),
        //
        //                           Forms(
        //                             controlador: _solicitacao_observacao,
        //                             tipagemValor: TextInputType.multiline,
        //                             rotulo: 'Descreva um pouco da solicitação...',
        //                             maxLinha: 5,
        //                           ),
        //                           const SizedBox(height: 24),
        //
        //                           Row(
        //                             mainAxisAlignment: MainAxisAlignment.center,
        //                             children: [
        //                               TextButton(
        //                                 onPressed: enviando
        //                                     ? null
        //                                     : () {
        //                                   Navigator.of(dialogContext).pop();
        //                                 },
        //                                 child: const Text('Cancelar'),
        //                               ),
        //                               const SizedBox(width: 12),
        //
        //                               FilledButton(
        //                                 onPressed: enviando
        //                                     ? null
        //                                     : () async {
        //                                   if (!(_formKey.currentState
        //                                       ?.validate() ??
        //                                       false)) {
        //                                     return;
        //                                   }
        //
        //                                   setStateModal(() {
        //                                     enviando = true;
        //                                   });
        //
        //                                   try {
        //                                     await _enviarSolicitacao(
        //                                       widget.profissional
        //                                           .profissional_usuarios_id,
        //                                     );
        //                                   } catch (erro) {
        //                                     if (!modalContext.mounted) return;
        //
        //                                     setStateModal(() {
        //                                       enviando = false;
        //                                     });
        //
        //                                     messenger.showSnackBar(
        //                                       SnackBar(
        //                                         content: Text(
        //                                           'Não foi possível enviar: $erro',
        //                                         ),
        //                                         backgroundColor: Colors.red,
        //                                       ),
        //                                     );
        //                                     return;
        //                                   }
        //
        //                                   if (!dialogContext.mounted) return;
        //
        //                                   Navigator.of(dialogContext).pop();
        //
        //                                   messenger.showSnackBar(
        //                                     const SnackBar(
        //                                       content: Text(
        //                                         'Solicitação de serviço enviada!',
        //                                         style: TextStyle(
        //                                           fontWeight: FontWeight.w600,
        //                                         ),
        //                                       ),
        //                                       backgroundColor: Colors.green,
        //
        //                                     ),
        //                                   );
        //                                 },
        //                                 style: FilledButton.styleFrom(
        //                                   backgroundColor: const Color(0xFF3B82F6),
        //                                   minimumSize: const Size(100, 40),
        //                                   shape: RoundedRectangleBorder(
        //                                     borderRadius: BorderRadius.circular(5),
        //                                   ),
        //                                 ),
        //                                 child: enviando
        //                                     ? const SizedBox(
        //                                   width: 20,
        //                                   height: 20,
        //                                   child: CircularProgressIndicator(
        //                                     strokeWidth: 2,
        //                                     color: Color(0xFF3B82F6),
        //                                   ),
        //                                 )
        //                                     : const Text('Enviar'),
        //                               ),
        //                             ],
        //                           ),
        //                         ],
        //                       ),
        //                     ),
        //                   ),
        //                 ),
        //               ),
        //             );
        //           },
        //         );
        //       },
        //     );
        //   },
        //   style: FilledButton.styleFrom(
        //     backgroundColor: const Color(0xFF3B82F6),
        //     minimumSize: const Size(500, 35),
        //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        //     textStyle: const TextStyle(
        //       fontSize: 18,
        //       fontWeight: FontWeight.w400,
        //     ),
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(5),
        //     ),
        //   ),
        //   child: const Text('Enviar solicitação'),
        // ),


          ],
        ),
      ),


    );
  }



}