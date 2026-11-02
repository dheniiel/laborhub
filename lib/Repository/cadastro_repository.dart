import '../Data/app_database.dart';

class CadastroRepository {
  Future<int> cadastrar({
    required Map<String, Object?> usuario,
    required Map<String, Object?> endereco,
    Map<String, Object?>? pessoaFisica,
    Map<String, Object?>? pessoaJuridica,
  }) async {
    // Exige exatamente um tipo de pessoa.
    if ((pessoaFisica == null) == (pessoaJuridica == null)) {
      throw ArgumentError(
        'Informe pessoa física ou pessoa jurídica, apenas uma.',
      );
    }

    final db = await AppDatabase.instance.database;

    return db.transaction((txn) async {
      final dadosUsuario = Map<String, Object?>.from(usuario)
        ..remove('usuarios_id');

      final usuarioId = await txn.insert(
        'usuarios',
        dadosUsuario,
      );

      if (pessoaFisica != null) {
        final dadosPF = Map<String, Object?>.from(pessoaFisica)
          ..remove('pf_id')
          ..['pf_usuarios_id'] = usuarioId;

        await txn.insert('pessoaFisica', dadosPF);
      } else {
        final dadosPJ = Map<String, Object?>.from(pessoaJuridica!)
          ..remove('pj_id')
          ..['pj_usuarios_id'] = usuarioId;

        await txn.insert('pessoaJuridica', dadosPJ);
      }

      final dadosEndereco = Map<String, Object?>.from(endereco)
        ..remove('endereco_id')
        ..['endereco_usuarios_id'] = usuarioId;

      await txn.insert('endereco', dadosEndereco);

      return usuarioId;
    });
  }
}