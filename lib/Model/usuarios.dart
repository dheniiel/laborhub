class Usuarios {

final int? usuarios_id;
final String usuarios_email;
final String usuarios_imagem;
final String? usuarios_telefone;
final String usuarios_senha_hash;
final bool usuarios_ativo;
final bool usuarios_is_admin;
final String? usuarios_reset_hash;
final DateTime? usuarios_expira_em;
final DateTime usuarios_criado_em;
final DateTime? usuarios_atualizado_em;
final DateTime? usuarios_deletado_em;



const Usuarios({
    this.usuarios_id,
    required this.usuarios_email,
    required this.usuarios_imagem,
    required this.usuarios_telefone,
    required this.usuarios_senha_hash,
    required this.usuarios_ativo,
    required this.usuarios_is_admin,
    this.usuarios_reset_hash,
    this.usuarios_expira_em,
    required this.usuarios_criado_em,
    this.usuarios_atualizado_em,
    this.usuarios_deletado_em,

});

Map<String, Object?> toMap() {
    return {
        if(usuarios_id != null) 'usuarios_id': usuarios_id,
            'usuarios_email': usuarios_email,
            'usuarios_imagem': usuarios_imagem,
            'usuarios_telefone': usuarios_telefone,
            'usuarios_senha_hash': usuarios_senha_hash,
            'usuarios_ativo': usuarios_ativo ? 1 : 0,
            'usuarios_is_admin': usuarios_is_admin ? 1 : 0,
            'usuarios_criado_em': usuarios_criado_em.toIso8601String(),

    };

}


factory Usuarios.fromMap(Map<String, Object?> map) {
  return Usuarios(
    usuarios_id: map['usuarios_id'] as int?,
    usuarios_email: map['usuarios_email'] as String,
    usuarios_imagem: map['usuarios_imagem'] as String,
    usuarios_telefone: map['usuarios_telefone'] as String?,
    usuarios_senha_hash: map['usuarios_senha_hash'] as String,
    usuarios_ativo: map['usuarios_ativo'] == 1,
    usuarios_is_admin: map['usuarios_is_admin'] == 1,
    usuarios_criado_em: DateTime.parse(
      map['usuarios_criado_em'] as String,
    ),
  );
}


}