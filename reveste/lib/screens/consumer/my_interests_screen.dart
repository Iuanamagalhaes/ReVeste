import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/interesse.dart';
import '../../services/firestore_service.dart';
import '../../widgets/interesse_tile.dart';

class MyInterestsScreen extends StatelessWidget {
  final AppUser usuario;
  const MyInterestsScreen({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus interesses')),
      body: StreamBuilder<List<Interesse>>(
        stream: FirestoreService().interessesDoConsumidor(usuario.id),
        builder: (context, s) {
          if (s.hasError) return const Center(child: Text('Não foi possível carregar.'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final l = s.data!;
          if (l.isEmpty) {
            return const Center(child: Text('Você ainda não falou com nenhum brechó.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [for (final i in l) InteresseTile(interesse: i, visaoLoja: false)],
          );
        },
      ),
    );
  }
}
