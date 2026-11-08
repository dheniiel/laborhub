import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:laborhub/Formularios/forms.dart';
import 'package:laborhub/Model/profissional.dart';
import '../Model/servico.dart';
import '../Model/pessoJuridica.dart';
import '../Model/pessoaFisica.dart';
import '../Model/usuarios.dart';




class  DetalhesUsuario extends StatefulWidget{
  final Profissional profissional;

  const DetalhesUsuario({super.key, required this.profissional});


  @override
  State<DetalhesUsuario> createState() => _DetalhesUsuarioProfissional();


}


class _DetalhesUsuarioProfissional extends State<DetalhesUsuario> {




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
                    height: 120, // Define a altura.
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


                    ],
                  ),
                )
              ],

            )
          ],
        ),
      ),


    );
  }



}