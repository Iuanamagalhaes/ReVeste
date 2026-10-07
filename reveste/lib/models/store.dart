import 'package:cloud_firestore/cloud_firestore.dart';

class Store {
  final String id;
  final String nome;
  final String descricao;
  final String ownerId;
  final String? logoUrl;
  final String? capaUrl;
  final List<String> estilos;
  final String tipoAtendimento; // fisico, online, hibrido
  final String? horarioFuncionamento;
  final String? whatsapp;
  final String? instagram;
  final bool ativa;
  final bool verificada;
  final GeoPoint? localizacao;
  final String logradouro;
  final String numero;
  final String bairro;
  final String cidade;
  final String estado;

  Store({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.ownerId,
    this.logoUrl,
    this.capaUrl,
    this.estilos = const [],
    this.tipoAtendimento = 'fisico',
    this.horarioFuncionamento,
    this.whatsapp,
    this.instagram,
    this.ativa = true,
    this.verificada = false,
    this.localizacao,
    this.logradouro = '',
    this.numero = '',
    this.bairro = '',
    this.cidade = '',
    this.estado = '',
  });

  String get enderecoCurto => '$logradouro, $numero · $bairro';

  factory Store.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final e = (d['endereco'] ?? {}) as Map<String, dynamic>;
    return Store(
      id: doc.id,
      nome: d['nome'] ?? '',
      descricao: d['descricao'] ?? '',
      ownerId: d['owner_id'] ?? '',
      logoUrl: d['logo_url'],
      capaUrl: d['capa_url'],
      estilos: List<String>.from(d['estilos'] ?? const []),
      tipoAtendimento: d['tipo_atendimento'] ?? 'fisico',
      horarioFuncionamento: d['horario_funcionamento'],
      whatsapp: d['whatsapp'],
      instagram: d['instagram'],
      ativa: d['ativa'] ?? true,
      verificada: d['verificada'] ?? false,
      localizacao: d['localizacao'] is GeoPoint ? d['localizacao'] : null,
      logradouro: e['logradouro'] ?? '',
      numero: e['numero'] ?? '',
      bairro: e['bairro'] ?? '',
      cidade: e['cidade'] ?? '',
      estado: e['estado'] ?? '',
    );
  }
}