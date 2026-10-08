import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Moldura das telas de entrada. dark = true para o perfil de brechó.
class AuthShell extends StatelessWidget {
  final bool dark;
  final String titulo;
  final List<Widget> children;

  const AuthShell({
    super.key,
    required this.dark,
    required this.titulo,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppColors.grafite : AppColors.creme;
    final tituloCor = dark ? AppColors.terracota : AppColors.verde;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back, color: AppColors.terracota),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: tituloCor),
              ),
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final bool obscure;
  final bool dark;
  final TextInputType? keyboard;

  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.dark,
    this.label,
    this.obscure = false,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: 12,
                  color: dark ? AppColors.terracota : AppColors.verde,
                ),
              ),
            ),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboard,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.salvia),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final bool dark;
  final String label;
  final VoidCallback onPressed;
  final bool loading;

  const AuthPrimaryButton({
    super.key,
    required this.dark,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: dark
          ? ElevatedButton.styleFrom(backgroundColor: AppColors.terracota)
          : null,
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(label),
    );
  }
}

class AuthSecondaryButton extends StatelessWidget {
  final bool dark;
  final String label;
  final VoidCallback onPressed;

  const AuthSecondaryButton({
    super.key,
    required this.dark,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: dark
          ? OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
            )
          : null,
      child: Text(label),
    );
  }
}

class AuthError extends StatelessWidget {
  final String? mensagem;
  const AuthError(this.mensagem, {super.key});

  @override
  Widget build(BuildContext context) {
    if (mensagem == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        mensagem!,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.terracota, fontSize: 13),
      ),
    );
  }
}