import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../state/cart.dart';
import 'auth/styles_screen.dart';
import 'boas_vindas_screen.dart';
import 'brecho/brecho_shell.dart';
import 'consumer/consumer_shell.dart';

Widget homePara(AppUser u) =>
    u.isBrecho ? BrechoShell(usuario: u) : ConsumerShell(usuario: u);

/// Consumidor sem estilos ainda passa pela escolha de estilos.
Widget destinoPosLogin(AppUser u) =>
    (!u.isBrecho && u.estilos.isEmpty) ? StylesScreen(usuario: u) : homePara(u);

void irParaHome(BuildContext context, AppUser u) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => homePara(u)),
    (r) => false,
  );
}

Future<void> sairDoApp(BuildContext context) async {
  Cart.instance.limpar();
  await AuthService().sair();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const BoasVindasScreen()),
    (r) => false,
  );
}
