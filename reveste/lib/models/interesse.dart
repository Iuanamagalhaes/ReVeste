import 'package:cloud_firestore/cloud_firestore.dart';

class InteresseItem {
  final String produtoId;
  final String nome;
  final int precoCentavos;
  final String? imagemUrl;

  const InteresseItem({
    required this.produtoId,
    required this.nome,
    required this.precoCentavos,
    this.imagemUrl,
  });
}

/// Documento da coleção `interests`: consumidor demonstrou interesse em peças.
class Interesse {
  final String id;
  final String consumidorId;
  final String storeId;
  final String canal;
  final String status; // contato_iniciado | atendido
  final List<InteresseItem> itens;
  final int totalCentavos;
  final DateTime? criadoEm;

  const Interesse({
    required this.id,
    required this.consumidorId,
    required this.storeId,
    required this.canal,
    required this.status,
    required this.itens,
    required this.totalCentavos,
    this.criadoEm,
  });

  factory Interesse.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final itens = (d['itens'] as List? ?? const []).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return InteresseItem(
        produtoId: m['produto_id'] ?? '',
        nome: m['nome'] ?? '',
        precoCentavos: ((m['preco'] ?? 0) as num).toInt(),
        imagemUrl: m['imagem_url'],
      );
    }).toList();
    final ts = d['criado_em'];
    return Interesse(
      id: doc.id,
      consumidorId: d['consumidor_id'] ?? '',
      storeId: d['store_id'] ?? '',
      canal: d['canal_contato'] ?? 'whatsapp',
      status: d['status'] ?? 'contato_iniciado',
      itens: itens,
      totalCentavos: ((d['total_estimado'] ?? 0) as num).toInt(),
      criadoEm: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
