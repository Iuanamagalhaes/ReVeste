import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'net_image.dart';

class ProductCard extends StatelessWidget {
  final Product produto;
  final bool favorito;
  final bool mostrarFavorito;
  final VoidCallback onTap;
  final VoidCallback? onFavorito;

  const ProductCard({
    super.key,
    required this.produto,
    required this.onTap,
    this.favorito = false,
    this.mostrarFavorito = true,
    this.onFavorito,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: produto.disponivel ? 1 : 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.expand(child: NetImage(url: produto.imagemCapa)),
              ),
            ),
            const SizedBox(height: 6),
            Text(produto.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(
              produto.disponivel
                  ? produto.lojaNome
                  : '${produto.lojaNome} · ${produto.vendido ? 'vendida' : 'indisponível'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: AppColors.grafite.withValues(alpha: 0.6)),
            ),
            Row(
              children: [
                Text(produto.precoFormatado,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.verde)),
                const Spacer(),
                if (mostrarFavorito)
                  InkWell(
                    onTap: onFavorito,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        favorito ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: favorito ? AppColors.terracota : AppColors.salvia,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Grade de peças. Já cuida do coração de favorito (grava em users/{uid}/favorite_products).
class ProductGrid extends StatefulWidget {
  final AppUser usuario;
  final List<Product> produtos;
  final void Function(Product)? onTap;
  final bool mostrarFavorito;
  final String vazio;

  const ProductGrid({
    super.key,
    required this.usuario,
    required this.produtos,
    required this.onTap,
    this.mostrarFavorito = true,
    this.vazio = 'Nenhuma peça encontrada.',
  });

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  final _fs = FirestoreService();
  late final Stream<Set<String>> _favs = _fs.produtosFavoritos(widget.usuario.id);

  @override
  Widget build(BuildContext context) {
    if (widget.produtos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(widget.vazio,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grafite.withValues(alpha: 0.6))),
        ),
      );
    }
    return StreamBuilder<Set<String>>(
      stream: _favs,
      builder: (context, snap) {
        final favs = snap.data ?? const <String>{};
        return LayoutBuilder(builder: (context, box) {
          final cols = (box.maxWidth / 190).floor().clamp(2, 6).toInt();
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: 0.62,
            ),
            itemCount: widget.produtos.length,
            itemBuilder: (context, i) {
              final p = widget.produtos[i];
              final fav = favs.contains(p.id);
              return ProductCard(
                produto: p,
                favorito: fav,
                mostrarFavorito: widget.mostrarFavorito,
                onTap: () => widget.onTap?.call(p),
                onFavorito: () => _fs.alternarFavoritoProduto(widget.usuario.id, p, !fav),
              );
            },
          );
        });
      },
    );
  }
}
