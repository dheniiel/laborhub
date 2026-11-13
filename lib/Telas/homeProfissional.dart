import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../Formularios/forms.dart';
import '../Model/profissional.dart';
import '../Model/usuarios.dart';
import '../Repository/profissional_repository.dart';
import '../Repository/sessao_repository.dart';
import '../Repository/solicitacao_repository.dart';
import 'login.dart';
import 'perfilProfissional.dart';
import 'editarPerfil.dart';
import 'historico.dart';
import 'agendamentos.dart';
import 'detalhesUsuario.dart';
import 'cardsSolicitacaoPendenteProfissional.dart';


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
  final SolicitacaoRepository _solicitacaoRepository = SolicitacaoRepository();

  late Usuarios _usuario = widget.usuarios;
   int _totalPendente = 0;
   int _totalAtivo = 0;
   bool _tipoServico = true;


  Future<void> _carregarPendente() async {

    try {
      final total = await _solicitacaoRepository.listarServicoPendente();
      final totalAtivo = await _solicitacaoRepository.listarServicoAtivos();
      final usuarioId = widget.usuarios.usuarios_id;

      if (usuarioId == null) return;

      final solicitacoes = await _solicitacaoRepository
          .solicitacaoPendente(usuarioId);

      if(!mounted) return;

      setState(() {
        _totalPendente = total;
        _totalAtivo = totalAtivo;

      });

    } catch(_){
      if(!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível carregar suas solicitações")),
      );
    }
  }


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
                    "Veja os status das suas solicitações ",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                          height: 80,
                          width: 60,
                          child: CardServico(
                              titulo: "Serviços pendentes",
                              quantidade: _totalPendente,
                              message: "Veja quem solicitou seu serviço.",
                          ),
                      ),

                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child:  SizedBox(
                        height: 80,
                        width: 60,
                        child: CardServico(
                            titulo: "Serviços ativos",
                            quantidade: _totalAtivo,
                            message: "Veja seus serviços atuais.",
                        ),
                      )
                    )

                  ],

                ),

                const SizedBox(height: 30),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //   Pessoa fisica
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _tipoServico = true;
                          });
                        },

                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0,40),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            backgroundColor: _tipoServico
                                ? Color.fromARGB(1000, 59, 130, 246)
                                : Colors.white,
                            foregroundColor: _tipoServico
                                ? Colors.white
                                : Colors.black,
                            side: const BorderSide(color: Color.fromARGB(1000, 59, 130, 246)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),

                            )
                        ),
                        child: const Text("Pendentes"),
                      ),
                    ),

                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _tipoServico = false;
                          });
                        },

                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0,40),
                            backgroundColor: !_tipoServico
                                ? Color.fromARGB(1000, 59, 130, 246)
                                : Colors.white,
                            foregroundColor: !_tipoServico
                                ? Colors.white
                                : Colors.black,
                            side: const BorderSide(color: Color.fromARGB(1000, 59, 130, 246)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),

                            )
                        ),
                        child: const Text("Ativos"),
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 30),

                Column(
                  children: [

                    for(final solicitacao)
                  ],
                )



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
  final String message;

  const CardServico({
    required this.titulo,
    required this.quantidade,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 10),
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
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            'Quantidade(s): $quantidade',
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 12,
              color: Color.fromARGB(1000, 59, 130, 246),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),

          Text(
            message,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey,
              fontWeight: FontWeight.w200,
            ),
          ),
        ],
      ),
    );
  }


}