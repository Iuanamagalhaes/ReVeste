import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../home_router.dart';

/// Verificação REAL de e-mail: o Firebase envia um link de confirmação.
/// A tela confere sozinha a cada 3 s e avança assim que o link é aberto.
class VerificationScreen extends StatefulWidget {
  final AppUser usuario;

  /// true quando o e-mail acabou de ser enviado no cadastro.
  final bool emailJaEnviado;

  const VerificationScreen({super.key, required this.usuario, this.emailJaEnviado = true});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _auth = AuthService();
  Timer? _poll;
  Timer? _cooldown;
  int _espera = 0;
  bool _checando = false;
  String? _erro;
  String? _info;

  bool get _dark => widget.usuario.isBrecho;

  @override
  void initState() {
    super.initState();
    if (widget.emailJaEnviado) {
      _espera = 30;
      _iniciarContagem();
    } else {
      _reenviar();
    }
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _checar(silencioso: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _cooldown?.cancel();
    super.dispose();
  }

  void _iniciarContagem() {
    _cooldown?.cancel();
    _cooldown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _espera--);
      if (_espera <= 0) t.cancel();
    });
  }

  Future<void> _checar({bool silencioso = false}) async {
    if (_checando) return;
    _checando = true;
    if (!silencioso && mounted) setState(() => _erro = null);
    try {
      final ok = await _auth.emailVerificado();
      if (!mounted) return;
      if (ok) {
        _poll?.cancel();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => destinoPosLogin(widget.usuario)),
          (r) => false,
        );
      } else if (!silencioso) {
        setState(() => _erro =
            'Ainda não identificamos a confirmação. Abra o link do e-mail e tente de novo.');
      }
    } catch (e) {
      if (!silencioso && mounted) setState(() => _erro = AuthService.mensagemDeErro(e));
    } finally {
      _checando = false;
    }
  }

  Future<void> _reenviar() async {
    if (_espera > 0) return;
    try {
      await _auth.enviarVerificacao();
      if (!mounted) return;
      setState(() {
        _erro = null;
        _info = 'E-mail enviado para ${widget.usuario.email}.';
        _espera = 30;
      });
      _iniciarContagem();
    } catch (e) {
      if (mounted) setState(() => _erro = AuthService.mensagemDeErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = _dark ? Colors.white : AppColors.grafite;
    return AuthShell(
      dark: _dark,
      titulo: 'Confirme seu e-mail',
      children: [
        Icon(Icons.mark_email_unread_outlined,
            size: 56, color: _dark ? AppColors.terracota : AppColors.verde),
        const SizedBox(height: 16),
        Text(
          'Enviamos um link de confirmação para',
          textAlign: TextAlign.center,
          style: TextStyle(color: texto.withValues(alpha: 0.7), fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(widget.usuario.email,
            textAlign: TextAlign.center,
            style: TextStyle(color: texto, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'Abra o e-mail, toque no link e volte aqui: a tela avança sozinha. '
          'Não achou? Olhe a caixa de spam.',
          textAlign: TextAlign.center,
          style: TextStyle(color: texto.withValues(alpha: 0.7), fontSize: 13),
        ),
        const SizedBox(height: 20),
        if (_info != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_info!,
                textAlign: TextAlign.center,
                style: TextStyle(color: texto.withValues(alpha: 0.7), fontSize: 12)),
          ),
        AuthError(_erro),
        AuthPrimaryButton(dark: _dark, label: 'Já confirmei', onPressed: () => _checar()),
        TextButton(
          onPressed: _espera > 0 ? null : _reenviar,
          child: Text(_espera > 0 ? 'Reenviar e-mail em ${_espera}s' : 'Reenviar e-mail',
              style: TextStyle(color: _espera > 0 ? AppColors.salvia : AppColors.terracota)),
        ),
        TextButton(
          onPressed: () => sairDoApp(context),
          child: Text('Usar outra conta', style: TextStyle(color: texto.withValues(alpha: 0.7))),
        ),
      ],
    );
  }
}
