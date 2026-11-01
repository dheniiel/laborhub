import 'package:flutter/material.dart';
import 'Telas/escolhaUsuario.dart';


void main() {
  runApp(const LaborHUBapp());

}

class LaborHUBapp extends StatelessWidget {
    const LaborHUBapp({super.key});


   @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EscolhaUsuario(),
    );
  }

}