import 'package:sqflite/sqflite.dart';
import '../Model/usuarios.dart';
import 'app_database.dart';

class UsuariosDao {
    Future<Database> get _db async => await AppDatabase.instance.database;

    //create
    Future<int> inserir(Usuarios usuarios) async {
        final db = await _db;
        return db.insert('usuarios', usuarios.toMap);

    }




}