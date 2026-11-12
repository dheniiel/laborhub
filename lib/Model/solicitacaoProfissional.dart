class SolicitacaoProfissional {
  final int? soliciticao_id;
  final DateTime solicitacao_data;
  final DateTime solicitacao_data_atual;
  final String solicitacao_status; // Finalizado, Pendente ou Recusado
  final int solicitacao_quantidade;
  final String solicitacao_observacao;
  final DateTime solicitacao_criada_em;
  final int solicitacao_endereco_id;
  final int solicitacao_usuarios_id;


  const SolicitacaoProfissional ({
    this.soliciticao_id,
    required this.solicitacao_data,
    required this.solicitacao_data_atual,
    required this.solicitacao_status,
    required this.solicitacao_quantidade,
    required this.solicitacao_observacao,
    required this.solicitacao_criada_em,
    required this.solicitacao_endereco_id,
    required this.solicitacao_usuarios_id,

  });

  Map<String, Object?> toMap() {
    return {
      if(soliciticao_id != null) 'soliciticao_id' : soliciticao_id,
      'solicitacao_data' : solicitacao_data,
      'solicitacao_data_atual' : solicitacao_data_atual,
      'solicitacao_status' : solicitacao_status,
      'solicitacao_quantidade' : solicitacao_quantidade,
      'solicitacao_observacao' : solicitacao_observacao,
      'solicitacao_criada_em' : solicitacao_criada_em,
      'solicitacao_endereco_id' : solicitacao_endereco_id,
      'solicitacao_usuarios_id' : solicitacao_usuarios_id,

    };

  }
}