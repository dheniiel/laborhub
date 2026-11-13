import 'dart:io';
import 'dart:convert';
import 'dart:ui';
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
  List<Map<String, dynamic>> _solicitacoes = [];
  List<Map<String, dynamic>> _solicitacaoAtivas = [];


  @override
  void initState() {
    super.initState();
    _carregarPendente();
  }


  Future<void> _carregarPendente() async {
    try {
      final usuarioId = widget.usuarios.usuarios_id;

      if (usuarioId == null) return;

      final total = await _solicitacaoRepository
          .listarServicoPendente(usuarioId);

      final totalAtivo =
      await _solicitacaoRepository.listarServicoAtivo();

      final solicitacoes = await _solicitacaoRepository
          .solicitacaoPendente(usuarioId);

      final solicitacoesAtivo = await _solicitacaoRepository.SolicitacaoProfissionalAtivo(usuarioId);

      if (!mounted) return;

      setState(() {
        _totalPendente = total;
        _totalAtivo = totalAtivo;
        _solicitacaoAtivas = solicitacoesAtivo;
        _solicitacoes = solicitacoes;
      });
    } catch (erro, pilha) {
      debugPrint('ERRO AO CARREGAR: $erro');
      debugPrintStack(stackTrace: pilha);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar suas solicitações'),
        ),
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

  Future<void> _sair() async {
    try {
      await _sessao.sair();
    } catch (_) {
      // Mesmo com erro local, volta ao login.
    }
    _voltarAoLogin(null);
  }

  void _voltarAoLogin(String? mensagem) {
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
    );
    if (mensagem != null) {
      mensageiro.showSnackBar(SnackBar(content: Text(mensagem)));
    }
  }





  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
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
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.notifications, size: 25),
                          color: Colors.black,
                          tooltip: 'Notificações',
                          onPressed: () {
                            // Navegação para tela de notificações
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, size: 25),
                          color: Colors.black,
                          tooltip: 'Configurações',
                          onPressed: _abrirEdicaoPerfil,
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, size: 25),
                          color: Colors.black,
                          tooltip: 'Sair',
                          onPressed: _sair,
                        ),
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


                  // Cards de quantidade
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

                  // Botao para mudar as solicitações
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

                  if(_tipoServico == true) ... [
                    Column(
                      children: [

                        if(_solicitacoes.isEmpty) ... [
                          const Text(
                              "Não há solicitação pendente",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                        ] else ...[
                        for(final solicitacao in _solicitacoes)

                          CardsSolicitacaopendenteprofissional(
                              nome: solicitacao['cliente_nome']?.toString() ?? 'Sem nome',
                              endereco: '${solicitacao['cliente_rua']?? ''}  ${solicitacao['cliente_complemento']?? ''} - ${solicitacao['cliente_bairro']?? ''} - ${solicitacao['cliente_cidade'] ?? ''}, ${solicitacao['cliente_uf'].toUpperCase()?? ''}',
                              dataSolicitacao: solicitacao['cliente_solicitacao_data_atual']?.toString() ?? '',
                              dataServico: solicitacao['cliente_solicitacao_data']?.toString() ?? '',
                              dias: int.tryParse(solicitacao['cliente_solicitacao_quantidade'].toString(),) ?? 0,
                              imagemUrl: solicitacao['cliente_imagem'] ?? '',

                          ),

                        ],

                      ],
                    )

                  ] else ... [


                  ],




                ],
              ),

            ),




          ),

        )
      ),

      bottomNavigationBar: Container(
        color: const Color(0xFFEFF6FF),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(44, 4, 44, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.assignment_outlined, size: 38),
                  color: const Color(0xFF424242),
                  tooltip: 'Histórico',
                  onPressed: () {},
                ),

                IconButton(
                  icon: const Icon(Icons.home, size: 38),
                  color: const Color(0xFF3B82F6),
                  tooltip: 'Início',
                  onPressed: () {
                    // Já está na Home.
                  },
                ),

                IconButton(
                  icon: const Icon(Icons.event_available, size: 38),
                  color: const Color(0xFF424242),
                  tooltip: 'Agendamentos',
                  onPressed: (){},
                ),
              ],
            ),
          ),
      ),

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