import 'package:flutter/material.dart';



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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),


              const Text(
                'Escolha seu usuário',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight(400),
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
                      icone: Icons.person_outline,
                      onTap:() {
                        //Navegação para tela de cadastro de cliente
                      },
                    ),
                  ),

                  const SizedBox(width: 32),

                  Expanded(
                    child: _OpcaoUsuario(
                      titulo: "Profissional",
                      icone: Icons.business_center_sharp,
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
        
      ),

    );
  }
}

class _OpcaoUsuario extends StatelessWidget {

  final String titulo;
  final IconData icone;
  final VoidCallback onTap;


  const _OpcaoUsuario({
    required this.titulo,
    required this.icone,
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
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: Colors.grey),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Icon(
                icone,
                size: 80,
                color: const Color(0xFF226477),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF387FFC),
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




