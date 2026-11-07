import 'package:sqflite/sqflite.dart';
import '../Model/pessoJuridica.dart';
import 'app_database.dart';

class PessoajuridicaDao {
    Future<Database> get _db async =>
        await AppDatabase.instance.database;

    Future<int> inserir(PessoaJuridica pj) async {
        final db = await _db;
        return db.insert('pessoaJuridica', pj.toMap());
    }

    Future<PessoaJuridica?> buscarPorUsuario(int usuarioId) async {
        final db = await _db;
        final resultado = await db.query(
            'pessoaJuridica',
            where: 'pj_usuarios_id = ?',
            whereArgs: [usuarioId],
            limit: 1,
        );

        if (resultado.isEmpty) return null;
        return PessoaJuridica.fromMap(resultado.first);
    }
}