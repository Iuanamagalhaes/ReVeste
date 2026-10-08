import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/estilos.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/form_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser usuario;
  const EditProfileScreen({super.key, required this.usuario});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _nome = TextEditingController(text: widget.usuario.nome);
  late final _tel = TextEditingController(text: widget.usuario.telefone ?? '');
  late final _cidade = TextEditingController(text: widget.usuario.cidade ?? '');
  late final _bairro = TextEditingController(text: widget.usuario.bairro ?? '');
  late final Set<String> _estilos = {...widget.usuario.estilos};
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    for (final c in [_nome, _tel, _cidade, _bairro]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nome.text.trim().isEmpty) {
      setState(() => _erro = 'Informe seu nome.');
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await FirestoreService().atualizarUsuario(widget.usuario.id, {
        'nome': _nome.text.trim(),
        'telefone': _tel.text.trim(),
        'regiao_manual': {'cidade': _cidade.text.trim(), 'bairro': _bairro.text.trim()},
        'estilos': _estilos.toList(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _erro = AuthService.mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus detalhes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FormInput(controller: _nome, label: 'Nome'),
          FormInput(controller: _tel, label: 'Telefone', keyboard: TextInputType.phone),
          FormInput(controller: _cidade, label: 'Cidade'),
          FormInput(controller: _bairro, label: 'Bairro'),
          const Text('Seus estilos', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in kEstilos)
                FilterChip(
                  label: Text(e),
                  selected: _estilos.contains(e.toLowerCase()),
                  showCheckmark: false,
                  selectedColor: AppColors.terracota,
                  backgroundColor: AppColors.creme,
                  side: BorderSide(
                      color: _estilos.contains(e.toLowerCase())
                          ? AppColors.terracota
                          : AppColors.verde),
                  labelStyle: TextStyle(
                      color: _estilos.contains(e.toLowerCase())
                          ? Colors.white
                          : AppColors.verde),
                  onSelected: (s) => setState(
                      () => s ? _estilos.add(e.toLowerCase()) : _estilos.remove(e.toLowerCase())),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AuthError(_erro),
          AuthPrimaryButton(
              dark: false, label: 'Salvar', onPressed: _salvar, loading: _salvando),
        ],
      ),
    );
  }
}
