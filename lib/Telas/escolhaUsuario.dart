import 'package:flutter/material.dart';
import 'package:laborhub/Telas/cliente.dart';



class EscolhaUsuario  extends StatefulWidget {
  const EscolhaUsuario({super.key});

  @override
  State<EscolhaUsuario> createState() => _EscolhaUsuarioState();



}

class _EscolhaUsuarioState extends State<EscolhaUsuario> {

  // @override {
  //   void initeState((){
  //     super.initState();
  // });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
          onPressed: (){
            Navigator.pop(context);
          },
        ),
      ),

      body: SafeArea(
        child: Center (
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),


              const Text(
                'Escolha seu perfil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 90),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _OpcaoUsuario(
                      titulo: 'Cliente',
                      imagem: 'lib/Assets/Images/cliente.png',
                      onTap:() {
                        //Navegação para tela de cadastro de cliente
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: ((context) => const Cliente())));
                      },
                    ),
                  ),

                  const SizedBox(width: 32),

                  Expanded(
                    child: _OpcaoUsuario(
                      titulo: "Profissional",
                      imagem: 'lib/Assets/Images/profissional.png',
                      onTap: () {
                        //     Navegação para tela de profissional
                      },
                    ),

                  ),
                ],
              ),


              const Spacer(flex: 3),

              const Text(
                'Direito reservado 2026',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
        )
        ),
      ),

    );
  }
}

class _OpcaoUsuario extends StatelessWidget {

  final String titulo;
  final String imagem;
  final VoidCallback onTap;


  const _OpcaoUsuario({
    required this.titulo,
    required this.imagem,
    required this.onTap,
});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
              side: const BorderSide(color: Colors.grey),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Image.asset(
                imagem,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              )
            ),
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }




}




