import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../placeholder_home.dart';
import 'styles_screen.dart';

/// Verificação SIMULADA (decisão técnica do CP5): o Firebase Auth não envia
/// código numérico por e-mail, então aceitamos um código fixo de teste.
const codigoDeTeste = '1234';

class VerificationScreen extends StatefulWidget {
  final AppUser usuario;
  const VerificationScreen({super.key, required this.usuario});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _ctrls = List.generate(4, (_) => TextEditingController());
  final _nodes = List.generate(4, (_) => FocusNode());
  String? _erro;

  bool get _dark => widget.usuario.isBrecho;

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _continuar() {
    final codigo = _ctrls.map((c) => c.text).join();
    if (codigo != codigoDeTeste) {
      setState(() => _erro = 'Código incorreto. Use $codigoDeTeste (modo de teste).');
      return;
    }
    final destino = widget.usuario.isBrecho
        ? PlaceholderHome(usuario: widget.usuario)
        : StylesScreen(usuario: widget.usuario);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destino),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textoCor = _dark ? Colors.white : AppColors.grafite;
    return AuthShell(
      dark: _dark,
      titulo: 'Código de verificação',
      children: [
        Text(
          'Enviamos o seu código de verificação via e-mail. Confirme seu e-mail.',
          textAlign: TextAlign.center,
          style: TextStyle(color: textoCor.withValues(alpha: 0.7), fontSize: 13),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (i) {
            return SizedBox(
              width: 60,
              height: 64,
              child: TextField(
                controller: _ctrls[i],
                focusNode: _nodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(counterText: ''),
                onChanged: (v) {
                  if (v.isNotEmpty && i < 3) _nodes[i + 1].requestFocus();
                  if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        AuthError(_erro),
        AuthPrimaryButton(dark: _dark, label: 'Continuar', onPressed: _continuar),
        TextButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Modo de teste: use o código 1234.')),
          ),
          child: const Text('Reenviar código',
              style: TextStyle(color: AppColors.terracota)),
        ),
      ],
    );
  }
}