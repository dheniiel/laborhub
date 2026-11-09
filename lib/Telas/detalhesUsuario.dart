import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:laborhub/Formularios/forms.dart';
import 'package:laborhub/Model/profissional.dart';
import '../Model/servico.dart';
import '../Model/pessoJuridica.dart';
import '../Model/pessoaFisica.dart';
import '../Model/usuarios.dart';
import '../Utils/validacao.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';




class  DetalhesUsuario extends StatefulWidget{
  final Profissional profissional;

  const DetalhesUsuario({super.key, required this.profissional});


  @override
  State<DetalhesUsuario> createState() => _DetalhesUsuarioProfissional();


}


class _DetalhesUsuarioProfissional extends State<DetalhesUsuario> {

  final _formKey = GlobalKey<FormState>();
  final _servicos_data = TextEditingController();
  final _servicos_quantidade = TextEditingController();
  final _solicitacao_observacao = TextEditingController();


  final _mascaraData = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  Widget _barraAvaliacao(
      int estrelas,
      int quantidade,
      int total,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$estrelas ${estrelas == 1 ? 'estrela' : 'estrelas'}',
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : quantidade / total,
                minHeight: 6,
                backgroundColor: const Color(0xFFD9D9D9),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF3B82F6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$quantidade',
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }




  @override
  Widget build(BuildContext context) {

    final profissional = widget.profissional;
    final caminho = profissional.profissional_imagem;
    final temFoto = caminho.isNotEmpty && File(caminho).existsSync();

    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Perfil do Profissional',
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
                          widget.profissional.profissional_nome,
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
                          const Icon(
                            Icons.location_on_outlined,
                            size: 19,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              "${widget.profissional.profissional_cidade} - ${widget.profissional.profissional_uf}",
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Campo de telefone
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 19,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              "${widget.profissional.profissional_telefone}",
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          )
                        ],
                      ),


                      const SizedBox(height: 4),

                      // Campo de email
                      Row(
                        children: [
                          const Icon(
                            Icons.mail,
                            size: 19,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              "${widget.profissional.profissional_email}",
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          )
                        ],
                      ),


                      const SizedBox(height: 4),

                      // Campo de email
                      Row(
                        children: [
                         Expanded(
                           child: Text.rich(
                             TextSpan(
                               children: [
                                 TextSpan(
                                   text: widget.profissional.profissional_servicos_nome,
                                   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                 ),

                                 TextSpan(
                                   text: " - ${widget.profissional.profissional_data}",
                                 ),
                               ]
                             )
                           ),
                         )
                        ],
                      ),

                      const SizedBox(height: 6),

                      if(widget.profissional.profissional_tipo_cobranca == 'Negociar') ... [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Valor a negociar",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  color: Color.fromARGB(1000, 34, 197, 94),
                                ),

                              ),
                            )
                          ],
                        ),

                      ] else ... [

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'R\$ ${profissional.profissional_preco.toStringAsFixed(2).replaceAll('.', ',')} - ${widget.profissional.profissional_tipo_cobranca}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                color: Color.fromARGB(1000, 34, 197, 94),
                              ),

                            ),
                          )
                        ],
                      ),

                      ],

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

                      Text(
                          "Profissional: ${widget.profissional.profissional_experiencia} - ${widget.profissional.profissional_observacao}",
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                )
              ],

            ),

            const SizedBox(height: 20),

            // card de avaliacao
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFF0F0F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // NOTA E ESTRELAS
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            widget.profissional.profissional_avaliacao
                                .toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final nota =
                                  widget.profissional.profissional_avaliacao;

                              return Icon(
                                nota >= index + 1
                                    ? Icons.star
                                    : nota >= index + 0.5
                                    ? Icons.star_half
                                    : Icons.star_border,
                                color: const Color(0xFFFFC107),
                                size: 22,
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'de 5 estrelas',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: 1,
                      height: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: const Color(0xFFEEEEEE),
                    ),

                    // QUANTIDADE POR NOTA
                    Expanded(
                      child: Column(
                        children: [
                          for (int estrela = 5; estrela >= 1; estrela--)
                            _barraAvaliacao(
                              estrela,
                              widget.profissional.avaliacoesPorEstrela[estrela - 1],
                              widget.profissional.profissional_total_avaliacoes,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Ver Comentario
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  // Botao para mandar pra uma proxima tela
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => (),
                  //   ),
                  // );
                },
                child: const Text(
                  'Ver comentarios',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Montserrat',
                    color: Color(0xFF3B82F6),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 130),

            FilledButton(
              child: const Text("Enviar solicitação"),


              // Modal para enviar solicitação
             onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  // Distância entre o modal e as bordas da tela.
                  backgroundColor: Colors.white,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 500,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Solicitação de Serviço",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,


                            ),
                          ),

                          const SizedBox(height: 30),

                          const Text(
                            "Data para serviço",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Forms(
                            controlador: _servicos_data,
                            tipagemValor: TextInputType.datetime,
                            rotulo: "dd/mm/aaaa",
                            formatadores: [_mascaraData],
                            validador: Validacao.servicosData,
                          ),

                          const SizedBox(height: 24),


                          // Quantidade de dias
                          const Text(
                            "Quantidade de dias",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Forms(
                            controlador: _servicos_quantidade,
                            tipagemValor: TextInputType.number,
                            rotulo: "Quantidade de dias",
                            validador: Validacao.quantidade,
                          ),

                          const SizedBox(height: 24),

                          const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Text(
                              "Observação",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),

                          Forms(
                            controlador: _solicitacao_observacao,
                            tipagemValor: TextInputType.multiline,
                            rotulo: "Descreva um pouco da solicitação...",
                            maxLinha: 5 ,

                          ),

                          const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton(
                            child: const Text("Enviar"),

                            onPressed: () {
                            //   função para enviar solicitação
                            },

                            style: FilledButton.styleFrom(

                                backgroundColor: Color.fromARGB(1000, 59, 130, 246),
                                minimumSize: const Size(100, 35),
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                textStyle: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w300,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.circular(5),

                                )
                            ),

                          ),

                        ]
                      )




                        ],
                      ),
                    ),
                  ),
                ),
              );
            },


              style: FilledButton.styleFrom(
                  backgroundColor: Color.fromARGB(1000, 59, 130, 246),
                  minimumSize: const Size(500, 35),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(5),

                  )
              ),

            ),
          ],
        ),
      ),


    );
  }



}