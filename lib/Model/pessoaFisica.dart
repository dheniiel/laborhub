class PessoaFisica {

final int? pf_id;
final String pf_nome;
final String pf_sobrenome;
final Date pf_dataNascimento;
final String pf_genero;
final String pf_tipo;
final int pf_usuarios_id; // chave estrangeira de usuarios

const PessoaFisica({
    this.id,
    required this.pf_nome,
    required this.pf_sobrenome,
    required this.pf_dataNascimento,
    required this.pf_genero,
    required this.pf_tipo,
    required this.pf_usuarios_id

})


Map<String, Object?> toMap() {
    return {
        if(pf_id != null) 'pf_id': pf_id,
        'pf_nome' : pf_nome,
        'pf_sobrenome' : pf_sobrenome,
        'pf_dataNascimento' : pf_dataNascimento,
        'pf_genero' : pf_genero,
        'pf_tipo' : pf_tipo,
        'pf_usuarios_id': pf_usuarios_id
    }
}


factory PessoaFisica.fromMap(Map<String, Object?> map) {
  return PessoaFisica(
    'pf_id': map['pf_id'] as int?,
    'pf_nome' : map['pf_nome'] as String,
    'pf_sobrenome' : map['pf_sobrenome'] as String,
    'pf_dataNascimento' : map['pf_dataNascimento'] as Date,
    'pf_genero' : map['pf_genero'] as String,
    'pf_tipo' : map['pf_tipo'] as String,
    'pf_usuarios_id' : map['pf_usuarios_id'] as int

  );
}


}