import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';

class BoasVindasScreen extends StatelessWidget {
  const BoasVindasScreen({super.key});

  void _ir(BuildContext context, String perfil) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoginScreen(perfil: perfil)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TODO: trocar pelo logo exportado do Figma (assets/logo.png)
              const Icon(Icons.shopping_cart_outlined, size: 72, color: AppColors.verde),
              const SizedBox(height: 12),
              Text('ReVeste',
                  textAlign: TextAlign.center,
                  style: t.headlineMedium?.copyWith(color: AppColors.verde)),
              const SizedBox(height: 4),
              const Text('moda com história',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.salvia)),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _ir(context, 'consumidor'),
                child: const Text('Sou consumidor'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _ir(context, 'brecho'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.grafite),
                child: const Text('Sou um brechó'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}