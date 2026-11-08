import 'package:sqflite/sqflite.dart';
import '../Model/sessao.dart';
import '../Model/usuarios.dart';
import 'app_database.dart';

class SessaoDao {
    Future<Database> get _db async =>
        await AppDatabase.instance.database;

    // Substitui a cópia local pelos dados retornados pela API (login ou renovação da sessão).
    Future<void> salvar(String token, Map<String, dynamic> dados) async {
        final db = await _db;
        final usuario = Usuarios.fromMap(dados);

        await db.transaction((txn) async {
            await _apagar(txn);
            await txn.insert('usuarios', usuario.toMap());

            final pf = dados['pessoaFisica'];
            if (pf is Map) await txn.insert('pessoaFisica', Map<String, Object?>.from(pf));

            final pj = dados['pessoaJuridica'];
            if (pj is Map) await txn.insert('pessoaJuridica', Map<String, Object?>.from(pj));

            for (final endereco in (dados['enderecos'] as List? ?? const [])) {
                await txn.insert('endereco', Map<String, Object?>.from(endereco as Map));
            }

            await txn.insert('sessao', {
                'sessao_id': 1,
                'sessao_token': token,
                'sessao_tipo': dados['tipo'] as String?,
                'sessao_expira_em': dados['sessao_expira_em'] as String,
                'sessao_usuarios_id': usuario.usuarios_id,
            });
        });
    }

    Future<Sessao?> buscar() async {
        final db = await _db;
        final resultado = await db.rawQuery(
            'SELECT * FROM sessao JOIN usuarios ON usuarios_id = sessao_usuarios_id LIMIT 1',
        );

        if (resultado.isEmpty) return null;
        final linha = resultado.first;
        return Sessao(
            token: linha['sessao_token'] as String,
            tipo: linha['sessao_tipo'] as String?,
            expiraEm: DateTime.parse(linha['sessao_expira_em'] as String),
            usuario: Usuarios.fromMap(linha),
        );
    }

        // Perfil (PF ou PJ) e endereço principal guardados no login. Usado na edição de perfil.
    Future<Map<String, Object?>> buscarPerfil() async {
        final db = await _db;
        final pf = await db.query('pessoaFisica', limit: 1);
        final pj = await db.query('pessoaJuridica', limit: 1);
        final endereco = await db.query('endereco', orderBy: 'endereco_id', limit: 1);

        return {
            'pessoaFisica': pf.isEmpty ? null : pf.first,
            'pessoaJuridica': pj.isEmpty ? null : pj.first,
            'endereco': endereco.isEmpty ? null : endereco.first,
        };
    }

    // Logout ou sessão inválida: remove a sessão e os dados do usuário do aparelho.
    Future<void> limpar() async {
        final db = await _db;
        await db.transaction(_apagar);
    }

    Future<void> _apagar(Transaction txn) async {
        for (final tabela in ['sessao', 'endereco', 'pessoaFisica', 'pessoaJuridica', 'usuarios']) {
            await txn.delete(tabela);
        }
    }
}
