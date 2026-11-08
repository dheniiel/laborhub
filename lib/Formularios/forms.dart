import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class Forms extends StatefulWidget {

  final TextEditingController? controlador;

  final TextInputType? tipagemValor;
  final String rotulo;
  final String? Function(String?)? validador;
  final List<TextInputFormatter>? formatadores;
  final bool ocultarTexto;
  final int maxLinha;
  final IconData? icone;

  final List<String>? opcao;
  final ValueChanged<String?>? onChanged;
  final String? valorInicial;


  const Forms({
    super.key,
    required this.controlador,
    required this.tipagemValor,
    required this.rotulo,
    this.validador,
    this.formatadores,
    this.ocultarTexto = false,
    this.maxLinha = 1,
    this.icone,
  }) : opcao = null, onChanged = null, valorInicial = null;


  const Forms.select({
    super.key,
    required this.rotulo,
    required this.opcao,
    required this.onChanged,
    this.validador,
    this.valorInicial,
  }) : controlador = null,
        tipagemValor = null,
        formatadores = null,
        ocultarTexto = false,
        maxLinha = 1,
        icone = null;


  @override
  State<Forms> createState() => _FormsState();

}


class _FormsState extends State<Forms> {

  late bool _textoOculto;

  static const _estiloTexto = TextStyle(
    fontSize: 15,
    fontFamily: 'Montserrat',
    color: Colors.black,
  );

  static const _bordaCampo = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
    borderSide: BorderSide(color: Color(0xFF7F7F7F)),
  );

  static const _bordaFoco = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
    borderSide: BorderSide(color: Color(0xFF3B82F6)),
  );

  static const _bordaErro = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
    borderSide: BorderSide(color: Colors.red),
  );


  @override
  void initState() {
    super.initState();
    _textoOculto = widget.ocultarTexto;
  }


  void _alternarVisibilidade() {
    setState(() => _textoOculto = !_textoOculto);
  }


  InputDecoration _decoracao({Widget? sufixo}) {
    return InputDecoration(
      hintText: widget.rotulo,
      hintStyle: const TextStyle(
        fontSize: 15,
        fontFamily: 'Montserrat',
        color: Color(0xFFA6A6A6),
      ),

      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 11,
      ),

      suffixIcon: sufixo,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 20,
      ),

      filled: true,
      fillColor: const Color(0xFFF4F4F4),

      border: _bordaCampo,
      enabledBorder: _bordaCampo,
      focusedBorder: _bordaFoco,
      errorBorder: _bordaErro,
      focusedErrorBorder: _bordaErro,

      errorStyle: const TextStyle(
        fontSize: 12,
        fontFamily: 'Montserrat',
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    if (widget.opcao != null) {
      return DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: _decoracao(),
        style: _estiloTexto,
        items: widget.opcao!.map((opcoes) {
          return DropdownMenuItem<String>(
            value: opcoes,
            child: Text(opcoes),
          );
        }).toList(),
        onChanged: widget.onChanged,
        validator: widget.validador,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        initialValue: widget.valorInicial,
      );
    }


    return TextFormField(
      controller: widget.controlador,
      keyboardType: widget.tipagemValor,
      minLines: widget.ocultarTexto ? 1 : widget.maxLinha,
      maxLines: widget.ocultarTexto ? 1 : widget.maxLinha,
      inputFormatters: widget.formatadores,
      validator: widget.validador,
      obscureText: _textoOculto,
      autocorrect: !widget.ocultarTexto,
      enableSuggestions: !widget.ocultarTexto,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      cursorColor: const Color(0xFF3B82F6),
      style: _estiloTexto,
      decoration: _decoracao(
        // Olho para exibir/ocultar (somente em campos com ocultarTexto)
        sufixo: widget.ocultarTexto
            ? InkWell(
                onTap: _alternarVisibilidade,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    _textoOculto
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: const Color(0xFF7F7F7F),
                    semanticLabel:
                        _textoOculto ? 'Exibir senha' : 'Ocultar senha',
                  ),
                ),
              )
            : widget.icone != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(widget.icone, size: 22, color: Colors.black),
                  )
                : null,
      ),
    );

  }

}