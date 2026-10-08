import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/pedido.dart';
import '../screens/chat/chat_screen.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'net_image.dart';

String _real(int c) => 'R\$ ${(c / 100).toStringAsFixed(2).replaceAll('.', ',')}';
String _dois(int n) => n.toString().padLeft(2, '0');
String _data(DateTime? d) => d == null
    ? ''
    : '${_dois(d.day)}/${_dois(d.month)}/${d.year} ${_dois(d.hour)}:${_dois(d.minute)}';

/// Cartão de pedido. visaoLoja = true no painel do brechó (com ações de andamento).
class PedidoTile extends StatefulWidget {
  final Pedido pedido;
  final AppUser usuario;
  final bool visaoLoja;
  const PedidoTile(
      {super.key, required this.pedido, required this.usuario, required this.visaoLoja});

  @override
  State<PedidoTile> createState() => _PedidoTileState();
}

class _PedidoTileState extends State<PedidoTile> {
  final _fs = FirestoreService();
  bool _ocupado = false;

  Pedido get _p => widget.pedido;

  ({String label, String status})? get _proximo {
    switch (_p.status) {
      case StatusPedido.aguardandoPagamento:
      case StatusPedido.pago:
        return (label: 'Iniciar preparo', status: StatusPedido.emPreparo);
      case StatusPedido.emPreparo:
        return (
          label: _p.entrega == 'entrega' ? 'Marcar como enviado' : 'Pronto para retirada',
          status: StatusPedido.pronto
        );
      case StatusPedido.pronto:
        return (label: 'Concluir pedido', status: StatusPedido.concluido);
    }
    return null;
  }

  bool get _podeCancelar {
    if (widget.visaoLoja) return _p.emAndamento;
    return _p.status == StatusPedido.pago || _p.status == StatusPedido.aguardandoPagamento;
  }

  Future<void> _executar(Future<void> Function() acao) async {
    setState(() => _ocupado = true);
    try {
      await acao();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não deu para atualizar o pedido. Tente de novo.')));
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _cancelar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar pedido?'),
        content: const Text('As peças voltam para o catálogo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancelar pedido')),
        ],
      ),
    );
    if (ok == true) await _executar(() => _fs.cancelarPedido(_p));
  }

  void _conversar() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(
        usuario: widget.usuario,
        consumidorId: _p.consumidorId,
        consumidorNome: _p.consumidorNome,
        storeId: _p.storeId,
        lojaNome: _p.lojaNome,
        titulo: widget.visaoLoja ? _p.consumidorNome : _p.lojaNome,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    final cor = p.status == StatusPedido.cancelado
        ? Colors.grey
        : (p.status == StatusPedido.concluido ? AppColors.verde : AppColors.terracota);
    final prox = _proximo;
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
                  child: Text(widget.visaoLoja ? p.consumidorNome : p.lojaNome,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                Chip(
                  label: Text(StatusPedido.rotulo(p.status),
                      style: const TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: cor,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                ),
              ],
            ),
            Text('Pedido #${p.codigo} · ${_data(p.criadoEm)}',
                style: TextStyle(fontSize: 11, color: AppColors.grafite.withValues(alpha: 0.6))),
            const SizedBox(height: 8),
            for (final it in p.itens)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    if ((it.imagemUrl ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(width: 36, height: 36, child: NetImage(url: it.imagemUrl)),
                        ),
                      ),
                    Expanded(child: Text(it.nome, style: const TextStyle(fontSize: 13))),
                    Text(_real(it.precoCentavos), style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            const Divider(),
            Text('Total: ${_real(p.totalCentavos)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Pagamento: ${p.metodoRotulo}', style: const TextStyle(fontSize: 12)),
            Text(
                p.entrega == 'entrega'
                    ? 'Entrega em: ${p.enderecoEntrega ?? '-'}'
                    : 'Retirada na loja',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: _conversar,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Mensagem'),
                ),
                if (_podeCancelar)
                  TextButton(
                    onPressed: _ocupado ? null : _cancelar,
                    child: const Text('Cancelar', style: TextStyle(color: AppColors.terracota)),
                  ),
                if (widget.visaoLoja && prox != null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
                    onPressed: _ocupado
                        ? null
                        : () => _executar(() => _fs.atualizarStatusPedido(p.id, prox.status)),
                    child: Text(prox.label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de pedidos em tempo real (loja: storeId; consumidor: sem storeId).
class PedidosLista extends StatefulWidget {
  final AppUser usuario;
  final String? storeId;
  const PedidosLista({super.key, required this.usuario, this.storeId});

  @override
  State<PedidosLista> createState() => _PedidosListaState();
}

class _PedidosListaState extends State<PedidosLista> {
  late final Stream<List<Pedido>> _stream = widget.storeId != null
      ? FirestoreService().pedidosDaLoja(widget.storeId!)
      : FirestoreService().pedidosDoConsumidor(widget.usuario.id);

  @override
  Widget build(BuildContext context) {
    final visaoLoja = widget.storeId != null;
    return StreamBuilder<List<Pedido>>(
      stream: _stream,
      builder: (context, s) {
        if (s.hasError) return const Center(child: Text('Não foi possível carregar.'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final l = s.data!;
        if (l.isEmpty) {
          return Center(
              child: Text(visaoLoja ? 'Nenhuma venda ainda.' : 'Você ainda não comprou nada.'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final p in l)
              PedidoTile(pedido: p, usuario: widget.usuario, visaoLoja: visaoLoja),
          ],
        );
      },
    );
  }
}
