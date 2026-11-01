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
}