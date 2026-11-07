import 'usuarios.dart';

class Sessao {

final String token;
final String? tipo; // Cliente ou Profissional
final DateTime expiraEm;
final Usuarios usuario;

const Sessao({
    required this.token,
    required this.tipo,
    required this.expiraEm,
    required this.usuario,
});

bool get expirada => !expiraEm.isAfter(DateTime.now());

}
