import 'package:sqflite/sqflite.dart';
import '../Model/endereco.dart';
import 'app_database.dart';

class EnderecoDao {
    Future<Database> get _db async => await AppDatabase.instance.database;

    //create
    Future<int> inserir(Endereco endereco) async {
        final db = await _db;
        return db.insert('endereco', endereco.toMap();

    }




}