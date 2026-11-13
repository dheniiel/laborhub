import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../Formularios/forms.dart';
import '../Model/profissional.dart';
import '../Model/usuarios.dart';
import '../Repository/profissional_repository.dart';
import '../Repository/sessao_repository.dart';
import 'login.dart';
import 'perfilProfissional.dart';
import 'editarPerfil.dart';
import 'historico.dart';
import 'agendamentos.dart';
import 'detalhesUsuario.dart';


class Homeprofissional  extends StatefulWidget{

  final Usuarios usuarios;

  const Homeprofissional({
    super.key,
    required this.usuarios,
  });

  @override
  State<Homeprofissional> createState() => _HomeProfissionalState();

}


class _HomeProfissionalState extends State<Homeprofissional> {

  final SessaoRepository _sessao = SessaoRepository();

  late Usuarios _usuario = widget.usuarios;


  Future<void> _abrirEdicaoPerfil() async {
    final atualizado = await Navigator.of(context).push<Usuarios>(
      MaterialPageRoute(builder: (context) => EditarPerfil(usuario: _usuario)),
    );
    if (atualizado != null && mounted) {
      setState(() => _usuario = atualizado);
    }
  }




  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsetsGeometry.fromLTRB(16, 10, 12, 0),
                  child: Row(
                    children: [
                      Tooltip(
                        message: "Meu perfil",
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _abrirEdicaoPerfil,
                          child: _Avatar(caminho: _usuario.usuarios_imagem, raio: 23),
                        ),
                      )
                    ],
                  ),

                ),
                const SizedBox(height: 55),

                Text(
                    "Veja os status das suas solicitações",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),

              ],
            ),



          ),

        )
      ),



    );
  }




}



//Classe para avatar
class _Avatar extends StatelessWidget {

  final String caminho;
  final double raio;

  const _Avatar({required this.caminho, required this.raio});

  @override
  Widget build(BuildContext context) {
    // A foto é salva como caminho de arquivo no cadastro (EnderecoTela).
    final temFoto = caminho.isNotEmpty && File(caminho).existsSync();

    return CircleAvatar(
      radius: raio,
      backgroundColor: const Color(0xFFF4F4F4),
      backgroundImage: temFoto ? FileImage(File(caminho)) : null,
      child: temFoto
          ? null
          : Icon(
        Icons.person,
        size: raio * 1.4,
        color: const Color(0xFF3B82F6),
      ),
    );
  }
}


class CardServico extends StatelessWidget {
  final String titulo;
  final int quantidade;

  const CardServico({
    required this.titulo,
    required this.quantidade,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titulo,
            textAlign: TextAlign.start,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 12),
          Text(
            '$quantidade',
            style: TextStyle(
              fontSize: 22,
              color: Color.fromARGB(1000, 59, 130, 246),
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }


}