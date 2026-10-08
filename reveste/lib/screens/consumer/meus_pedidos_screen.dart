import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../widgets/pedido_tile.dart';

class MeusPedidosScreen extends StatelessWidget {
  final AppUser usuario;
  const MeusPedidosScreen({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Minhas compras')),
        body: PedidosLista(usuario: usuario),
      );
}
