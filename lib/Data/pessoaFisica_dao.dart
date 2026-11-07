import 'package:sqflite/sqflite.dart';
import '../Model/pessoaFisica.dart';
import 'app_database.dart';

class PessoaFisicaDao {
    Future<Database> get _db async =>
        await AppDatabase.instance.database;

    Future<int> inserir(PessoaFisica pf) async {
        final db = await _db;
        return db.insert('pessoaFisica', pf.toMap());
    }

    Future<PessoaFisica?> buscarPorUsuario(int usuarioId) async {
        final db = await _db;
        final resultado = await db.query(
            'pessoaFisica',
            where: 'pf_usuarios_id = ?',
            whereArgs: [usuarioId],
            limit: 1,
        );

        if (resultado.isEmpty) return null;
        return PessoaFisica.fromMap(resultado.first);
    }
}