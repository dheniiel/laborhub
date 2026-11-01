class PessoaJuridica {

final int? pj_id;
final String pj_razaoSocial;
final String pj_nomeFantasia;
final String pj_dataFundacao;
final String pj_cnpj;
final String pj_tipo;
final int pj_usuarios_id;


const PessoaJuridica ({
    this.pj_id,
    required this.pj_razaoSocial,
    required this.pj_nomeFantasia,
    required this.pj_dataFundacao,
    required this.pj_cnpj,
    required this.pj_tipo,
    required this.pj_usuarios_id,

});

Map<String, Object?> toMap() {
    return {
        if(pj_id != null) 'pj_id' : pj_id,
        'pj_razaoSocial' : pj_razaoSocial,
        'pj_nomeFantasia' : pj_nomeFantasia,
        'pj_dataFundacao' : pj_dataFundacao,
        'pj_cnpj' : pj_cnpj,
        'pj_tipo' : pj_tipo,
        'pj_usuarios_id' : pj_usuarios_id,

    };

}

factory PessoaJuridica.fromMap(Map<String, Object?> map) {
  return PessoaJuridica(
    pj_id: map['pj_id'] as int?,
    pj_razaoSocial: map['pj_razaoSocial'] as String,
    pj_nomeFantasia: map['pj_nomeFantasia'] as String,
    pj_dataFundacao: map['pj_dataFundacao'] as String,
    pj_cnpj: map['pj_cnpj'] as String,
    pj_tipo: map['pj_tipo'] as String,
    pj_usuarios_id: map['pj_usuarios_id'] as int,

  );
}




}