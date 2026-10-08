import 'package:flutter/foundation.dart';
import '../models/product.dart';

/// Carrinho / lista de interesse em memória (não precisa ir ao banco:
/// só vira documento em `interests` quando o consumidor fala com o brechó).
class Cart extends ChangeNotifier {
  Cart._();
  static final Cart instance = Cart._();

  final Map<String, Product> _itens = {};

  int get quantidade => _itens.length;
  bool contem(String id) => _itens.containsKey(id);

  /// Itens agrupados por brechó (storeId).
  Map<String, List<Product>> get porLoja {
    final m = <String, List<Product>>{};
    for (final p in _itens.values) {
      m.putIfAbsent(p.storeId, () => []).add(p);
    }
    return m;
  }

  void adicionar(Product p) {
    _itens[p.id] = p;
    notifyListeners();
  }

  void remover(String id) {
    _itens.remove(id);
    notifyListeners();
  }

  void removerDaLoja(String storeId) {
    _itens.removeWhere((_, p) => p.storeId == storeId);
    notifyListeners();
  }

  void limpar() {
    _itens.clear();
    notifyListeners();
  }
}
