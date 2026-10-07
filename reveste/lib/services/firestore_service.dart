import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/store.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ---------- Leitura ----------
  Stream<List<Category>> categorias() => _db
      .collection('categories')
      .orderBy('ordem')
      .snapshots()
      .map((s) => s.docs.map(Category.fromDoc).toList());

  Stream<List<Store>> lojasAtivas() => _db
      .collection('stores')
      .where('ativa', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map(Store.fromDoc).toList());

  Future<Store?> loja(String id) async {
    final doc = await _db.collection('stores').doc(id).get();
    return doc.exists ? Store.fromDoc(doc) : null;
  }

  /// Todos os produtos (ou só de uma loja). Filtros finos ficam no ProductFilter.
  Stream<List<Product>> produtos({String? storeId}) {
    Query<Map<String, dynamic>> q = _db.collection('products');
    if (storeId != null) q = q.where('store_id', isEqualTo: storeId);
    return q.snapshots().map((s) => s.docs.map(Product.fromDoc).toList());
  }

  Future<Product?> produto(String id) async {
    final doc = await _db.collection('products').doc(id).get();
    return doc.exists ? Product.fromDoc(doc) : null;
  }

  // ---------- Usuário ----------
  Future<AppUser?> usuario(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? AppUser.fromDoc(doc) : null;
  }

  Future<void> salvarUsuario(AppUser u) =>
      _db.collection('users').doc(u.id).set(u.toMap(), SetOptions(merge: true));

  Future<void> salvarEstilos(String uid, List<String> estilos) =>
      _db.collection('users').doc(uid).update({'estilos': estilos});

  // ---------- Favoritos (subcoleções de users/{uid}) ----------
  Stream<Set<String>> produtosFavoritos(String uid) => _db
      .collection('users/$uid/favorite_products')
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toSet());

  Stream<Set<String>> lojasFavoritas(String uid) => _db
      .collection('users/$uid/favorite_stores')
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toSet());

  Future<void> alternarFavoritoProduto(String uid, Product p, bool favoritar) {
    final ref = _db.doc('users/$uid/favorite_products/${p.id}');
    return favoritar
        ? ref.set({
            'produto_id': p.id,
            'store_id': p.storeId,
            'criado_em': FieldValue.serverTimestamp(),
          })
        : ref.delete();
  }

  Future<void> alternarFavoritoLoja(String uid, String storeId, bool favoritar) {
    final ref = _db.doc('users/$uid/favorite_stores/$storeId');
    return favoritar
        ? ref.set({'store_id': storeId, 'criado_em': FieldValue.serverTimestamp()})
        : ref.delete();
  }

  // ---------- Lista de interesse / contato com o brechó ----------
  Future<String> criarInteresse({
    required String consumidorId,
    required String storeId,
    required List<Product> itens,
    String canalContato = 'whatsapp',
  }) async {
    final ref = _db.collection('interests').doc();
    await ref.set({
      'id': ref.id,
      'consumidor_id': consumidorId,
      'store_id': storeId,
      'canal_contato': canalContato,
      'status': 'contato_iniciado',
      'itens': itens
          .map((p) => {
                'produto_id': p.id,
                'nome': p.nome,
                'preco': p.precoCentavos,
                'imagem_url': p.imagemCapa,
              })
          .toList(),
      'total_estimado': itens.fold<int>(0, (s, p) => s + p.precoCentavos),
      'criado_em': FieldValue.serverTimestamp(),
      'enviado_em': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // ---------- Painel do brechó ----------
  Future<void> cadastrarProduto(Product p) =>
      _db.collection('products').doc(p.id).set(p.toMap());

  Future<void> alternarDisponibilidade(String productId, bool disponivel) => _db
      .collection('products')
      .doc(productId)
      .update({'disponivel': disponivel, 'atualizado_em': FieldValue.serverTimestamp()});

  Future<void> removerProduto(String productId) =>
      _db.collection('products').doc(productId).delete();
}