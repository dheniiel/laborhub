import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'Telas/escolhaUsuario.dart';
import 'Telas/login.dart';
import 'Telas/enderecoTela.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_localizations/flutter_localizations.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final suportaFirebase = Platform.isAndroid || Platform.isIOS;

  if (suportaFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onMessage.listen((mensagem) {
      debugPrint('Push recebido: ${mensagem.notification?.title}');
    });
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
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: [
        Locale('pt', 'BR'),
        Locale('en'),
      ],
    );
  }

}