import 'package:sqflite/sqflite.dart';
import '../Model/pessoaFisica.dart';
import 'app_database.dart';

class PessoaFisicaDao {
    Future<Database> get _db async =>
        await AppDatabase.instance.database;

    Future<int> inserir(PessoaFisica pf) async {
        final db = await _db;
        return db.insert('pessoaJuridica', pf.toMap());
    }
}