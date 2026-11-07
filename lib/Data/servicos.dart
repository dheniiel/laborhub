import 'package:sqflite/sqflite.dart';
import '../Model/servico.dart';
import 'app_database.dart';

class ServicosDAO {
  Future<Database> get _db async =>
      await AppDatabase.instance.database;

  Future<int> inserir(Servico servicos) async {
    final db = await _db;
    return db.insert('servicos', servicos.toMap());
  }

}