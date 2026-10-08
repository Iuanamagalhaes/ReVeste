import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/product.dart';
import '../../state/cart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/net_image.dart';
import '../chat/chat_screen.dart';
import 'checkout_screen.dart';

/// Carrinho: um grupo por brechó. Cada grupo pode ser comprado e pago dentro do
/// app, ou virar uma conversa com o brechó.
class CartScreen extends StatelessWidget {
  final AppUser usuario;
  const CartScreen({super.key, required this.usuario});

  String _real(int centavos) =>
      'R\$ ${(centavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carrinho')),
      body: ListenableBuilder(
        listenable: Cart.instance,
        builder: (context, _) {
          final grupos = Cart.instance.porLoja;
          if (grupos.isEmpty) {
            return const Center(child: Text('Seu carrinho está vazio.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final e in grupos.entries) _grupo(context, e.key, e.value),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Cada brechó tem um pedido separado. O pagamento é uma simulação '
                  'para demonstração do app.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _grupo(BuildContext context, String storeId, List<Product> itens) {
    final total = itens.fold<int>(0, (s, p) => s + p.precoCentavos);
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(itens.first.lojaNome, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final p in itens)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(width: 56, height: 56, child: NetImage(url: p.imagemCapa)),
                ),
                title: Text(p.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(p.precoFormatado),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Cart.instance.remover(p.id),
                ),
              ),
            const Divider(),
            Text('Total: ${_real(total)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracota),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      CheckoutScreen(usuario: usuario, storeId: storeId, itens: itens))),
              icon: const Icon(Icons.lock_outline, size: 18),
              label: Text('Comprar e pagar · ${_real(total)}'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => abrirChatComLoja(context,
                  usuario: usuario,
                  storeId: storeId,
                  textoInicial: textoDeInteresse(itens.first.lojaNome, itens)),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Conversar com o brechó'),
            ),
          ],
        ),
      ),
    );
  }
}
