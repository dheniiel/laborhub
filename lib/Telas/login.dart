import 'package:flutter/material.dart';
// import 'package:path/path.dart';

import '../Formularios/forms.dart';
import '../Repository/usuarios_repository.dart';
import '../Repository/sessao_repository.dart';
import '../Model/usuarios.dart';
import 'escolhaUsuario.dart';
import 'recuperarSenha.dart';
import '../Repository/auth_api.dart';
import 'homeCliente.dart';
import 'homeProfissional.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final UsuariosRepository _repository = UsuariosRepository();
  final SessaoRepository _sessao = SessaoRepository();

  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _restaurarSessao();
  }

  // Sessão salva no SQLite: entra direto, mesmo sem internet.
  Future<void> _restaurarSessao() async {
    try {
      final sessao = await _sessao.restaurar();
      if (!mounted || sessao == null) return;

      if(sessao.tipo != 'Cliente' && sessao.tipo != 'Profissional') return;
      _abrirHome(sessao.usuario, sessao.tipo!);
    } catch (_) {
      // Banco local indisponível: segue no login normal.
    }
  }

  void _abrirHome(Usuarios usuario, String tipo) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => tipo == 'Cliente'
          ? HomeCliente(usuario: usuario)
          : Homeprofissional(usuarios: usuario),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  String? _validarEmail(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe seu email';
    }
    final emailValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailValido.hasMatch(valor.trim())) {
      return 'Email inválido';
    }
    return null;
  }

  String? _validarSenha(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Informe sua senha';
    }
    return null;
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      final (usuario, tipo) = await _repository.Autenticar(
        _emailController.text,
        _senhaController.text,
      );

      if (!mounted) return;

      if (tipo != 'Cliente' && tipo != 'Profissional') {
        // Sem área para este perfil no app: não mantém a sessão aberta.
        await _sessao.sair();
        if (!mounted) return;
        _mostrarMensagem('Perfil não encontrado.');
        return;
      }

      _abrirHome(usuario, tipo!);
    } on AuthException catch (error) {
      if (mounted) _mostrarMensagem(error.mensagem);
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível realizar o login. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Spacer(flex: 5),

                              const Text(
                                'Login',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),

                              const Spacer(flex: 6),

                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 4),

                              Forms(
                                controlador: _emailController,
                                tipagemValor: TextInputType.emailAddress,
                                rotulo: 'Digite seu email',
                                validador: _validarEmail,
                              ),

                              const SizedBox(height: 28),

                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Text(
                                  'Senha',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 4),

                              Forms(
                                controlador: _senhaController,
                                tipagemValor: TextInputType.visiblePassword,
                                rotulo: 'Digite sua senha',
                                ocultarTexto: true,
                                validador: _validarSenha,
                              ),

                              const SizedBox(height: 12),

                              Align(
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                  onTap: _carregando
                                      ? null
                                      : () async {
                                          final sucesso =
                                              await Navigator.push<bool>(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => RecuperarSenha(),
                                                ),
                                              );
                                          if (!mounted) return;
                                          if (sucesso == true) {
                                            _senhaController.clear();
                                            _mostrarMensagem(
                                              'Senha redefinida com sucesso. Entre com sua nova senha.',
                                            );
                                          }
                                        },
                                  child: const Text(
                                    'Esqueci minha senha',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'Montserrat',
                                      color: Color(0xFF3B82F6),
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFF3B82F6),
                                    ),
                                  ),
                                ),
                              ),
                              
                              const Spacer(flex: 3),

                              SizedBox(
                                height: 40,
                                child: ElevatedButton(
                                  onPressed: _carregando ? null : _entrar,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: const Color(
                                      0xFF3B82F6,
                                    ),
                                    disabledForegroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: _carregando
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Entrar',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 21),

                              SizedBox(
                                height: 40,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const EscolhaUsuario(),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: EdgeInsets.zero,
                                    side: const BorderSide(
                                      color: Color(0xFF858585),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: const Text(
                                    'Registrar',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),

                              const Spacer(flex: 6),

                              const Text(
                                'Direito reservado 2026',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Montserrat',
                                  color: Colors.grey,
                                ),
                              ),

                              const Spacer(flex: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
