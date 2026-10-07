import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';
import 'verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String perfil;
  const RegisterScreen({super.key, required this.perfil});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirma = TextEditingController();
  final _rua = TextEditingController();
  final _telefone = TextEditingController();
  bool _lojaFisica = true;
  bool _loading = false;
  String? _erro;

  bool get _dark => widget.perfil == 'brecho';

  @override
  void dispose() {
    for (final c in [_nome, _email, _senha, _confirma, _rua, _telefone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (_nome.text.trim().isEmpty || _email.text.trim().isEmpty || _senha.text.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos.');
      return;
    }
    if (_telefone.text.replaceAll(RegExp(r'\D'), '').length < 10) {
      setState(() => _erro = 'Informe um telefone com DDD.');
      return;
    }
    if (_senha.text != _confirma.text) {
      setState(() => _erro = 'As senhas não são iguais.');
      return;
    }
    if (_dark && _lojaFisica && _rua.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o endereço da loja física.');
      return;
    }
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final u = await AuthService().cadastrar(
        nome: _nome.text.trim(),
        email: _email.text.trim(),
        senha: _senha.text,
        perfil: widget.perfil,
        lojaFisica: _lojaFisica,
        rua: _rua.text.trim(),
        telefone: _telefone.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VerificationScreen(usuario: u)),
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
      titulo: 'Criar uma conta',
      children: [
        AuthField(controller: _nome, label: 'Nome', hint: _dark ? 'Nome do brechó' : 'Ex: Julia Barros', dark: _dark),
        AuthField(controller: _email, label: 'Email', hint: 'seuemail@gmail.com', dark: _dark, keyboard: TextInputType.emailAddress),
        AuthField(controller: _telefone, label: 'Telefone (com DDD)', hint: '11999998888', dark: _dark, keyboard: TextInputType.phone),
        AuthField(controller: _senha, label: 'Senha', hint: '********', dark: _dark, obscure: true),
        AuthField(controller: _confirma, label: 'Confirmação de senha', hint: '********', dark: _dark, obscure: true),
        if (_dark) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Localização', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Loja física')),
              ButtonSegment(value: false, label: Text('Loja online')),
            ],
            selected: {_lojaFisica},
            onSelectionChanged: (s) => setState(() => _lojaFisica = s.first),
          ),
          const SizedBox(height: 12),
          if (_lojaFisica)
            AuthField(controller: _rua, hint: 'Rua e número', dark: _dark),
        ],
        const SizedBox(height: 4),
        AuthError(_erro),
        AuthPrimaryButton(
          dark: _dark,
          label: _dark ? 'Criar seu brechó' : 'Cadastrar sua conta',
          onPressed: _cadastrar,
          loading: _loading,
        ),
      ],
    );
  }
}