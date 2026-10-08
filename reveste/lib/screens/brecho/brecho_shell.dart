import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/store.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pedido_tile.dart';
import '../chat/chat_screen.dart';
import '../home_router.dart';
import '../store/store_view.dart';

/// Painel do brechó: Minha loja (peças), Pedidos (vendas) e Mensagens.
class BrechoShell extends StatefulWidget {
  final AppUser usuario;
  const BrechoShell({super.key, required this.usuario});

  @override
  State<BrechoShell> createState() => _BrechoShellState();
}

class _BrechoShellState extends State<BrechoShell> {
  late final Stream<Store?> _loja = FirestoreService().lojaDoDono(widget.usuario.id);
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ReVeste',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.verde)),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout, color: AppColors.verde),
            onPressed: () => sairDoApp(context),
          ),
        ],
      ),
      body: StreamBuilder<Store?>(
        stream: _loja,
        builder: (context, s) {
          if (s.hasError) {
            return const Center(child: Text('Não foi possível carregar sua loja.'));
          }
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final loja = s.data;
          if (loja == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Não encontramos uma loja ligada a esta conta.',
                    textAlign: TextAlign.center),
              ),
            );
          }
          return IndexedStack(
            index: _i,
            children: [
              StoreView(usuario: widget.usuario, loja: loja, editable: true),
              PedidosLista(usuario: widget.usuario, storeId: loja.id),
              ConversasLista(usuario: widget.usuario, storeId: loja.id),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.creme,
        indicatorColor: AppColors.salvia.withValues(alpha: 0.4),
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Minha loja'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Pedidos'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Mensagens'),
        ],
      ),
    );
  }
}
