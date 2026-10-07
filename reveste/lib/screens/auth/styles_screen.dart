import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'location_screen.dart';

class StylesScreen extends StatefulWidget {
  final AppUser usuario;
  const StylesScreen({super.key, required this.usuario});

  @override
  State<StylesScreen> createState() => _StylesScreenState();
}

class _StylesScreenState extends State<StylesScreen> {
  static const _estilos = [
    'vintage', 'streetwear', 'Y2K', 'hippie', 'casual',
    'feminino', 'masculino', 'oversized', 'esportivo',
  ];
  final Set<String> _escolhidos = {};
  bool _loading = false;
  String? _erro;

  Future<void> _concluir() async {
    if (_escolhidos.isEmpty) {
      setState(() => _erro = 'Escolha pelo menos um estilo.');
      return;
    }
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      await FirestoreService().salvarEstilos(widget.usuario.id, _escolhidos.toList());
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LocationScreen(usuario: widget.usuario)),
        (r) => false,
      );
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não deu para salvar. Tente de novo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Seu estilo', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              const Text('Escolha o que combina com você.',
                  style: TextStyle(color: AppColors.salvia)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _estilos.map((e) {
                  final valor = e.toLowerCase();
                  final marcado = _escolhidos.contains(valor);
                  return FilterChip(
                    label: Text(e),
                    selected: marcado,
                    showCheckmark: false,
                    selectedColor: AppColors.terracota,
                    backgroundColor: AppColors.creme,
                    side: BorderSide(
                        color: marcado ? AppColors.terracota : AppColors.verde),
                    labelStyle: TextStyle(
                        color: marcado ? Colors.white : AppColors.verde),
                    onSelected: (s) => setState(() {
                      s ? _escolhidos.add(valor) : _escolhidos.remove(valor);
                    }),
                  );
                }).toList(),
              ),
              const Spacer(),
              if (_erro != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_erro!,
                        style: const TextStyle(color: AppColors.terracota)),
                  ),
                ),
              ElevatedButton(
                onPressed: _loading ? null : _concluir,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Concluir cadastro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}