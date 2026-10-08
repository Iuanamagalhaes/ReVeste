import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String storeId;
  final String lojaNome;
  final String nome;
  final String descricao;
  final String categoriaId;
  final String tamanho;
  final String condicao;
  final String cor;
  final String marca;
  final int precoCentavos; // 8990 = R$ 89,90
  final bool disponivel;
  final bool vendido;
  final List<String> imagens;

  Product({
    required this.id,
    required this.storeId,
    required this.lojaNome,
    required this.nome,
    required this.descricao,
    required this.categoriaId,
    required this.tamanho,
    required this.condicao,
    required this.cor,
    required this.marca,
    required this.precoCentavos,
    required this.disponivel,
    this.vendido = false,
    required this.imagens,
  });

  String? get imagemCapa => imagens.isNotEmpty ? imagens.first : null;

  /// Capa para copiar em pedidos/interesses: ignora fotos gravadas inline
  /// (data-URL) para não estourar o limite de 1 MB do documento.
  String? get imagemCapaLeve {
    final c = imagemCapa;
    return (c == null || c.startsWith('data:')) ? null : c;
  }

  String get precoFormatado =>
      'R\$ ${(precoCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Product(
      id: doc.id,
      storeId: d['store_id'] ?? '',
      lojaNome: d['loja_nome'] ?? '',
      nome: d['nome'] ?? '',
      descricao: d['descricao'] ?? '',
      categoriaId: d['categoria_id'] ?? '',
      tamanho: d['tamanho'] ?? '',
      condicao: d['condicao'] ?? '',
      cor: d['cor'] ?? '',
      marca: d['marca'] ?? '',
      precoCentavos: ((d['preco'] ?? 0) as num).toInt(),
      disponivel: d['disponivel'] ?? true,
      vendido: d['vendido'] ?? false,
      imagens: List<String>.from(d['imagens'] ?? const []),
    );
  }

  /// Usado no "Cadastrar peça" do painel do brechó.
  Map<String, dynamic> toMap() => {
        'id': id,
        'store_id': storeId,
        'loja_nome': lojaNome,
        'nome': nome,
        'descricao': descricao,
        'categoria_id': categoriaId,
        'tamanho': tamanho,
        'condicao': condicao,
        'cor': cor,
        'marca': marca,
        'preco': precoCentavos,
        'disponivel': disponivel,
        'vendido': vendido,
        'imagens': imagens,
        'criado_em': FieldValue.serverTimestamp(),
        'atualizado_em': FieldValue.serverTimestamp(),
      };
}

/// Filtros da home. Aplicados no app (client-side) para não exigir
/// índices compostos no Firestore, o que basta para o volume do protótipo.
class ProductFilter {
  final String? categoriaId;
  final Set<String> tamanhos;
  final Set<String> estilosDaLoja;
  final int? precoMinCentavos;
  final int? precoMaxCentavos;
  final String busca;

  const ProductFilter({
    this.categoriaId,
    this.tamanhos = const {},
    this.estilosDaLoja = const {},
    this.precoMinCentavos,
    this.precoMaxCentavos,
    this.busca = '',
  });

  bool get temFiltroAvancado =>
      tamanhos.isNotEmpty ||
      estilosDaLoja.isNotEmpty ||
      precoMinCentavos != null ||
      precoMaxCentavos != null;

  ProductFilter copyWith({
    Object? categoriaId = _manter,
    Set<String>? tamanhos,
    Set<String>? estilosDaLoja,
    Object? precoMinCentavos = _manter,
    Object? precoMaxCentavos = _manter,
    String? busca,
  }) =>
      ProductFilter(
        categoriaId: identical(categoriaId, _manter) ? this.categoriaId : categoriaId as String?,
        tamanhos: tamanhos ?? this.tamanhos,
        estilosDaLoja: estilosDaLoja ?? this.estilosDaLoja,
        precoMinCentavos:
            identical(precoMinCentavos, _manter) ? this.precoMinCentavos : precoMinCentavos as int?,
        precoMaxCentavos:
            identical(precoMaxCentavos, _manter) ? this.precoMaxCentavos : precoMaxCentavos as int?,
        busca: busca ?? this.busca,
      );

  bool matches(Product p, {Map<String, List<String>> estilosPorLoja = const {}}) {
    if (!p.disponivel) return false;
    if (categoriaId != null && p.categoriaId != categoriaId) return false;
    if (tamanhos.isNotEmpty && !tamanhos.contains(p.tamanho)) return false;
    if (precoMinCentavos != null && p.precoCentavos < precoMinCentavos!) return false;
    if (precoMaxCentavos != null && p.precoCentavos > precoMaxCentavos!) return false;
    if (estilosDaLoja.isNotEmpty) {
      final estilos = estilosPorLoja[p.storeId] ?? const [];
      if (!estilos.any(estilosDaLoja.contains)) return false;
    }
    if (busca.trim().isNotEmpty) {
      final q = busca.toLowerCase();
      final alvo = '${p.nome} ${p.marca} ${p.lojaNome} ${p.cor}'.toLowerCase();
      if (!alvo.contains(q)) return false;
    }
    return true;
  }
}

const Object _manter = Object();
