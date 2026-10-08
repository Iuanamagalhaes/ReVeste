import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/product.dart';
import '../../models/store.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/net_image.dart';
import '../../widgets/product_grid.dart';
import '../store/store_view.dart';
import 'product_detail_screen.dart';

class FavoritesTab extends StatefulWidget {
  final AppUser usuario;
  const FavoritesTab({super.key, required this.usuario});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  final _fs = FirestoreService();
  late final _favProdutos = _fs.produtosFavoritos(widget.usuario.id);
  late final _favLojas = _fs.lojasFavoritas(widget.usuario.id);
  late final _produtos = _fs.produtos();
  late final _lojas = _fs.lojasAtivas();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: AppColors.verde,
              indicatorColor: AppColors.terracota,
              tabs: [Tab(text: 'Peças'), Tab(text: 'Brechós')],
            ),
            Expanded(
              child: TabBarView(children: [_pecas(), _brechos()]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pecas() => StreamBuilder<Set<String>>(
        stream: _favProdutos,
        builder: (context, fs) => StreamBuilder<List<Product>>(
          stream: _produtos,
          builder: (context, ps) {
            if (!ps.hasData || !fs.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final lista = ps.data!.where((p) => fs.data!.contains(p.id)).toList();
            return ProductGrid(
              usuario: widget.usuario,
              produtos: lista,
              vazio: 'Toque no coração de uma peça para salvá-la aqui.',
              onTap: (p) => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(usuario: widget.usuario, produto: p))),
            );
          },
        ),
      );

  Widget _brechos() => StreamBuilder<Set<String>>(
        stream: _favLojas,
        builder: (context, fs) => StreamBuilder<List<Store>>(
          stream: _lojas,
          builder: (context, ls) {
            if (!ls.hasData || !fs.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final lista = ls.data!.where((l) => fs.data!.contains(l.id)).toList();
            if (lista.isEmpty) {
              return const Center(child: Text('Você ainda não segue nenhum brechó.'));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final l in lista)
                  Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: Avatar(url: l.logoUrl, size: 44, icon: Icons.storefront),
                      title: Text(l.nome),
                      subtitle: Text(l.cidade.isEmpty ? l.bairro : '${l.bairro} · ${l.cidade}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              StoreProfileScreen(usuario: widget.usuario, storeId: l.id))),
                    ),
                  ),
              ],
            );
          },
        ),
      );
}
