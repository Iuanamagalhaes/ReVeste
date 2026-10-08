import 'package:flutter/material.dart';
import '../models/interesse.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

/// Cartão de interesse. visaoLoja = true: mostra o consumidor (painel do brechó);
/// false: mostra a loja (histórico do consumidor).
class InteresseTile extends StatefulWidget {
  final Interesse interesse;
  final bool visaoLoja;
  const InteresseTile({super.key, required this.interesse, required this.visaoLoja});

  @override
  State<InteresseTile> createState() => _InteresseTileState();
}

class _InteresseTileState extends State<InteresseTile> {
  final _fs = FirestoreService();
  late final Future<String> _quem = _carregar();

  Future<String> _carregar() async {
    try {
      if (widget.visaoLoja) {
        final u = await _fs.usuario(widget.interesse.consumidorId);
        if (u == null) return 'Consumidor';
        final tel = (u.telefone ?? '').isEmpty ? '' : ' · ${u.telefone}';
        return '${u.nome}$tel';
      }
      final l = await _fs.loja(widget.interesse.storeId);
      return l?.nome ?? 'Brechó';
    } catch (_) {
      return widget.visaoLoja ? 'Consumidor' : 'Brechó';
    }
  }

  String _dois(int n) => n.toString().padLeft(2, '0');

  String _data(DateTime? d) => d == null
      ? ''
      : '${_dois(d.day)}/${_dois(d.month)}/${d.year} ${_dois(d.hour)}:${_dois(d.minute)}';

  @override
  Widget build(BuildContext context) {
    final i = widget.interesse;
    final atendido = i.status == 'atendido';
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: FutureBuilder<String>(
                    future: _quem,
                    builder: (context, s) => Text(s.data ?? '...',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                Chip(
                  label: Text(atendido ? 'Atendido' : 'Novo',
                      style: const TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: atendido ? AppColors.verde : AppColors.terracota,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                ),
              ],
            ),
            Text(_data(i.criadoEm),
                style: TextStyle(fontSize: 11, color: AppColors.grafite.withValues(alpha: 0.6))),
            const SizedBox(height: 8),
            for (final it in i.itens)
              Text('• ${it.nome} — R\$ ${(it.precoCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            Text('Total: R\$ ${(i.totalCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (widget.visaoLoja && !atendido)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _fs.atualizarStatusInteresse(i.id, 'atendido'),
                  child: const Text('Marcar como atendido'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
