class Solicitacao {

  final int solicitacao_id;
  final DateTime solicitacao_data; // Data para o serviço
  final DateTime solicitacao_data_atual; // Data em que foi solicitado
  final DateTime? solicitacao_conclusao;
  final int solicitacao_quantidade; // Dias solicitados
  final String solicitacao_status; // Finalizado, Pendente ou Recusado
  final String? solicitacao_motivo;
  final String? solicitacao_observacao;
  final double servicos_valor;
  final String servicos_tipo_cobranca;
  final double? valor_final;
  final String? descricao_conclusao;

  // Dados do profissional exibidos no card e nos detalhes.
  final String profissional_nome;
  final String profissional_profissao;
  final String profissional_imagem;
  final String profissional_telefone;
  final String profissional_email;
  final String profissional_cidade;
  final String profissional_uf;

  // Avaliação feita pelo cliente; null enquanto o serviço não foi avaliado.
  final int? avaliacao_notas;
  final String? avaliacao_descricao;

  bool get avaliado => avaliacao_notas != null;
  final String? clienteNome;
  final String? clienteImagem;
  final String? servicosNome;

  const Solicitacao({
    required this.solicitacao_id,
    required this.solicitacao_data,
    required this.solicitacao_data_atual,
    this.solicitacao_conclusao,
    required this.solicitacao_quantidade,
    required this.solicitacao_status,
    this.solicitacao_motivo,
    this.solicitacao_observacao,
    required this.servicos_valor,
    required this.servicos_tipo_cobranca,
    required this.profissional_nome,
    required this.profissional_profissao,
    required this.profissional_imagem,
    required this.profissional_telefone,
    required this.profissional_email,
    required this.profissional_cidade,
    required this.profissional_uf,
    this.avaliacao_notas,
    this.avaliacao_descricao,
    this.valor_final,
    this.descricao_conclusao,

    this.clienteNome,
    this.clienteImagem,
    this.servicosNome,
  });

  factory Solicitacao.fromMap(Map<String, Object?> map) {
    final conclusao = map['solicitacao_conclusao'] as String?;

    return Solicitacao(
      solicitacao_id: map['solicitacao_id'] as int,
      solicitacao_data: DateTime.parse(map['solicitacao_data'] as String),
      solicitacao_data_atual: DateTime.parse(map['solicitacao_data_atual'] as String),
      solicitacao_conclusao: conclusao == null ? null : DateTime.parse(conclusao),
      solicitacao_quantidade: map['solicitacao_quantidade'] as int,
      solicitacao_status: map['solicitacao_status'] as String,
      solicitacao_motivo: map['solicitacao_motivo'] as String?,
      solicitacao_observacao: map['solicitacao_observacao'] as String?,
      servicos_valor: (map['servicos_valor'] as num).toDouble(),
      servicos_tipo_cobranca: (map['servicos_tipo_cobranca'] as String?) ?? '',
      valor_final: double.tryParse(map['valor_final']?.toString() ?? ''),
      descricao_conclusao: map['descricao_conclusao'] as String?,

      profissional_nome: map['profissional_nome'] as String? ?? '',
      clienteNome: map['cliente_nome'] as String?,
      clienteImagem: map['cliente_imagem'] as String?,
      servicosNome: map['servicos_nome'] as String?,
      profissional_profissao: map['profissional_profissao'] as String? ?? '',
      profissional_imagem: map['profissional_imagem'] as String? ?? '',
      profissional_telefone: map['profissional_telefone'] as String? ?? '',
      profissional_email: map['profissional_email'] as String? ?? '',
      profissional_cidade: map['profissional_cidade'] as String? ?? '',
      profissional_uf: map['profissional_uf'] as String? ?? '',
      avaliacao_notas: map['avaliacao_notas'] as int?,
      avaliacao_descricao: map['avaliacao_descricao'] as String?,
    );
  }
}