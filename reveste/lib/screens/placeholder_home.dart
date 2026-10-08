import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'boas_vindas_screen.dart';

/// Tela provisória: a home de verdade entra na parte 3.
class PlaceholderHome extends StatelessWidget {
  final AppUser usuario;
  const PlaceholderHome({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Olá, ${usuario.nome}!',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Perfil: ${usuario.tipoPerfil}'),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: OutlinedButton(
                onPressed: () async {
                  await AuthService().sair();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const BoasVindasScreen()),
                    (r) => false,
                  );
                },
                child: const Text('Sair'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}