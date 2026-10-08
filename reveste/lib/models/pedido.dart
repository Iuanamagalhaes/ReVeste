import 'package:cloud_firestore/cloud_firestore.dart';

class PedidoItem {
  final String produtoId;
  final String nome;
  final int precoCentavos;
  final String? imagemUrl;
  const PedidoItem({
    required this.produtoId,
    required this.nome,
    required this.precoCentavos,
    this.imagemUrl,
  });
}

/// Status do pedido (coleção `orders`).
class StatusPedido {
  static const aguardandoPagamento = 'aguardando_pagamento'; // pagar na retirada
  static const pago = 'pago';
  static const emPreparo = 'em_preparo';
  static const pronto = 'pronto'; // pronto p/ retirada ou enviado
  static const concluido = 'concluido';
  static const cancelado = 'cancelado';

  static String rotulo(String s) {
    switch (s) {
      case aguardandoPagamento:
        return 'Pagar na retirada';
      case pago:
        return 'Pago';
      case emPreparo:
        return 'Em preparo';
      case pronto:
        return 'Pronto / enviado';
      case concluido:
        return 'Concluído';
      case cancelado:
        return 'Cancelado';
    }
    return s;
  }
}

class Pedido {
  final String id;
  final String consumidorId;
  final String consumidorNome;
  final String storeId;
  final String lojaNome;
  final List<PedidoItem> itens;
  final int totalCentavos;
  final String metodoPagamento; // pix | cartao | na_retirada
  final String entrega; // retirada | entrega
  final String? enderecoEntrega;
  final String status;
  final DateTime? criadoEm;

  const Pedido({
    required this.id,
    required this.consumidorId,
    required this.consumidorNome,
    required this.storeId,
    required this.lojaNome,
    required this.itens,
    required this.totalCentavos,
    required this.metodoPagamento,
    required this.entrega,
    this.enderecoEntrega,
    required this.status,
    this.criadoEm,
  });

  bool get emAndamento => status != StatusPedido.concluido && status != StatusPedido.cancelado;

  String get metodoRotulo {
    switch (metodoPagamento) {
      case 'pix':
        return 'Pix';
      case 'cartao':
        return 'Cartão de crédito';
      default:
        return 'Pagar na retirada';
    }
  }

  String get codigo => id.length > 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase();

  factory Pedido.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final itens = (d['itens'] as List? ?? const []).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return PedidoItem(
        produtoId: m['produto_id'] ?? '',
        nome: m['nome'] ?? '',
        precoCentavos: ((m['preco'] ?? 0) as num).toInt(),
        imagemUrl: m['imagem_url'],
      );
    }).toList();
    final ts = d['criado_em'];
    return Pedido(
      id: doc.id,
      consumidorId: d['consumidor_id'] ?? '',
      consumidorNome: d['consumidor_nome'] ?? 'Consumidor',
      storeId: d['store_id'] ?? '',
      lojaNome: d['loja_nome'] ?? 'Brechó',
      itens: itens,
      totalCentavos: ((d['total'] ?? 0) as num).toInt(),
      metodoPagamento: d['metodo_pagamento'] ?? 'pix',
      entrega: d['entrega'] ?? 'retirada',
      enderecoEntrega: d['endereco_entrega'],
      status: d['status'] ?? StatusPedido.pago,
      criadoEm: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
