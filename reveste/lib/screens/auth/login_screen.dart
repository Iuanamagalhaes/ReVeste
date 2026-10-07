import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';
import '../placeholder_home.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final String perfil; // 'consumidor' ou 'brecho'
  const LoginScreen({super.key, required this.perfil});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _loading = false;
  String? _erro;

  bool get _dark => widget.perfil == 'brecho';

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_email.text.trim().isEmpty || _senha.text.isEmpty) {
      setState(() => _erro = 'Preencha e-mail e senha.');
      return;
    }
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final u = await AuthService()
          .entrar(_email.text.trim(), _senha.text, perfil: widget.perfil);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PlaceholderHome(usuario: u)),
        (r) => false,
      );
    } catch (e) {
      if (mounted) setState(() => _erro = AuthService.mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      dark: _dark,
      titulo: _dark ? 'Entrar como brechó' : 'Entrar como consumidor',
      children: [
        AuthField(
            controller: _email,
            hint: _dark ? 'e-mail da loja' : 'seuemail@gmail.com',
            dark: _dark,
            keyboard: TextInputType.emailAddress),
        AuthField(controller: _senha, hint: '********', dark: _dark, obscure: true),
        AuthError(_erro),
        AuthPrimaryButton(dark: _dark, label: 'Entrar', onPressed: _entrar, loading: _loading),
        const SizedBox(height: 12),
        AuthSecondaryButton(
          dark: _dark,
          label: 'Criar conta',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RegisterScreen(perfil: widget.perfil)),
          ),
        ),
      ],
    );
  }
}