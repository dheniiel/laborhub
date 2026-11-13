import 'package:flutter/material.dart';
import 'dart:io';

class CardsSolicitacaopendenteprofissional extends StatelessWidget {

  final String nome;
  final String endereco;
  final String dataSolicitacao;
  final String dataServico;
  final int dias;
  final String? imagemUrl;
  // final  onVer;


  const CardsSolicitacaopendenteprofissional ({
    super.key,
    required this.nome,
    required this.endereco,
    required this.dataSolicitacao,
    required this.dataServico,
    required this.dias,
    // required this.onVer,
    this.imagemUrl,
  });

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
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                        endereco,
                      style: const TextStyle(fontSize: 14),
                    ),

                    const SizedBox(height: 8),


                    _informacao('Data solicitada: ', _formatarData(dataSolicitacao)),
                    _informacao('Data para serviço: ', _formatarData(dataServico)),
                    _informacao('Dias solicitados: ', '$dias dias(s)'),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () {} ,
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

                        child: const Text('Ver'),

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