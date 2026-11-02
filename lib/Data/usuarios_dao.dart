import 'package:sqflite/sqflite.dart';
import '../Model/usuarios.dart';
import 'app_database.dart';

class UsuariosDao {
    Future<Database> get _db async =>
        await AppDatabase.instance.database;

    Future<int> inserir(Usuarios usuarios) async {
        final db = await _db;
        return db.insert('usuarios', usuarios.toMap());
    }
    
    Future<Usuarios?> buscarPorEmail(String email) async {
        final db = await _db;
        final resultado = await db.query(
            'usuarios',
            where: 'usuarios_email = ? AND usuarios_deletado_em IS NULL',
            whereArgs: [email],
            limit: 1,
        );

        if (resultado.isEmpty) return null;
        return Usuarios.fromMap(resultado.first);
    }
}