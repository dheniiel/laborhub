class Profissional{
  final String profissional_nome;
  final String profissional_profissao;
  final String profissional_cidade;
  final String profissional_uf;
  final double profissional_avaliacao;
  final int profissional_total_avaliacoes;
  final String profissional_observacao;
  final double profissional_preco;
  final String profissional_imagem;

  const Profissional({
    required this.profissional_nome,
    required this.profissional_profissao,
    required this.profissional_cidade,
    required this.profissional_uf,
    required this.profissional_avaliacao,
    required this.profissional_total_avaliacoes,
    required this.profissional_observacao,
    required this.profissional_preco,
    required this.profissional_imagem,
  });

  factory Profissional.fromMap(Map<String, Object?> map){
    return Profissional(
      profissional_nome: map['profissional_nome'] as String,
      profissional_profissao: map['profissional_profissao'] as String,
      profissional_cidade: map['profissional_cidade'] as String,
      profissional_uf: map['profissional_uf'] as String,
      profissional_avaliacao: (map['profissional_avaliacao'] as num).toDouble(),
      profissional_total_avaliacoes: map['profissional_total_avaliacoes'] as int,
      profissional_observacao: map['profissional_observacao'] as String,
      profissional_preco: (map['profissional_preco'] as num).toDouble(),
      profissional_imagem: map['profissional_imagem'] as String? ?? '',
    );
  }
}