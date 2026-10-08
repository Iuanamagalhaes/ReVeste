import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth/verification_screen.dart';
import 'boas_vindas_screen.dart';
import 'home_router.dart';

/// Mantém o usuário logado ao reabrir o app.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<Widget> _destino = _resolver();

  Future<Widget> _resolver() async {
    try {
      final auth = AuthService();
      if (!auth.logado) return const BoasVindasScreen();
      final u = await auth.perfilAtual();
      if (u == null) {
        await auth.sair();
        return const BoasVindasScreen();
      }
      if (AuthService.exigirVerificacao && !await auth.emailVerificado()) {
        return VerificationScreen(usuario: u, emailJaEnviado: false);
      }
      return destinoPosLogin(u);
    } catch (_) {
      return const BoasVindasScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _destino,
      builder: (context, snap) {
        if (snap.hasData) return snap.data!;
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
