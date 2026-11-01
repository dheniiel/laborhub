class Endereco {

final int? endereco_id;
final String endereco_nome;
final String endereco_rua;
final String endereco_bairro;
final String endereco_cep;
final String endereco_complemento;
final String endereco_numero;
final String? endereco_descricao;
final String endereco_cidade;
final String endereco_uf;
final int endereco_usuarios_id;


const Endereco({
    this.endereco_id,
    required this.endereco_nome,
    required this.endereco_rua,
    required this.endereco_bairro,
    required this.endereco_cep,
    required this.endereco_complemento,
    required this.endereco_numero,
    this.endereco_descricao,
    required this.endereco_cidade,
    required this.endereco_uf,
    required this.endereco_usuarios_id,

});

Map<String, Object?> toMap() {
    return {
        if(endereco_id != null) 'endereco_id' : endereco_id,
        'endereco_nome': endereco_nome,
        'endereco_rua' : endereco_nome,
        'endereco_bairro' : endereco_bairro,
        'endereco_cep' : endereco_cep,
        'endereco_complemento' : endereco_complemento,
        'endereco_numero' : endereco_numero,
        'endereco_descricao' : endereco_descricao,
        'endereco_cidade' : endereco_cidade,
        'endereco_uf' : endereco_uf,
        'endereco_usuarios_id' : endereco_usuarios_id


    };


}


factory Endereco.fromMap(Map<String, Object?> map) {
    return Endereco (
        endereco_id : map['endereco_id'] as int?,
        endereco_nome : map['endereco_nome'] as String,
        endereco_rua : map['endereco_rua'] as String,
        endereco_bairro : map['endereco_bairro'] as String,
        endereco_cep : map['endereco_cep'] as String,
        endereco_complemento : map['endereco_complemento'] as String,
        endereco_numero : map['endereco_numero'] as String,
        endereco_cidade : map['endereco_cidade'] as String,
        endereco_uf: map['endereco_uf'] as String,
        endereco_usuarios_id : map['endereco_usuarios_id'] as int,

    );


}

}