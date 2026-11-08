class Solicitacao {

  final int solicitacao_id;
  final DateTime solicitacao_data;
  final DateTime? solicitacao_conclusao;
  final String solicitacao_status; // Finalizado, Pendente ou Recusado
  final String? solicitacao_motivo;
  final String? solicitacao_observacao;
  final double servicos_valor;

  // Dados do profissional exibidos no card.
  final String profissional_nome;
  final String profissional_profissao;
  final String profissional_imagem;

  const Solicitacao({
    required this.solicitacao_id,
    required this.solicitacao_data,
    this.solicitacao_conclusao,
    required this.solicitacao_status,
    this.solicitacao_motivo,
    this.solicitacao_observacao,
    required this.servicos_valor,
    required this.profissional_nome,
    required this.profissional_profissao,
    required this.profissional_imagem,
  });

  factory Solicitacao.fromMap(Map<String, Object?> map) {
    final conclusao = map['solicitacao_conclusao'] as String?;

    return Solicitacao(
      solicitacao_id: map['solicitacao_id'] as int,
      solicitacao_data: DateTime.parse(map['solicitacao_data'] as String),
      solicitacao_conclusao: conclusao == null ? null : DateTime.parse(conclusao),
      solicitacao_status: map['solicitacao_status'] as String,
      solicitacao_motivo: map['solicitacao_motivo'] as String?,
      solicitacao_observacao: map['solicitacao_observacao'] as String?,
      servicos_valor: (map['servicos_valor'] as num).toDouble(),
      profissional_nome: map['profissional_nome'] as String,
      profissional_profissao: map['profissional_profissao'] as String,
      profissional_imagem: map['profissional_imagem'] as String? ?? '',
    );
  }
}