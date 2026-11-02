import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _abrir();
    return _db!;
  }

  Future<Database> _abrir() async {
    final dir = await getDatabasesPath();
    final caminho = p.join(dir, 'laborHUb.db');

    return openDatabase(
      caminho,
      version: 1,

      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },

      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios (
            usuarios_id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuarios_email TEXT NOT NULL,
            usuarios_imagem TEXT,
            usuarios_telefone TEXT,
            usuarios_senha_hash TEXT NOT NULL,
            usuarios_ativo INTEGER,
            usuarios_is_admin INTEGER,
            usuarios_reset_hash TEXT,
            usuarios_expira_em TEXT,
            usuarios_ativacao_hash TEXT,
            usuarios_criado_em TEXT,
            usuarios_atualizado_em TEXT,
            usuarios_deletado_em TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE pessoaFisica (
            pf_id INTEGER PRIMARY KEY AUTOINCREMENT,
            pf_nome TEXT NOT NULL,
            pf_sobrenome TEXT NOT NULL,
            pf_dataNascimento TEXT,
            pf_genero TEXT,
            pf_cpf TEXT,
            pf_tipo TEXT,
            pf_usuarios_id INTEGER,pf_usuarios_id INTEGER,
            FOREIGN KEY (pf_usuarios_id) REFERENCES usuarios(usuarios_id)
            
            
          )
        ''');

        await db.execute('''
          CREATE TABLE pessoaJuridica (
            pj_id INTEGER PRIMARY KEY AUTOINCREMENT,
            pj_razaoSocial TEXT NOT NULL,
            pj_nomeFantasia TEXT NOT NULL,
            pj_dataFundacao TEXT,
            pj_cnpj TEXT NOT NULL,
            pj_tipo TEXT NOT NULL,
            pj_usuarios_id INTEGER
            FOREIGN KEY (pj_usuarios_id) REFERENCES usuarios(usuarios_id)
            
          )
        ''');

        await db.execute('''
          CREATE TABLE endereco.dart (
            endereco_id INTEGER PRIMARY KEY AUTOINCREMENT,
            endereco_nome TEXT NOT NULL,
            endereco_rua TEXT NOT NULL,
            endereco_bairro TEXT,
            endereco_cep TEXT NOT NULL,
            endereco_complemento TEXT,
            endereco_numero TEXT NOT NULL,
            endereco_descricao TEXT,
            endereco_cidade TEXT NOT NULL,
            endereco_uf TEXT NOT NULL,
            endereco_usuarios_id INTEGER
            FOREIGN KEY (endereco_usuarios_id) REFERENCES usuarios(usuarios_id)
          )
        ''');
      },
    );
  }
}