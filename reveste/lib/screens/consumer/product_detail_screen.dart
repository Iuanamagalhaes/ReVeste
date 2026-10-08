import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/product.dart';
import '../../services/firestore_service.dart';
import '../../state/cart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/net_image.dart';
import '../chat/chat_screen.dart';
import '../store/store_view.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final AppUser usuario;
  final Product produto;
  const ProductDetailScreen({super.key, required this.usuario, required this.produto});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _fs = FirestoreService();
  late final Stream<Set<String>> _favs = _fs.produtosFavoritos(widget.usuario.id);
  int _foto = 0;
  bool _contatando = false;

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _falar() async {
    final p = widget.produto;
    setState(() => _contatando = true);
    await abrirChatComLoja(context,
        usuario: widget.usuario,
        storeId: p.storeId,
        textoInicial: textoDeInteresse(p.lojaNome, [p]));
    if (mounted) setState(() => _contatando = false);
  }

  void _comprar() {
    final p = widget.produto;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            CheckoutScreen(usuario: widget.usuario, storeId: p.storeId, itens: [p])));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.produto;
    final List<String?> fotos = p.imagens.isEmpty ? [null] : List<String?>.of(p.imagens);
    return Scaffold(
      appBar: AppBar(
        actions: [
          StreamBuilder<Set<String>>(
            stream: _favs,
            builder: (context, snap) {
              final fav = (snap.data ?? const <String>{}).contains(p.id);
              return IconButton(
                onPressed: () => _fs.alternarFavoritoProduto(widget.usuario.id, p, !fav),
                icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
                    color: AppColors.terracota),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: fotos.length,
                  onPageChanged: (i) => setState(() => _foto = i),
                  itemBuilder: (_, i) => NetImage(url: fotos[i]),
                ),
                if (fotos.length > 1)
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < fotos.length; i++)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _foto ? AppColors.terracota : Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nome, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(p.precoFormatado,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.verde)),
                if (!p.disponivel)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(p.vendido ? 'Esta peça já foi vendida' : 'Peça indisponível no momento',
                        style: TextStyle(color: AppColors.terracota)),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (p.tamanho.isNotEmpty) Chip(label: Text('Tam. ${p.tamanho}')),
                    if (p.condicao.isNotEmpty) Chip(label: Text(p.condicao)),
                    if (p.cor.isNotEmpty) Chip(label: Text(p.cor)),
                    if (p.marca.isNotEmpty) Chip(label: Text(p.marca)),
                  ],
                ),
                if (p.descricao.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(p.descricao),
                ],
                const SizedBox(height: 16),
                Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.storefront_outlined, color: AppColors.verde),
                    title: Text(p.lojaNome),
                    subtitle: const Text('Ver perfil do brechó'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            StoreProfileScreen(usuario: widget.usuario, storeId: p.storeId))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              IconButton.outlined(
                tooltip: 'Conversar com o brechó',
                onPressed: _contatando ? null : _falar,
                icon: const Icon(Icons.chat_bubble_outline, color: AppColors.verde),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ListenableBuilder(
                  listenable: Cart.instance,
                  builder: (context, _) {
                    final no = Cart.instance.contem(p.id);
                    return OutlinedButton(
                      onPressed: !p.disponivel
                          ? null
                          : () {
                              no ? Cart.instance.remover(p.id) : Cart.instance.adicionar(p);
                              _msg(no ? 'Removido do carrinho' : 'Adicionado ao carrinho');
                            },
                      child: Text(no ? 'No carrinho' : 'Ao carrinho'),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: p.disponivel ? _comprar : null,
                  child: const Text('Comprar agora'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
