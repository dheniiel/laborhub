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

  // Fecha a conexão (usado nos testes).
  Future<void> fechar() async {
    await _db?.close();
    _db = null;
  }

  Future<Database> _abrir() async {
    final dir = await getDatabasesPath();
    final caminho = p.join(dir, 'laborHUb.db');

    return openDatabase(
      caminho,
      version: 3,

      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },

      onCreate: (db, version) => _criarTabelas(db),

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // As versões 1 e 2 guardavam perfis criados só no aparelho, sem vínculo com o MySQL.
          // A partir da versão 3 o SQLite é a cópia offline dos dados da API: recria as tabelas.
          for (final tabela in ['endereco', 'pessoaFisica', 'pessoaJuridica', 'servicos', 'usuarios']) {
            await db.execute('DROP TABLE IF EXISTS $tabela');
          }
          await _criarTabelas(db);
        }
      },
    );
  }

  // Mesmas colunas do MySQL (database/init/01-laborhub.sql). Os ids são os do servidor.
  Future<void> _criarTabelas(Database db) async {
    await db.execute('''
      CREATE TABLE usuarios (
        usuarios_id INTEGER PRIMARY KEY,
        usuarios_email TEXT NOT NULL,
        usuarios_imagem TEXT,
        usuarios_telefone TEXT,
        usuarios_senha_hash TEXT,
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
        pf_id INTEGER PRIMARY KEY,
        pf_nome TEXT,
        pf_sobrenome TEXT,
        pf_dataNascimento TEXT,
        pf_genero TEXT,
        pf_cpf TEXT,
        pf_tipo TEXT,
        pf_usuarios_id INTEGER,
        FOREIGN KEY (pf_usuarios_id) REFERENCES usuarios(usuarios_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pessoaJuridica (
        pj_id INTEGER PRIMARY KEY,
        pj_razaoSocial TEXT,
        pj_nomeFantasia TEXT,
        pj_dataFundacao TEXT,
        pj_cnpj TEXT,
        pj_tipo TEXT,
        pj_usuarios_id INTEGER,
        FOREIGN KEY (pj_usuarios_id) REFERENCES usuarios(usuarios_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE endereco (
        endereco_id INTEGER PRIMARY KEY,
        endereco_nome TEXT,
        endereco_rua TEXT,
        endereco_bairro TEXT,
        endereco_cep TEXT,
        endereco_complemento TEXT,
        endereco_numero TEXT,
        endereco_descricao TEXT,
        endereco_cidade TEXT,
        endereco_uf TEXT,
        endereco_usuarios_id INTEGER,
        FOREIGN KEY (endereco_usuarios_id) REFERENCES usuarios(usuarios_id)
      )
    ''');

    // Usada pelo ServicosDAO. Sem vínculo com a sessão: não é apagada no logout.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS servicos (
        servicos_id INTEGER PRIMARY KEY AUTOINCREMENT,
        servicos_nome TEXT,
        servicos_data TEXT,
        servicos_valor REAL,
        servicos_tipo_cobranca TEXT,
        servicos_nivel_experiencia TEXT,
        servicos_descricao TEXT,
        servicos_usuarios_id INTEGER
      )
    ''');

    // Uma única sessão por aparelho (sessao_id sempre 1).
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessao (
        sessao_id INTEGER PRIMARY KEY CHECK (sessao_id = 1),
        sessao_token TEXT NOT NULL,
        sessao_tipo TEXT,
        sessao_expira_em TEXT NOT NULL,
        sessao_usuarios_id INTEGER NOT NULL,
        FOREIGN KEY (sessao_usuarios_id) REFERENCES usuarios(usuarios_id)
      )
    ''');
  }
}