import 'package:flutter/material.dart';


class Forms extends StatelessWidget {

  final TextEditingController controlador;
  final TextInputType tipagemValor;
  final String rotulo;
  final String? Function(String?)? validador;


  const Forms({
    super.key,
    required this.controlador,
    required this.tipagemValor,
    required this.rotulo,
    this.validador,
  });


  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return TextFormField(
      controller: controlador,
      keyboardType: tipagemValor,
      validator: validador,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: rotulo,
        border: const OutlineInputBorder(),
          fillColor: Color(0xFFE8F5E9),
      ),
    );

  }


}