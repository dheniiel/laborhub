// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// import '../Formularios/forms.dart';
// import '../Repository/auth_api.dart';
// import '../Utils/validacao.dart';
//
// class RecuperarSenha extends StatefulWidget {
//   final RecuperacaoRepository? repository;
//   const RecuperarSenha({super.key, this.repository});
//   @override
//   State<RecuperarSenha> createState() => _RecuperarSenhaState();
// }
//
// class _RecuperarSenhaState extends State<RecuperarSenha> {
//   final _form = GlobalKey<FormState>();
//   final _email = TextEditingController();
//   final _senha = TextEditingController();
//   final _confirmacao = TextEditingController();
//   final _digitos = List.generate(6, (_) => TextEditingController());
//   final _focos = List.generate(6, (_) => FocusNode());
//   late final RecuperacaoRepository _repository;
//   String? _token;
//   String? _erro;
//   int _etapa = 0;
//   int _espera = 0;
//   bool _carregando = false;
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//     _repository = widget.repository ?? RecuperacaoRepository();
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     for (final controller in [_email, _senha, _confirmacao, ..._digitos]) {
//       controller.dispose();
//     }
//     for (final foco in _focos) {
//       foco.dispose();
//     }
//     super.dispose();
//   }
//
//   void _iniciarEspera() {
//     _timer?.cancel();
//     _espera = 60;
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!mounted) return;
//       setState(() => _espera--);
//       if (_espera == 0) timer.cancel();
//     });
//   }
//
//   Future<void> _enviar({bool reenviar = false}) async {
//     if (_carregando) return;
//     FocusScope.of(context).unfocus();
//     if (!reenviar && !_form.currentState!.validate()) return;
//     setState(() {
//       _carregando = true;
//       _erro = null;
//     });
//     try {
//       if (_etapa == 0 || reenviar) {
//         await _repository.solicitar(_email.text);
//         if (!mounted) return;
//         setState(() {
//           _etapa = 1;
//           _token = null;
//           for (final digito in _digitos) {
//             digito.clear();
//           }
//           _iniciarEspera();
//         });
//       } else if (_etapa == 1) {
//         final codigo = _digitos.map((d) => d.text).join();
//         if (codigo.length != 6)
//           throw const AuthException('Informe os seis dígitos.');
//         final token = await _repository.validar(_email.text, codigo);
//         if (!mounted) return;
//         setState(() {
//           _token = token;
//           _etapa = 2;
//         });
//       } else {
//         await _repository.redefinir(
//           _email.text,
//           _token!,
//           _senha.text,
//           _confirmacao.text,
//         );
//         if (!mounted) return;
//         Navigator.pop(context, true);
//       }
//     } on AuthException catch (error) {
//       if (mounted) setState(() => _erro = error.mensagem);
//     } catch (_) {
//       if (mounted)
//         setState(() => _erro = 'Não foi possível concluir. Tente novamente.');
//     } finally {
//       if (mounted) setState(() => _carregando = false);
//     }
//   }
//
//   Widget _campo(
//     String label,
//     TextEditingController controller,
//     String? Function(String?) validator, {
//     bool senha = false,
//   }) => Column(
//     crossAxisAlignment: CrossAxisAlignment.stretch,
//     children: [
//       Text(label),
//       const SizedBox(height: 4),
//       Forms(
//         controlador: controller,
//         tipagemValor: senha
//             ? TextInputType.visiblePassword
//             : TextInputType.emailAddress,
//         rotulo: senha
//             ? (controller == _confirmacao
//                   ? 'Digite novamente sua senha'
//                   : 'Digite sua senha')
//             : 'Digite seu email',
//         ocultarTexto: senha,
//         validador: validator,
//       ),
//     ],
//   );
//   Widget _codigo() => Row(
//     children: List.generate(
//       6,
//       (i) => Expanded(
//         child: Padding(
//           padding: EdgeInsets.only(right: i == 2 ? 12 : (i == 5 ? 0 : 4)),
//           child: Semantics(
//             label: 'Dígito ${i + 1} de 6',
//             child: TextFormField(
//               controller: _digitos[i],
//               focusNode: _focos[i],
//               keyboardType: TextInputType.number,
//               textAlign: TextAlign.center,
//               autofillHints: i == 0 ? const [AutofillHints.oneTimeCode] : null,
//               inputFormatters: [
//                 FilteringTextInputFormatter.digitsOnly,
//                 LengthLimitingTextInputFormatter(6),
//               ],
//               decoration: InputDecoration(
//                 filled: true,
//                 fillColor: const Color(0xFFF4F4F4),
//                 contentPadding: const EdgeInsets.symmetric(vertical: 10),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ),
//               onChanged: (value) {
//                 if (value.length > 1) {
//                   for (var j = 0; j < 6; j++) {
//                     _digitos[j].text = j < value.length ? value[j] : '';
//                   }
//                   _focos[value.length - 1].requestFocus();
//                 } else if (value.isNotEmpty && i < 5) {
//                   _focos[i + 1].requestFocus();
//                 } else if (value.isEmpty && i > 0) {
//                   _focos[i - 1].requestFocus();
//                 }
//               },
//             ),
//           ),
//         ),
//       ),
//     ),
//   );
//   @override
//   Widget build(BuildContext context) => Scaffold(
//     backgroundColor: Colors.white,
//     appBar: AppBar(
//       backgroundColor: Colors.white,
//       surfaceTintColor: Colors.white,
//     ),
//     body: SafeArea(
//       child: Center(
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 500),
//           child: LayoutBuilder(
//             builder: (context, constraints) => SingleChildScrollView(
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                 child: IntrinsicHeight(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 32),
//                     child: Form(
//                       key: _form,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           const SizedBox(height: 24),
//                           const Text(
//                             'Redefinir senha',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               fontFamily: 'Montserrat',
//                               fontSize: 26,
//                             ),
//                           ),
//                           const SizedBox(height: 90),
//                           Text(
//                             _etapa == 0
//                                 ? 'Informe o Email para redefinição de senha'
//                                 : _etapa == 1
//                                 ? 'Digite o Código recebido no email'
//                                 : 'Informe a nova senha',
//                           ),
//                           const SizedBox(height: 16),
//                           AbsorbPointer(
//                             absorbing: _carregando,
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.stretch,
//                               children: [
//                                 if (_etapa == 0)
//                                   _campo('Email', _email, Validacao.email),
//                                 if (_etapa == 1) ...[
//                                   _codigo(),
//                                   const SizedBox(height: 12),
//                                   const Text(
//                                     'Se o email estiver cadastrado, você receberá um código válido por 10 minutos.',
//                                   ),
//                                 ],
//                                 if (_etapa == 2) ...[
//                                   _campo('Senha', _senha, (value) {
//                                     final error = Validacao.senha(value);
//                                     if (error != null) return error;
//                                     return value!.length > 128
//                                         ? 'Use até 128 caracteres.'
//                                         : null;
//                                   }, senha: true),
//                                   const SizedBox(height: 16),
//                                   _campo(
//                                     'Confirme a senha',
//                                     _confirmacao,
//                                     (value) => value == _senha.text
//                                         ? null
//                                         : 'As senhas não conferem.',
//                                     senha: true,
//                                   ),
//                                 ],
//                               ],
//                             ),
//                           ),
//                           if (_erro != null)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 16),
//                               child: Semantics(
//                                 liveRegion: true,
//                                 child: Text(
//                                   _erro!,
//                                   style: const TextStyle(color: Colors.red),
//                                 ),
//                               ),
//                             ),
//                           const SizedBox(height: 48),
//                           SizedBox(
//                             height: 40,
//                             child: ElevatedButton(
//                               onPressed: _carregando ? null : () => _enviar(),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xFF3B82F6),
//                                 foregroundColor: Colors.white,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                               ),
//                               child: _carregando
//                                   ? const SizedBox(
//                                       width: 20,
//                                       height: 20,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         color: Colors.white,
//                                       ),
//                                     )
//                                   : Text(_etapa == 2 ? 'Redefinir' : 'Enviar'),
//                             ),
//                           ),
//                           if (_etapa > 0)
//                             TextButton(
//                               onPressed: _carregando || _espera > 0
//                                   ? null
//                                   : () => _enviar(reenviar: true),
//                               child: Text(
//                                 _espera > 0
//                                     ? 'Reenviar código em ${_espera}s'
//                                     : 'Reenviar código',
//                               ),
//                             ),
//                           if (_etapa > 0)
//                             TextButton(
//                               onPressed: _carregando
//                                   ? null
//                                   : () => setState(() {
//                                       _etapa = 0;
//                                       _token = null;
//                                       _erro = null;
//                                       _senha.clear();
//                                       _confirmacao.clear();
//                                     }),
//                               child: const Text('Alterar email'),
//                             ),
//                           const SizedBox(height: 40),
//                           const Spacer(),
//                           const Text(
//                             'Direito Reservado 2026',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(color: Colors.grey, fontSize: 12),
//                           ),
//                           const SizedBox(height: 32),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     ),
//   );
// }
