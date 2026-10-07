import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String nome;
  final String email;
  final String tipoPerfil; // 'consumidor' ou 'brecho'
  final String? fotoUrl;
  final String? telefone;
  final String? cidade;
  final String? bairro;
  final bool usaLocalizacao;
  final List<String> estilos; // campo NOVO: preferências do onboarding

  AppUser({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipoPerfil,
    this.fotoUrl,
    this.telefone,
    this.cidade,
    this.bairro,
    this.usaLocalizacao = false,
    this.estilos = const [],
  });

  bool get isBrecho => tipoPerfil == 'brecho';

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final regiao = (d['regiao_manual'] ?? {}) as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      nome: d['nome'] ?? '',
      email: d['email'] ?? '',
      tipoPerfil: d['tipo_perfil'] ?? 'consumidor',
      fotoUrl: d['foto_url'],
      telefone: d['telefone'],
      cidade: regiao['cidade'],
      bairro: regiao['bairro'],
      usaLocalizacao: d['usa_localizacao'] ?? false,
      estilos: List<String>.from(d['estilos'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'email': email,
        'tipo_perfil': tipoPerfil,
        'foto_url': fotoUrl,
        'telefone': telefone,
        'regiao_manual': {'cidade': cidade, 'bairro': bairro},
        'usa_localizacao': usaLocalizacao,
        'estilos': estilos,
        'criado_em': FieldValue.serverTimestamp(),
      };
}
