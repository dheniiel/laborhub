import 'package:flutter/material.dart';

class MenuLateral extends StatelessWidget {

  final VoidCallback onEditarPerfil;
  final VoidCallback onSair;

  const MenuLateral({
    super.key,
    required this.onEditarPerfil,
    required this.onSair,
  });

  static const _estiloTexto = TextStyle(
    fontSize: 15,
    fontFamily: 'Montserrat',
    color: Colors.black,
  );

  // Fecha a barra antes de executar a ação escolhida.
  void _selecionar(BuildContext context, VoidCallback acao) {
    Navigator.of(context).pop();
    acao();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            ListTile(
              leading: const Icon(
                Icons.manage_accounts,
                size: 25,
                color: Color(0xFF3B82F6),
              ),
              title: const Text('Editar perfil', style: _estiloTexto),
              onTap: () => _selecionar(context, onEditarPerfil),
            ),

            const Divider(height: 1, color: Color(0xFFD9D9D9)),

            ListTile(
              leading: const Icon(Icons.logout, size: 25, color: Colors.black),
              title: const Text('Logout', style: _estiloTexto),
              onTap: () => _selecionar(context, onSair),
            ),
          ],
        ),
      ),
    );
  }
}