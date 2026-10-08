import 'package:cloud_firestore/cloud_firestore.dart';

/// Conversa entre um consumidor e um brechó (coleção `chats`).
/// O id é sempre `${consumidorId}_${storeId}`: só existe uma conversa por par.
class Conversa {
  final String id;
  final String consumidorId;
  final String consumidorNome;
  final String storeId;
  final String lojaNome;
  final String ultimaMensagem;
  final String ultimoAutorId;
  final DateTime? atualizadoEm;

  const Conversa({
    required this.id,
    required this.consumidorId,
    required this.consumidorNome,
    required this.storeId,
    required this.lojaNome,
    required this.ultimaMensagem,
    required this.ultimoAutorId,
    this.atualizadoEm,
  });

  static String idDe(String consumidorId, String storeId) => '${consumidorId}_$storeId';

  factory Conversa.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['atualizado_em'];
    return Conversa(
      id: doc.id,
      consumidorId: d['consumidor_id'] ?? '',
      consumidorNome: d['consumidor_nome'] ?? 'Consumidor',
      storeId: d['store_id'] ?? '',
      lojaNome: d['loja_nome'] ?? 'Brechó',
      ultimaMensagem: d['ultima_mensagem'] ?? '',
      ultimoAutorId: d['ultimo_autor_id'] ?? '',
      atualizadoEm: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class Mensagem {
  final String id;
  final String autorId;
  final String texto;
  final DateTime? criadoEm;

  const Mensagem({
    required this.id,
    required this.autorId,
    required this.texto,
    this.criadoEm,
  });

  factory Mensagem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['criado_em'];
    return Mensagem(
      id: doc.id,
      autorId: d['autor_id'] ?? '',
      texto: d['texto'] ?? '',
      criadoEm: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
