import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/product.dart';
import '../../models/store.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/net_image.dart';
import '../../widgets/product_grid.dart';
import '../brecho/edit_store_screen.dart';
import '../brecho/product_form_screen.dart';
import '../chat/chat_screen.dart';
import '../consumer/product_detail_screen.dart';

/// Perfil público do brechó (visto pelo consumidor).
class StoreProfileScreen extends StatefulWidget {
  final AppUser usuario;
  final String storeId;
  const StoreProfileScreen({super.key, required this.usuario, required this.storeId});

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  late final Stream<Store?> _stream = FirestoreService().lojaStream(widget.storeId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: StreamBuilder<Store?>(
        stream: _stream,
        builder: (context, s) {
          if (s.hasError) return const Center(child: Text('Não foi possível carregar.'));
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final loja = s.data;
          if (loja == null) return const Center(child: Text('Brechó não encontrado.'));
          return StoreView(usuario: widget.usuario, loja: loja, editable: false);
        },
      ),
    );
  }
}

/// Cabeçalho do brechó + grade de peças. editable = true no painel do próprio brechó.
class StoreView extends StatefulWidget {
  final AppUser usuario;
  final Store loja;
  final bool editable;
  const StoreView({super.key, required this.usuario, required this.loja, required this.editable});

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  final _fs = FirestoreService();
  late final Stream<List<Product>> _produtos = _fs.produtos(storeId: widget.loja.id);
  late final Stream<Set<String>> _seguindo = _fs.lojasFavoritas(widget.usuario.id);

  String get _atendimento {
    switch (widget.loja.tipoAtendimento) {
      case 'online':
        return 'Loja online';
      case 'hibrido':
        return 'Loja física e online';
      default:
        return 'Loja física';
    }
  }

  String get _endereco => [
        widget.loja.logradouro,
        widget.loja.numero,
        widget.loja.bairro,
        widget.loja.cidade,
      ].where((e) => e.isNotEmpty).join(', ');

  Widget _acoes() {
    final l = widget.loja;
    if (widget.editable) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => EditStoreScreen(usuario: widget.usuario, loja: l))),
              child: const Text('Editar'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracota),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProductFormScreen(usuario: widget.usuario, loja: l))),
              child: const Text('+ Item'),
            ),
          ),
        ],
      );
    }
    return StreamBuilder<Set<String>>(
      stream: _seguindo,
      builder: (context, s) {
        final segue = (s.data ?? const <String>{}).contains(l.id);
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
                onPressed: () => _fs.alternarFavoritoLoja(widget.usuario.id, l.id, !segue),
                icon: Icon(segue ? Icons.favorite : Icons.favorite_border, size: 18),
                label: Text(segue ? 'Salvo' : 'Salvar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracota),
                onPressed: () =>
                    abrirChatComLoja(context, usuario: widget.usuario, loja: l),
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: const Text('Mensagem'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.loja;
    return Column(
      children: [
        Container(
          color: AppColors.grafite,
          child: Column(
            children: [
              SizedBox(
                height: 100,
                width: double.infinity,
                child: NetImage(url: l.capaUrl, icon: Icons.image_outlined),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Avatar(url: l.logoUrl, size: 60, icon: Icons.storefront),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.nome,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              Text(_atendimento,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              if (_endereco.isNotEmpty)
                                Text(_endereco,
                                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (l.descricao.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(l.descricao,
                          style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                    if (l.estilos.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final e in l.estilos)
                            Chip(
                              label: Text(e, style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: AppColors.salvia,
                              side: BorderSide.none,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    _acoes(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: _produtos,
            builder: (context, s) {
              if (s.hasError) {
                return Center(child: Text(AuthService.mensagemDeErro(s.error!)));
              }
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
              final lista =
                  s.data!.where((p) => widget.editable || p.disponivel).toList();
              return ProductGrid(
                usuario: widget.usuario,
                produtos: lista,
                mostrarFavorito: !widget.editable,
                vazio: widget.editable
                    ? 'Você ainda não cadastrou peças. Toque em "+ Item".'
                    : 'Este brechó ainda não tem peças disponíveis.',
                onTap: (p) => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => widget.editable
                      ? ProductFormScreen(usuario: widget.usuario, loja: l, produto: p)
                      : ProductDetailScreen(usuario: widget.usuario, produto: p),
                )),
              );
            },
          ),
        ),
      ],
    );
  }
}
