import '../Model/solicitacao.dart';

class SolicitacaoRepository {
  // ainda não foi feita a API com o banco (tabela solicitacao)
  Future<List<Solicitacao>> Listar() async {
    return _dados.map(Solicitacao.fromMap).toList();
  }

  // Sem API ainda: a tela só remove o item da lista.
  Future<void> cancelar(int solicitacaoId) async {}


  //exemplo somente para teste, já que não possuimos dados cadastrados
  static const List<Map<String, Object?>> _dados = [
    {
      'solicitacao_id': 1,
      'solicitacao_data': '2026-05-15',
      'solicitacao_conclusao': '2026-05-25',
      'solicitacao_status': 'Finalizado',
      'servicos_valor': 549.99,
      'profissional_nome': 'Letícia Felix',
      'profissional_profissao': 'Professora de linguagem',
      'profissional_imagem': '',
    },
    {
      'solicitacao_id': 2,
      'solicitacao_data': '2026-07-01',
      'solicitacao_status': 'Pendente',
      'servicos_valor': 149.99,
      'profissional_nome': 'Kamilla Marcela',
      'profissional_profissao': 'Eletricista',
      'profissional_imagem': '',
    },
    {
      'solicitacao_id': 3,
      'solicitacao_data': '2026-05-15',
      'solicitacao_status': 'Recusado',
      'solicitacao_motivo': 'Profissional sem disponibilidade na data solicitada.',
      'servicos_valor': 199.99,
      'profissional_nome': 'Matheus Kyan',
      'profissional_profissao': 'Encanador',
      'profissional_imagem': '',
    },
  ];
}