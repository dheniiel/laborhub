import 'auth_api.dart';
import '../Data/sessao_dao.dart';
import '../Model/solicitacao.dart';

class SolicitacaoRepository {
  final AuthApi _api;
  final SessaoDao _dao;
  SolicitacaoRepository({AuthApi? api, SessaoDao? dao})
    : _api = api ?? AuthApi(),
      _dao = dao ?? SessaoDao();

  // Solicitações do cliente logado (MySQL, via API).
  Future<List<Solicitacao>> Listar() async {
    final body = await _api.post('solicitacoes', {}, token: await _token());
    return (body['solicitacoes'] as List)
        .map((item) => Solicitacao.fromMap(Map<String, Object?>.from(item as Map)))
        .toList();
  }

  // Cancela no banco; a tela remove o item da lista após o sucesso.
  Future<void> cancelar(int solicitacaoId) async {
    await _api.post(
      'solicitacoes/cancelar',
      {'solicitacao_id': solicitacaoId},
      token: await _token(),
    );
  }

  // Avalia o profissional de um serviço finalizado (uma vez por serviço).
  Future<void> avaliar(int solicitacaoId, int nota, String comentario) async {
    await _api.post(
      'solicitacoes/avaliar',
      {
        'solicitacao_id': solicitacaoId,
        'avaliacao_notas': nota,
        'avaliacao_descricao': comentario,
      },
      token: await _token(),
    );
  }

  // Pega a quantidade de solicitacao pendente

  Future<int> listarServicoPendente(int usuarioId) async {
    final body = await _api.post(
      'solicitacoes/listarServicoPendente',
      {'usuario_id': usuarioId},
      token: await _token(),
    );

    return (body['totalPendente'] as num).toInt();
  }


  Future<int> listarServicoAtivo(int usuarioId) async {
    final body = await _api.post(
      'solicitacoes/listarServicoAtivo',
      {'usuario_id': usuarioId},
      token: await _token(),
    );

    return (body['totalAtivo'] as num).toInt();
  }

  Future<List<Map<String, dynamic>>> solicitacaoPendente(
      int usuarioId,
      ) async {
    final body = await _api.post(
      'solicitacoes/solicitacaoPendente',
      {'usuario_id': usuarioId},
      token: await _token(),
    );

    return (body['solicitacoes'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> SolicitacaoProfissionalAtivo(
      int usuarioId,
      ) async {
    final body = await _api.post(
      'solicitacoes/SolicitacaoProfissionalAtivo',
      {'usuario_id': usuarioId},
      token: await _token(),
    );

    return (body['solicitacoesAtivas'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }


  Future<void> recusarSolicitacao(int solicitacaoId, String motivo) async {
    await _api.post(
      'solicitacoes/recusarSolicitacao',
      {'solicitacao_id': solicitacaoId,
        'motivo' : motivo,
      },
      token: await _token(),
    );
  }

  // Recusar solicitacao
  Future<void> aceitarSolicitacao(int solicitacaoId) async {
    await _api.post(
      'solicitacoes/aceitarSolicitacao',
      {'solicitacao_id': solicitacaoId
      },
      token: await _token(),
    );
  }

  Future<void> finalizarSolicitacao(int solicitacaoId) async {
    await _api.post(
      'solicitacoes/finalizarSolicitacao',
      {'solicitacao_id': solicitacaoId,

      },
      token: await _token(),
    );
  }




  Future<String> _token() async {
    final sessao = await _dao.buscar();
    if (sessao == null) {
      throw const AuthException('Sua sessão expirou. Entre novamente.', 401);
    }
    return sessao.token;
  }

  Future<int> enviarSolicitacao({
    required DateTime solicitacao_data,
    required DateTime solicitacao_data_atual,
    required int solicitacao_quantidade,
    required String solicitacao_observacao,
    required DateTime solicitacao_criada_em,
    required int solicitacao_endereco_id,
    required int solicitacao_usuarios_id,
    required int servicos_id,

  }) async {

    // print({
    //   'solicitacao_data': solicitacao_data.toIso8601String().split('T').first,
    //   'solicitacao_quantidade': solicitacao_quantidade,
    //   'solicitacao_observacao': solicitacao_observacao,
    //   'solicitacao_endereco_id': solicitacao_endereco_id,
    //   'servicos_id': servicos_id,
    // });

    final body = await _api.post(
      'solicitacoes/enviarSolicitacao', {

        'solicitacao_data' : solicitacao_data.toIso8601String().split('T').first,
      'solicitacao_data_atual' : solicitacao_data_atual.toIso8601String().split('T').first,
      'solicitacao_quantidade' : solicitacao_quantidade,
      'solicitacao_observacao' : solicitacao_observacao,
      'solicitacao_criada_em' : solicitacao_criada_em.toIso8601String().split('T').first,
      'solicitacao_endereco_id' : solicitacao_endereco_id,
      'solicitacao_usuarios_id' : solicitacao_usuarios_id,
      'servicos_id' : servicos_id,


      },


      token: await _token(),
    );

    return body['solicitacao_id'] as int;

  }
}