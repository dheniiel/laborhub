class Avaliacao {
  final int id;
  final String? assunto;
  final String? descricao;
  final String? resposta;
  final int nota;
  final String data;
  final String avaliadorNome;
  final String avaliadorImagem;

  const Avaliacao({
    required this.id,
    this.assunto,
    this.descricao,
    this.resposta,
    required this.nota,
    required this.data,
    required this.avaliadorNome,
    required this.avaliadorImagem,
  });

  factory Avaliacao.fromMap(Map<String, dynamic> map) {
    return Avaliacao(
      id: int.parse(map['avaliacao_id'].toString()),
      assunto: map['avaliacao_assunto'] as String?,
      descricao: map['avaliacao_descricao'] as String?,
      resposta: map['avaliacao_resposta'] as String?,
      nota: int.parse(map['avaliacao_notas'].toString()),
      data: map['avaliacao_data'] as String,
      avaliadorNome: map['avaliador_nome'] as String? ?? 'Usuário',
      avaliadorImagem: map['avaliador_imagem'] as String? ?? '',
    );
  }
}