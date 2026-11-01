import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:laborhub/Formularios/forms.dart';

import '../Model/pessoaFisica.dart';
import '../Model/pessoJuridica.dart';
import '../Model/usuarios.dart';
import '../Repository/pessoaFisica_repository.dart';
import '../Repository/pessoaJuridica_Repository.dart';
import '../Repository/usuarios_repository.dart';

class Cliente extends StatefulWidget {
  const Cliente({super.key});

  @override
  State<Cliente> createState() => _ClienteTelas();
}

class _ClienteTelas() extends State<Cliente> {
  Uint8List? _foto; //para foto de perfil
  bool _pessoaFisica = true; // para mudar o botao ao escolher o tipo de usuario

  Future<void> _selecionarFoto() async {
    try {
      final arquivo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (arquivo == null) {
        return;
      }

      final bytes = await arquivo.readAsBytes();

      if (!mounted) return;

      setState(() {
        _foto = bytes;
      });
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível abrir a imagem.")),
      );
    }
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  // const Spacer(flex: 2),
                  const SizedBox(height: 30),
                  const Text(
                    'Foto de perfil',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: Color.fromARGB(1000, 59, 130, 246),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: _foto != null
                              ? MemoryImage(_foto!)
                              : null,
                          child: _foto == null
                              ? Icon(
                                  Icons.person,
                                  size: 100,
                                  color: Color.fromARGB(1000, 59, 130, 246),
                                )
                              : null,
                        ),
                      ),

                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filled(
                          onPressed: _selecionarFoto,
                          icon: const Icon(Icons.edit),
                          tooltip: 'Alterar foto',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),

                  // Botoes
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      //   Pessoa fisica
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _pessoaFisica = true;
                            });
                          },

                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0,40),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            backgroundColor: _pessoaFisica
                                ? Color.fromARGB(1000, 59, 130, 246)
                                : Colors.white,
                            foregroundColor: _pessoaFisica
                                ? Colors.white
                                : Colors.black,
                            side: const BorderSide(color: Color.fromARGB(1000, 59, 130, 246)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),

                            )
                          ),
                          child: const Text("Pessoa Física"),
                        ),
                      ),

                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _pessoaFisica = false;
                            });
                          },

                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0,40),
                              backgroundColor: !_pessoaFisica
                                  ? Color.fromARGB(1000, 59, 130, 246)
                                  : Colors.white,
                              foregroundColor: !_pessoaFisica
                                  ? Colors.white
                                  : Colors.black,
                              side: const BorderSide(color: Color.fromARGB(1000, 59, 130, 246)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),

                              )
                          ),
                          child: const Text("Pessoa Jurídica"),
                        ),
                      ),

                    ],
                  ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      Forms(
                          controlador: usuarios_id,
                          tipagemValor: tipagemValor,
                          rotulo: rotulo)

                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
