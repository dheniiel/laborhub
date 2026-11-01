import 'package:sqflite/sqflite.dart';
import '../Model/pessoaJuridica.dart';
import 'app_database.dart';

class PessoaJuridicaDao {
    Future<Database> get _db async => await AppDatabase.instance.database;

    //create
    Future<int> inserir(PessoaJuridica pj) async {
        final db = await _db;
        return db.insert('pessoaJuridica', pj.toMap();

    }




}