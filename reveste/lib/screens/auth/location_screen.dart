import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../home_router.dart';

/// Região informada manualmente (usa_localizacao = false).
/// A localização por GPS fica para o CP6.
class LocationScreen extends StatefulWidget {
  final AppUser usuario;
  const LocationScreen({super.key, required this.usuario});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _cidade = TextEditingController(text: 'São Paulo');
  final _bairro = TextEditingController();
  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _cidade.dispose();
    _bairro.dispose();
    super.dispose();
  }

  Future<void> _concluir() async {
    if (_cidade.text.trim().isEmpty || _bairro.text.trim().isEmpty) {
      setState(() => _erro = 'Informe cidade e bairro.');
      return;
    }
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.usuario.id)
          .update({
        'regiao_manual': {
          'cidade': _cidade.text.trim(),
          'bairro': _bairro.text.trim(),
        },
        'usa_localizacao': false,
      });
      if (!mounted) return;
      irParaHome(context, widget.usuario);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não deu para salvar. Tente de novo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      dark: false,
      titulo: 'Onde você está?',
      children: [
        const Text(
          'Usamos sua região para mostrar os brechós mais perto de você.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.salvia, fontSize: 13),
        ),
        const SizedBox(height: 24),
        AuthField(controller: _cidade, label: 'Cidade', hint: 'São Paulo', dark: false),
        AuthField(controller: _bairro, label: 'Bairro', hint: 'Ex: Pinheiros', dark: false),
        AuthError(_erro),
        AuthPrimaryButton(
            dark: false, label: 'Concluir cadastro', onPressed: _concluir, loading: _loading),
      ],
    );
  }
}