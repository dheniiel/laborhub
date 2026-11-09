import 'dart:async';

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
  final String profissional_telefone;
  final String profissional_email;
  final String profissional_servicos_nome;
  final String profissional_data;
  final String profissional_tipo_cobranca;
  final String profissional_experiencia;
  final int profissional_servicos_id;
  final int profissional_endereco_id;
  final int profissioal_usuarios_id;


  final List<int> avaliacoesPorEstrela;


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
    required this.profissional_telefone,
    required this.profissional_email,
    required this.profissional_servicos_nome,
    required this.profissional_data,
    required this.profissional_tipo_cobranca,
    required this.profissional_experiencia,
    required this.profissional_servicos_id,
    required this.profissional_endereco_id,
    required this.profissioal_usuarios_id,
    required this.avaliacoesPorEstrela
  });

  factory Profissional.fromMap(Map<String,  Object?> map){
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
      profissional_telefone:  map['profissional_telefone'] as String? ?? '',
      profissional_email:  map['profissional_email'] as String? ?? '',
      profissional_servicos_nome:  map['profissional_servicos_nome'] as String? ?? '',
      profissional_data:  map['profissional_data'] as String? ?? '',
      profissional_tipo_cobranca:  map['profissional_tipo_cobranca'] as String? ?? '',
      profissional_experiencia:  map['profissional_experiencia'] as String? ?? '',
      profissional_endereco_id: map['profissional_endereco_id'] as int,
      profissional_servicos_id: map['profissional_servicos_id'] as int,
      profissioal_usuarios_id: map['profissional_usuarios_id'] as int,

      avaliacoesPorEstrela: List.generate(
        5,
            (index) => int.parse(
          '${map['estrelas_${index + 1}'] ?? 0}',
        ),
      ),


    );
  }
}