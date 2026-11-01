import 'package:flutter/material.dart';

class Forms extends StatefulWidget {
  final TextEditingController controlador;
  final TextInputType tipagemValor;
  final String rotulo;
  final String? Function(String?)? validador;
  final bool ocultarTexto;
  final String? dica;

  const Forms({
    super.key,
    required this.controlador,
    required this.tipagemValor,
    required this.rotulo,
    this.validador,
    this.ocultarTexto = false,
    this.dica,
  });

  @override
  State<Forms> createState() => _FormsState();
}

class _FormsState extends State<Forms> {
  late bool _textoOculto;

  @override
  void initState() {
    super.initState();
    _textoOculto = widget.ocultarTexto;
  }

  void _alternarVisibilidade() {
    setState(() => _textoOculto = !_textoOculto);
  }

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
            widget.rotulo,
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
          controller: widget.controlador,
          keyboardType: widget.tipagemValor,
          validator: widget.validador,
          obscureText: _textoOculto,
          enableSuggestions: !widget.ocultarTexto,
          autocorrect: !widget.ocultarTexto,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          cursorColor: const Color(0xFF3B82F6),

          style: const TextStyle(
            fontSize: 15,
            fontFamily: 'Montserrat',
            color: Colors.black,
          ),

          decoration: InputDecoration(
            hintText: widget.dica,
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

            // Olho para exibir/ocultar (somente em campos com ocultarTexto)
            suffixIcon: widget.ocultarTexto
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
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 20,
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