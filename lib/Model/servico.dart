class Servico {

  final int? servicos_id;
  final String servicos_nome;
  final String servicos_data;
  final double servicos_valor;
  final String servicos_tipo_cobranca;
  final String servicos_nivel_experiencia;
  final String servicos_descricao;
  final int servicos_usuarios_id;


  const Servico ({
    this.servicos_id,
    required this.servicos_nome,
    required this.servicos_data,
    required this.servicos_valor,
    required this.servicos_tipo_cobranca,
    required this.servicos_nivel_experiencia,
    required this.servicos_descricao,
    required this.servicos_usuarios_id,

  });

  Map<String, Object?> toMap() {
    return {
      if(servicos_id != null) 'servicos_id' : servicos_id,
      'servicos_nome' : servicos_nome,
      'servicos_data' : servicos_data,
      'servicos_valor' : servicos_valor,
      'servicos_tipo_cobranca' : servicos_tipo_cobranca,
      'servicos_nivel_experiencia' : servicos_nivel_experiencia,
      'servicos_descricao' : servicos_descricao,
      'servicos_usuarios_id' : servicos_usuarios_id,

    };

  }

  factory Servico.fromMap(Map<String, Object?> map) {
    return Servico(
      servicos_id: map['servicos_id'] as int?,
      servicos_nome: map['servicos_nome'] as String,
      servicos_data: map['servicos_data'] as String,
      servicos_valor: map['servicos_valor'] as double,
      servicos_tipo_cobranca: map['servicos_tipo_cobranca'] as String,
      servicos_nivel_experiencia: map['servicos_nivel_experiencia'] as String,
      servicos_descricao: map['servicos_descricao'] as String,
      servicos_usuarios_id: map['servicos_usuarios_id'] as int,

    );
  }




}