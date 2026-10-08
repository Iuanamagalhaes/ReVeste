import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/category.dart';
import '../../models/estilos.dart';
import '../../models/product.dart';
import '../../models/store.dart';
import '../../services/firestore_service.dart';
import '../../services/image_upload_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/net_image.dart';

/// Cadastrar (produto == null) ou editar uma peça. As fotos vão para o Storage
/// e os LINKS ficam em products/{id}.imagens.
class ProductFormScreen extends StatefulWidget {
  final AppUser usuario;
  final Store loja;
  final Product? produto;
  const ProductFormScreen({super.key, required this.usuario, required this.loja, this.produto});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  static const _maxFotos = 5;
  final _fs = FirestoreService();
  late final _nome = TextEditingController(text: widget.produto?.nome ?? '');
  late final _descricao = TextEditingController(text: widget.produto?.descricao ?? '');
  late final _cor = TextEditingController(text: widget.produto?.cor ?? '');
  late final _marca = TextEditingController(text: widget.produto?.marca ?? '');
  late final _preco = TextEditingController(
      text: widget.produto == null
          ? ''
          : (widget.produto!.precoCentavos / 100).toStringAsFixed(2).replaceAll('.', ','));
  late List<String> _urls = [...?widget.produto?.imagens];
  final List<PickedImg> _novas = [];
  List<Category> _cats = [];
  String? _categoria;
  String? _tamanho;
  String? _condicao;
  bool _disponivel = true;
  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.produto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produto;
    if (p != null) {
      _categoria = p.categoriaId.isEmpty ? null : p.categoriaId;
      _tamanho = p.tamanho.isEmpty ? null : p.tamanho;
      _condicao = p.condicao.isEmpty ? null : p.condicao;
      _disponivel = p.disponivel;
    }
    _fs.categorias().first.then((c) {
      if (mounted) setState(() => _cats = c);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    for (final c in [_nome, _descricao, _cor, _marca, _preco]) {
      c.dispose();
    }
    super.dispose();
  }

  List<DropdownMenuItem<String>> _itens(List<String> base, String? atual) {
    final todos = {...base, if (atual != null && atual.isNotEmpty) atual};
    return [for (final t in todos) DropdownMenuItem(value: t, child: Text(t))];
  }

  Future<void> _addFotos() async {
    final restante = _maxFotos - _urls.length - _novas.length;
    if (restante <= 0) return;
    final imgs = await ImageUploadService.escolherVarias(limite: restante);
    if (imgs.isNotEmpty && mounted) setState(() => _novas.addAll(imgs));
  }

  int? _centavos() {
    final t = _preco.text.replaceAll('R\$', '').trim().replaceAll('.', '').replaceAll(',', '.');
    final v = double.tryParse(t);
    return (v == null || v <= 0) ? null : (v * 100).round();
  }

  Future<void> _salvar() async {
    final centavos = _centavos();
    if (_nome.text.trim().isEmpty) return setState(() => _erro = 'Informe o nome da peça.');
    if (centavos == null) return setState(() => _erro = 'Informe um preço válido (ex: 89,90).');
    if (_categoria == null) return setState(() => _erro = 'Escolha uma categoria.');
    if (_tamanho == null) return setState(() => _erro = 'Escolha o tamanho.');
    if (_urls.isEmpty && _novas.isEmpty) {
      return setState(() => _erro = 'Adicione pelo menos uma foto.');
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final id = widget.produto?.id ?? _fs.novoIdProduto();
      final links = [..._urls];
      for (final img in _novas) {
        links.add(await ImageUploadService.enviar(img, 'products/$id'));
      }
      if (_editando) {
        await _fs.atualizarProduto(id, {
          'nome': _nome.text.trim(),
          'descricao': _descricao.text.trim(),
          'categoria_id': _categoria,
          'tamanho': _tamanho,
          'condicao': _condicao ?? '',
          'cor': _cor.text.trim(),
          'marca': _marca.text.trim(),
          'preco': centavos,
          'disponivel': _disponivel,
          if (_disponivel) 'vendido': false,
          'imagens': links,
        });
      } else {
        await _fs.cadastrarProduto(Product(
          id: id,
          storeId: widget.loja.id,
          lojaNome: widget.loja.nome,
          nome: _nome.text.trim(),
          descricao: _descricao.text.trim(),
          categoriaId: _categoria!,
          tamanho: _tamanho!,
          condicao: _condicao ?? '',
          cor: _cor.text.trim(),
          marca: _marca.text.trim(),
          precoCentavos: centavos,
          disponivel: true,
          imagens: links,
        ));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _erro = ImageUploadService.mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir peça?'),
        content: const Text('Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _fs.removerProduto(widget.produto!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _erro = ImageUploadService.mensagemDeErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalFotos = _urls.length + _novas.length;
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar peça' : 'Cadastrar peça')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Fotos', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _urls.length; i++)
                RemovableThumb(
                  child: NetImage(url: _urls[i]),
                  onRemove: () => setState(() => _urls.removeAt(i)),
                ),
              for (var i = 0; i < _novas.length; i++)
                RemovableThumb(
                  child: Image.memory(_novas[i].bytes, fit: BoxFit.cover),
                  onRemove: () => setState(() => _novas.removeAt(i)),
                ),
              if (totalFotos < _maxFotos)
                InkWell(
                  onTap: _addFotos,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.verde),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined, color: AppColors.verde),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FormInput(controller: _nome, label: 'Nome da peça'),
          FormInput(controller: _descricao, label: 'Descrição', maxLines: 3),
          FormDropdown(
            label: 'Categoria',
            value: _categoria,
            items: [
              for (final c in _cats) DropdownMenuItem(value: c.id, child: Text(c.nome)),
              if (_categoria != null && !_cats.any((c) => c.id == _categoria))
                DropdownMenuItem(value: _categoria, child: Text(_categoria!)),
            ],
            onChanged: (v) => setState(() => _categoria = v),
          ),
          FormDropdown(
            label: 'Tamanho',
            value: _tamanho,
            items: _itens(kTamanhos, _tamanho),
            onChanged: (v) => setState(() => _tamanho = v),
          ),
          FormDropdown(
            label: 'Condição',
            value: _condicao,
            items: _itens(kCondicoes, _condicao),
            onChanged: (v) => setState(() => _condicao = v),
          ),
          FormInput(controller: _cor, label: 'Cor'),
          FormInput(controller: _marca, label: 'Marca'),
          FormInput(
              controller: _preco,
              label: 'Preço (R\$)',
              hint: '89,90',
              keyboard: const TextInputType.numberWithOptions(decimal: true)),
          if (_editando)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Peça disponível'),
              value: _disponivel,
              activeThumbColor: AppColors.verde,
              onChanged: (v) => setState(() => _disponivel = v),
            ),
          const SizedBox(height: 8),
          AuthError(_erro),
          AuthPrimaryButton(
              dark: false,
              label: _editando ? 'Salvar alterações' : 'Publicar peça',
              onPressed: _salvar,
              loading: _salvando),
          if (_editando)
            TextButton(
              onPressed: _salvando ? null : _excluir,
              child: const Text('Excluir peça', style: TextStyle(color: AppColors.terracota)),
            ),
        ],
      ),
    );
  }
}
