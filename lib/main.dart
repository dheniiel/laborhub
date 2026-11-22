import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'Telas/escolhaUsuario.dart';
import 'Telas/login.dart';
import 'Telas/enderecoTela.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // try {
  //   final token = await FirebaseMessaging.instance.getToken();
  //   debugPrint('FCM token: $token');
  // } catch (erro) {
  //   debugPrint('Erro ao obter token FCM: $erro');
  // }
  FirebaseMessaging.onMessage.listen((mensagem) {
    debugPrint('Push recebido: ${mensagem.notification?.title}');
  });

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