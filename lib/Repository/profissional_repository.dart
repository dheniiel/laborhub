import '../Model/profissional.dart';

class ProfissionalRepository{
  // ainda não foi feita a API com o banco
  Future<List<Profissional>> Listar () async {
    return _dados.map(Profissional.fromMap).toList();
  }


  //exemplo somente para teste, já que não possuimos dados cadastrados
  static const List<Map<String, Object?>> _dados = [
    {
      'profissional_nome': 'Rogério Alves',
      'profissional_profissao': 'Eletricista',
      'profissional_cidade': 'Ceres',
      'profissional_uf': 'GO',
      'profissional_avaliacao': 4.9,
      'profissional_total_avaliacoes': 11890,
      'profissional_observacao':
          'Profissional Avançado, trabalho na área a cerca de 5 anos.',
      'profissional_preco': 149.99,
      'profissional_imagem': '',
    },
    {
      'profissional_nome': 'Letícia Felix',
      'profissional_profissao': 'Professora de linguagem',
      'profissional_cidade': 'Rialma',
      'profissional_uf': 'GO',
      'profissional_avaliacao': 4.9,
      'profissional_total_avaliacoes': 11250,
      'profissional_observacao':
          'Avançado - Sou professora particular de diferentes línguas e quero ajudar você a realizar seus sonhos.',
      'profissional_preco': 549.99,
      'profissional_imagem': '',
    },
  ];
}