import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
            radius: 28,
            backgroundColor: Colors.grey.shade300,
            foregroundImage: imagemUrl != null && imagemUrl!.isNotEmpty
            ? NetworkImage(imagemUrl!)
            : null,
            child: const Icon(Icons.person, color: Colors.grey,),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
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

                _informacao('Data solicitação: ', dataSolicitacao),
                _informacao('Data para serviço: ', dataServico),
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
        style: const TextStyle(fontSize: 14),
      );

    }

}