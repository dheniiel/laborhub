import 'package:flutter/material.dart';
import 'Telas/escolhaUsuario.dart';
import 'Telas/login.dart';
import 'Telas/enderecoTela.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const LaborHUBapp());

}

class LaborHUBapp extends StatelessWidget {
    const LaborHUBapp({super.key});


   @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Login(),
    );
  }

}