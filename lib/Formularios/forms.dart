import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class Forms extends StatelessWidget {

  final TextEditingController? controlador;

  final TextInputType? tipagemValor;
  final String rotulo;
  final String? Function(String?)? validador;
  final List<TextInputFormatter>? formatadores;
  final bool ocultarTexto;

  final List<String>? opcao;
  final ValueChanged<String?>? onChanged;


  const Forms({
    super.key,
    required this.controlador,
    required this.tipagemValor,
    required this.rotulo,
    this.validador,
    this.formatadores,
    this.ocultarTexto = false,
  }) : opcao = null, onChanged = null;


  const Forms.select({
    super.key,
    required this.rotulo,
    required this.opcao,
    required this.onChanged,
    this.validador,
  }) : controlador = null,
        tipagemValor = null,
        formatadores = null,
        ocultarTexto = false;



  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    final decoration = InputDecoration(
      hintText: rotulo,
      border: const OutlineInputBorder(),
    );

    if (opcao != null) {
      return DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: decoration,
        items: opcao!.map((opcoes) {
          return DropdownMenuItem<String>(
            value: opcoes,
            child: Text(opcoes),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validador,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      );
    }


    return TextFormField(
      controller: controlador,
      keyboardType: tipagemValor,
      inputFormatters: formatadores,
      validator: validador,
      obscureText: ocultarTexto,
      autocorrect: !ocultarTexto,
      enableSuggestions: !ocultarTexto,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: rotulo,
        border: const OutlineInputBorder(),
          fillColor: Color.fromARGB(1000, 59, 130, 246),
      ),
    );

  }





}