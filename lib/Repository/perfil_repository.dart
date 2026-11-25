import 'auth_api.dart';
import '../Data/sessao_dao.dart';
import '../Model/usuarios.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';

class PerfilRepository {
  final AuthApi _api;
  final SessaoDao _dao;
  PerfilRepository({AuthApi? api, SessaoDao? dao})
    : _api = api ?? AuthApi(),
      _dao = dao ?? SessaoDao();

  // Dados guardados no SQLite: a tela de edição abre mesmo offline.
  Future<Map<String, Object?>> carregar() => _dao.buscarPerfil();
  Future<Map<String, Object?>> carregarProfissional() =>
      _dao.buscarPerfilProfissional();

  // Grava no MySQL pela API e atualiza a cópia local com a resposta.
  Future<Usuarios> atualizar({
    required Map<String, Object?> usuario,
    required Map<String, Object?> endereco,
    Map<String, Object?>? pessoaFisica,
    Map<String, Object?>? pessoaJuridica,

  }) async {
    if ((pessoaFisica == null) == (pessoaJuridica == null)) {
      throw ArgumentError('Informe pessoa física ou pessoa jurídica, apenas uma.');
    }

    final sessao = await _dao.buscar();
    if (sessao == null) {
      throw const AuthException('Sua sessão expirou. Entre novamente.', 401);
    }

    final body = await _api.post('auth/profile', {
      'usuario': usuario,
      'endereco': endereco,
      if (pessoaFisica != null) 'pessoaFisica': pessoaFisica,
      if (pessoaJuridica != null) 'pessoaJuridica': pessoaJuridica,
    }, token: sessao.token);

    await _dao.salvar(sessao.token, body);
    return Usuarios.fromMap(body);
  }


  Future<Usuarios> atualizarProfissional({
    required Map<String, Object?> usuario,
    required Map<String, Object?> endereco,
    Map<String, Object?>? pessoaFisica,
    Map<String, Object?>? pessoaJuridica,
    Map<String, Object?>? servicos,

  }) async {
    if ((pessoaFisica == null) == (pessoaJuridica == null)) {
      throw ArgumentError('Informe pessoa física ou pessoa jurídica, apenas uma.');
    }

    final sessao = await _dao.buscar();
    if (sessao == null) {
      throw const AuthException('Sua sessão expirou. Entre novamente.', 401);
    }

    final body = await _api.post('auth/profile', {
      'usuario': usuario,
      'endereco': endereco,
      'servicos': servicos,
      if (pessoaFisica != null) 'pessoaFisica': pessoaFisica,
      if (pessoaJuridica != null) 'pessoaJuridica': pessoaJuridica,
    }, token: sessao.token);

    await _dao.salvarProfissional(sessao.token, body);
    return Usuarios.fromMap(body);
  }

  Future<void> salvarPreferenciaNotificacoes(bool ativo) async {
    final sessao = await _dao.buscar();

    if (sessao == null) {
      throw const AuthException('Sua sessão expirou. Entre novamente.', 401);
    }

    await _api.post(
      'perfil/notificacoes',
      {'ativo': ativo},
      token: sessao.token,
    );
  }

  Future<void> registrarDispositivo() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    
    final sessao = await _dao.buscar();
    if (sessao == null || sessao.expirada) return;

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    await _api.post(
      'perfil/dispositivo',
      {'fcm_token': fcmToken},
      token: sessao.token,
    );
  }

  Future<bool> consultarPreferenciaNotificacoes() async {
    final sessao = await _dao.buscar();
    if (sessao == null || sessao.expirada) {
      throw const AuthException('Sua sessão expirou. Entre novamente.', 401);
    }

    final resposta = await _api.post(
      'perfil/notificacoes/consultar',
      {},
      token: sessao.token,
    );

    return resposta['notificacoes_ativas'] as bool;
  }

}