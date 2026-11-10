import 'auth_api.dart';

class CadastroRepository {
  final AuthApi _api;
  CadastroRepository({AuthApi? api}) : _api = api ?? AuthApi();

  Future<int>  cadastrar({
    required String senha,
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

    // A API grava usuário, perfil e endereço no MySQL em uma única transação
    // e preenche as chaves estrangeiras. Ids e hashes locais não são enviados:
    // a senha digitada vai separada e somente o servidor gera o hash.
    Map<String, Object?> semChaves(Map<String, Object?> dados, List<String> chaves) =>
        Map<String, Object?>.from(dados)..removeWhere((chave, _) => chaves.contains(chave));

    final body = await _api.post('auth/register', {
      'email': usuario['usuarios_email'] as String,
      'password': senha,
      'usuario': semChaves(usuario, ['usuarios_id', 'usuarios_senha_hash']),
      'endereco': semChaves(endereco, ['endereco_id', 'endereco_usuarios_id']),
      if (pessoaFisica != null)
        'pessoaFisica': semChaves(pessoaFisica, ['pf_id', 'pf_usuarios_id']),
      if (pessoaJuridica != null)
        'pessoaJuridica': semChaves(pessoaJuridica, ['pj_id', 'pj_usuarios_id']),
    });

    return body['usuarios_id'] as int;
  }
}
