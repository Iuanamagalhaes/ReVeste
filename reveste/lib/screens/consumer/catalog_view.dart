import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/store.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../state/cart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_grid.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

/// Feed de peças usado na Início (com categorias) e na Pesquisa (com busca).
/// Filtros: categoria, estilo da loja, tamanho, faixa de preço e texto.
class CatalogView extends StatefulWidget {
  final AppUser usuario;
  final bool mostrarBusca;
  final bool mostrarCategorias;

  const CatalogView({
    super.key,
    required this.usuario,
    this.mostrarBusca = false,
    this.mostrarCategorias = true,
  });

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  final _fs = FirestoreService();
  late final Stream<List<Product>> _produtos = _fs.produtos();
  late final Stream<List<Store>> _lojas = _fs.lojasAtivas();
  late final Stream<List<Category>> _cats = _fs.categorias();
  final _busca = TextEditingController();
  ProductFilter _filtro = const ProductFilter();
  List<String> _estilosOpc = [];
  List<String> _tamanhosOpc = [];

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _abrirFiltros() async {
    final r = await showModalBottomSheet<ProductFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.creme,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) =>
          FilterSheet(inicial: _filtro, estilos: _estilosOpc, tamanhos: _tamanhosOpc),
    );
    if (r != null) setState(() => _filtro = r);
  }

  Widget _topo() {
    final botoes = [
      IconButton(
        onPressed: _abrirFiltros,
        icon: Badge(
          isLabelVisible: _filtro.temFiltroAvancado,
          smallSize: 8,
          child: const Icon(Icons.tune, color: AppColors.verde),
        ),
      ),
      ListenableBuilder(
        listenable: Cart.instance,
        builder: (context, _) => IconButton(
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CartScreen(usuario: widget.usuario))),
          icon: Badge(
            isLabelVisible: Cart.instance.quantidade > 0,
            label: Text('${Cart.instance.quantidade}'),
            child: const Icon(Icons.shopping_cart_outlined, color: AppColors.verde),
          ),
        ),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        children: [
          if (widget.mostrarBusca)
            Expanded(
              child: TextField(
                controller: _busca,
                onChanged: (v) => setState(() => _filtro = _filtro.copyWith(busca: v)),
                decoration: const InputDecoration(
                  hintText: 'Digite aqui...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            )
          else ...[
            Text('ReVeste',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: AppColors.verde)),
            const Spacer(),
          ],
          ...botoes,
        ],
      ),
    );
  }

  Widget _categorias() {
    return StreamBuilder<List<Category>>(
      stream: _cats,
      builder: (context, snap) {
        final cats = snap.data ?? const <Category>[];
        if (cats.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              _chip('Todos', _filtro.categoriaId == null,
                  () => setState(() => _filtro = _filtro.copyWith(categoriaId: null))),
              for (final c in cats)
                _chip(c.nome, _filtro.categoriaId == c.id,
                    () => setState(() => _filtro = _filtro.copyWith(categoriaId: c.id))),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: sel,
          showCheckmark: false,
          selectedColor: AppColors.terracota,
          backgroundColor: AppColors.creme,
          side: BorderSide(color: sel ? AppColors.terracota : AppColors.verde),
          labelStyle: TextStyle(color: sel ? Colors.white : AppColors.verde),
          onSelected: (_) => onTap(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _topo(),
          if (widget.mostrarCategorias) _categorias(),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _produtos,
              builder: (context, ps) {
                if (ps.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Não foi possível carregar as peças.\n${AuthService.mensagemDeErro(ps.error!)}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!ps.hasData) return const Center(child: CircularProgressIndicator());
                return StreamBuilder<List<Store>>(
                  stream: _lojas,
                  builder: (context, ls) {
                    final lojas = ls.data ?? const <Store>[];
                    final porLoja = {for (final l in lojas) l.id: l.estilos};
                    final todos = ps.data!;
                    _estilosOpc = ({for (final l in lojas) ...l.estilos}.toList()..sort());
                    _tamanhosOpc = ({
                      for (final p in todos)
                        if (p.tamanho.isNotEmpty) p.tamanho
                    }.toList()
                      ..sort());
                    final lista = todos
                        .where((p) => _filtro.matches(p, estilosPorLoja: porLoja))
                        .toList();
                    return ProductGrid(
                      usuario: widget.usuario,
                      produtos: lista,
                      onTap: (p) => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              ProductDetailScreen(usuario: widget.usuario, produto: p))),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FilterSheet extends StatefulWidget {
  final ProductFilter inicial;
  final List<String> estilos;
  final List<String> tamanhos;
  const FilterSheet(
      {super.key, required this.inicial, required this.estilos, required this.tamanhos});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late Set<String> _tam = {...widget.inicial.tamanhos};
  late Set<String> _est = {...widget.inicial.estilosDaLoja};
  late final _min = TextEditingController(
      text: widget.inicial.precoMinCentavos == null
          ? ''
          : '${widget.inicial.precoMinCentavos! ~/ 100}');
  late final _max = TextEditingController(
      text: widget.inicial.precoMaxCentavos == null
          ? ''
          : '${widget.inicial.precoMaxCentavos! ~/ 100}');

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  int? _centavos(String s) {
    final v = int.tryParse(s.replaceAll(RegExp(r'\D'), ''));
    return v == null ? null : v * 100;
  }

  Widget _grupo(String titulo, List<String> opcoes, Set<String> sel) {
    if (opcoes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in opcoes)
              FilterChip(
                label: Text(o),
                selected: sel.contains(o),
                showCheckmark: false,
                selectedColor: AppColors.terracota,
                backgroundColor: AppColors.creme,
                side: BorderSide(
                    color: sel.contains(o) ? AppColors.terracota : AppColors.verde),
                labelStyle: TextStyle(
                    color: sel.contains(o) ? Colors.white : AppColors.verde),
                onSelected: (s) => setState(() => s ? sel.add(o) : sel.remove(o)),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
            _grupo('Estilo', widget.estilos, _est),
            _grupo('Tamanho', widget.tamanhos, _tam),
            const SizedBox(height: 16),
            const Text('Preço (R\$)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _min,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'mínimo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _max,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'máximo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(
                        context,
                        ProductFilter(
                            categoriaId: widget.inicial.categoriaId,
                            busca: widget.inicial.busca)),
                    child: const Text('Limpar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(
                        context,
                        widget.inicial.copyWith(
                          tamanhos: _tam,
                          estilosDaLoja: _est,
                          precoMinCentavos: _centavos(_min.text),
                          precoMaxCentavos: _centavos(_max.text),
                        )),
                    child: const Text('Aplicar'),
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
