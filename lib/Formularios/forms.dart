
import 'package:flutter/material.dart';

class Forms extends StatelessWidget {
  final TextEditingController controlador;
  final TextInputType tipagemValor;
  final String rotulo;
  final String? Function(String?)? validador;
  final bool ocultarTexto;

  const Forms({
    super.key,
    required this.controlador,
    required this.tipagemValor,
    required this.rotulo,
    this.validador,
    this.ocultarTexto = false,
  });

  @override
  Widget build(BuildContext context) {
    const bordaCampo = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFF7F7F7F)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            rotulo,
            style: const TextStyle(
              fontSize: 15,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),

        const SizedBox(height: 4),

        TextFormField(
          controller: controlador,
          keyboardType: tipagemValor,
          validator: validador,
          obscureText: ocultarTexto,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          cursorColor: const Color(0xFF3B82F6),

          style: const TextStyle(
            fontSize: 15,
            fontFamily: 'Montserrat',
            color: Colors.black,
          ),

          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 11,
            ),

            filled: true,
            fillColor: const Color(0xFFF4F4F4),

            border: bordaCampo,
            enabledBorder: bordaCampo,

            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                color: Color(0xFF3B82F6),
              ),
            ),

            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(color: Colors.red),
            ),

            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(color: Colors.red),
            ),

            errorStyle: const TextStyle(
              fontSize: 12,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
      ],
    );
  }
}
