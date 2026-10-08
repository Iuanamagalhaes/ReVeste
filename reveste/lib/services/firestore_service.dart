import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/category.dart';
import '../models/chat.dart';
import '../models/interesse.dart';
import '../models/pedido.dart';
import '../models/product.dart';
import '../models/store.dart';

/// Peça que deixou de estar disponível durante a compra.
class PecaIndisponivelException implements Exception {
  final String nome;
  final String produtoId;
  const PecaIndisponivelException(this.nome, this.produtoId);
}

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  /// Escritas no Firestore ficam pendentes para sempre se o banco não responde
  /// (sem internet, regras bloqueando...). Com o timeout o app mostra o erro
  /// em vez de ficar girando.
  static const _limite = Duration(seconds: 20);
  Future<T> _t<T>(Future<T> f) => f.timeout(_limite);

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
                'imagem_url': p.imagemCapaLeve,
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
      _t(_db.collection('products').doc(p.id).set(p.toMap()));

  Future<void> alternarDisponibilidade(String productId, bool disponivel) => _db
      .collection('products')
      .doc(productId)
      .update({'disponivel': disponivel, 'atualizado_em': FieldValue.serverTimestamp()});

  Future<void> removerProduto(String productId) =>
      _db.collection('products').doc(productId).delete();

  // ---------- Extras (CP5) ----------
  Stream<AppUser?> usuarioStream(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromDoc(d) : null);

  Stream<Store?> lojaStream(String id) => _db
      .collection('stores')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Store.fromDoc(d) : null);

  /// Loja cujo dono é o usuário (perfil brechó).
  Stream<Store?> lojaDoDono(String ownerId) => _db
      .collection('stores')
      .where('owner_id', isEqualTo: ownerId)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : Store.fromDoc(s.docs.first));

  Future<void> atualizarUsuario(String uid, Map<String, dynamic> dados) =>
      _t(_db.collection('users').doc(uid).update(dados));

  Future<void> atualizarLoja(String id, Map<String, dynamic> dados) => _t(_db
      .collection('stores')
      .doc(id)
      .update({...dados, 'atualizado_em': FieldValue.serverTimestamp()}));

  String novoIdProduto() => _db.collection('products').doc().id;

  Future<void> atualizarProduto(String id, Map<String, dynamic> dados) => _t(_db
      .collection('products')
      .doc(id)
      .update({...dados, 'atualizado_em': FieldValue.serverTimestamp()}));

  // Ordenação feita no app para não exigir índice composto.
  Stream<List<Interesse>> interessesDaLoja(String storeId) => _db
      .collection('interests')
      .where('store_id', isEqualTo: storeId)
      .snapshots()
      .map((s) => _ordenar(s.docs.map(Interesse.fromDoc).toList()));

  Stream<List<Interesse>> interessesDoConsumidor(String uid) => _db
      .collection('interests')
      .where('consumidor_id', isEqualTo: uid)
      .snapshots()
      .map((s) => _ordenar(s.docs.map(Interesse.fromDoc).toList()));

  List<Interesse> _ordenar(List<Interesse> l) {
    l.sort((a, b) => (b.criadoEm ?? DateTime.now()).compareTo(a.criadoEm ?? DateTime.now()));
    return l;
  }

  Future<void> atualizarStatusInteresse(String id, String status) =>
      _db.collection('interests').doc(id).update({'status': status});

  // ---------- Pedidos (compra dentro do app) ----------
  /// Cria o pedido e marca as peças como vendidas NA MESMA transação: se outra
  /// pessoa comprou a peça um segundo antes, a compra falha sem duplicar venda.
  Future<String> criarPedido({
    required AppUser usuario,
    required String storeId,
    required String lojaNome,
    required List<Product> itens,
    required String metodoPagamento, // pix | cartao | na_retirada
    required String entrega, // retirada | entrega
    String? enderecoEntrega,
  }) async {
    final ref = _db.collection('orders').doc();
    final total = itens.fold<int>(0, (s, p) => s + p.precoCentavos);
    await _db.runTransaction((tx) async {
      for (final p in itens) {
        final snap = await tx.get(_db.collection('products').doc(p.id));
        final ok = snap.exists && (snap.data()?['disponivel'] ?? true) == true;
        if (!ok) throw PecaIndisponivelException(p.nome, p.id);
      }
      for (final p in itens) {
        tx.update(_db.collection('products').doc(p.id), {
          'disponivel': false,
          'vendido': true,
          'comprador_id': usuario.id,
          'pedido_id': ref.id,
          'atualizado_em': FieldValue.serverTimestamp(),
        });
      }
      tx.set(ref, {
        'id': ref.id,
        'consumidor_id': usuario.id,
        'consumidor_nome': usuario.nome,
        'store_id': storeId,
        'loja_nome': lojaNome,
        'itens': itens
            .map((p) => {
                  'produto_id': p.id,
                  'nome': p.nome,
                  'preco': p.precoCentavos,
                  'imagem_url': p.imagemCapaLeve,
                })
            .toList(),
        'total': total,
        'metodo_pagamento': metodoPagamento,
        'pagamento_simulado': true,
        'entrega': entrega,
        'endereco_entrega': enderecoEntrega,
        'status': metodoPagamento == 'na_retirada'
            ? StatusPedido.aguardandoPagamento
            : StatusPedido.pago,
        'criado_em': FieldValue.serverTimestamp(),
        'atualizado_em': FieldValue.serverTimestamp(),
      });
    }).timeout(_limite);
    return ref.id;
  }

  Stream<List<Pedido>> pedidosDoConsumidor(String uid) => _db
      .collection('orders')
      .where('consumidor_id', isEqualTo: uid)
      .snapshots()
      .map((s) => _ordenarPedidos(s.docs.map(Pedido.fromDoc).toList()));

  Stream<List<Pedido>> pedidosDaLoja(String storeId) => _db
      .collection('orders')
      .where('store_id', isEqualTo: storeId)
      .snapshots()
      .map((s) => _ordenarPedidos(s.docs.map(Pedido.fromDoc).toList()));

  List<Pedido> _ordenarPedidos(List<Pedido> l) {
    final agora = DateTime.now();
    l.sort((a, b) => (b.criadoEm ?? agora).compareTo(a.criadoEm ?? agora));
    return l;
  }

  Future<void> atualizarStatusPedido(String id, String status) => _t(_db
      .collection('orders')
      .doc(id)
      .update({'status': status, 'atualizado_em': FieldValue.serverTimestamp()}));

  /// Cancela o pedido e devolve as peças para o catálogo.
  Future<void> cancelarPedido(Pedido p) {
    final batch = _db.batch();
    batch.update(_db.collection('orders').doc(p.id), {
      'status': StatusPedido.cancelado,
      'atualizado_em': FieldValue.serverTimestamp(),
    });
    for (final it in p.itens) {
      batch.update(_db.collection('products').doc(it.produtoId), {
        'disponivel': true,
        'vendido': false,
        'comprador_id': FieldValue.delete(),
        'pedido_id': FieldValue.delete(),
        'atualizado_em': FieldValue.serverTimestamp(),
      });
    }
    return _t(batch.commit());
  }

  // ---------- Mensagens (chat dentro do app) ----------
  Stream<List<Mensagem>> mensagens(String chatId) => _db
      .collection('chats/$chatId/messages')
      .orderBy('criado_em')
      .snapshots()
      .map((s) => s.docs.map(Mensagem.fromDoc).toList());

  Stream<List<Conversa>> conversasDoConsumidor(String uid) => _db
      .collection('chats')
      .where('consumidor_id', isEqualTo: uid)
      .snapshots()
      .map((s) => _ordenarConversas(s.docs.map(Conversa.fromDoc).toList()));

  Stream<List<Conversa>> conversasDaLoja(String storeId) => _db
      .collection('chats')
      .where('store_id', isEqualTo: storeId)
      .snapshots()
      .map((s) => _ordenarConversas(s.docs.map(Conversa.fromDoc).toList()));

  List<Conversa> _ordenarConversas(List<Conversa> l) {
    final agora = DateTime.now();
    l.sort((a, b) => (b.atualizadoEm ?? agora).compareTo(a.atualizadoEm ?? agora));
    return l;
  }

  /// Grava a mensagem e atualiza o resumo da conversa de uma vez só
  /// (a conversa é criada na primeira mensagem).
  Future<void> enviarMensagem({
    required String consumidorId,
    required String consumidorNome,
    required String storeId,
    required String lojaNome,
    required String autorId,
    required String texto,
  }) {
    final chatId = Conversa.idDe(consumidorId, storeId);
    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();
    final batch = _db.batch();
    batch.set(msgRef, {
      'autor_id': autorId,
      'texto': texto,
      'criado_em': FieldValue.serverTimestamp(),
    });
    batch.set(
        chatRef,
        {
          'id': chatId,
          'consumidor_id': consumidorId,
          'consumidor_nome': consumidorNome,
          'store_id': storeId,
          'loja_nome': lojaNome,
          'ultima_mensagem': texto,
          'ultimo_autor_id': autorId,
          'atualizado_em': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));
    return _t(batch.commit());
  }
}
