import 'dart:io';

import 'package:flutter/material.dart';

import '../Model/profissional.dart';


class PerfilProfissional extends StatelessWidget {
  // Profissional escolhido no card da HomeCliente.
  final Profissional profissional;

  const PerfilProfissional({super.key, required this.profissional});

  @override
  Widget build(BuildContext context) {
    // A foto é um caminho de arquivo, como no cadastro.
    final caminho = profissional.profissional_imagem;
    final temFoto = caminho.isNotEmpty && File(caminho).existsSync();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Perfil',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 65,
                    backgroundColor: const Color(0xFF3B82F6),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: temFoto ? FileImage(File(caminho)) : null,
                      child: temFoto
                          ? null
                          : const Icon(Icons.person, size: 100, color: Color(0xFF3B82F6)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profissional.profissional_nome,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profissional.profissional_profissao,
                    style: const TextStyle(fontSize: 15, fontFamily: 'Montserrat', color: Colors.black),
                  ),
                  Text(
                    '${profissional.profissional_cidade}, ${profissional.profissional_uf}',
                    style: const TextStyle(fontSize: 13, fontFamily: 'Montserrat', color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 5; i++)
                        Icon(
                          i < profissional.profissional_avaliacao.round()
                              ? Icons.star
                              : Icons.star_border,
                          size: 24,
                          color: const Color(0xFFFFC107),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        profissional.profissional_avaliacao.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 14, fontFamily: 'Montserrat'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Observação',
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      profissional.profissional_observacao,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                        height: 1.4,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'R\$ ${profissional.profissional_preco.toStringAsFixed(2).replaceAll('.', ',')} - Total',
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}