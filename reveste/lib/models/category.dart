import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String nome;
  final String icone;
  final int ordem;

  Category({required this.id, required this.nome, required this.icone, required this.ordem});

  factory Category.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Category(
      id: doc.id,
      nome: d['nome'] ?? '',
      icone: d['icone'] ?? '',
      ordem: (d['ordem'] ?? 0) as int,
    );
  }
}
