import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'auth_service.dart';

/// Onde as imagens ficam guardadas. Em todos os casos o que vai para o
/// Firestore é uma STRING (campo foto_url / logo_url / imagens[]):
///
/// - auto (padrão): usa Cloudinary se você preencheu as chaves abaixo;
///   caso contrário usa firestoreInline. Funciona sem cartão e sem configurar nada.
/// - firestoreInline: a foto é reduzida (~800px) e gravada no próprio Firestore
///   como data-URL. Grátis e sem serviços externos, mas as fotos ficam pequenas.
/// - cloudinary: gratuito e sem cartão. Gera um LINK https de verdade, que é
///   gravado no Firestore. Basta criar conta, copiar o "cloud name" e criar um
///   "upload preset" do tipo UNSIGNED.
/// - firebaseStorage: exige o plano Blaze (cartão) desde fev/2026. Sem ele, o envio
///   nunca termina — foi isso que travava o app em "carregando".
enum ImageHost { auto, firestoreInline, cloudinary, firebaseStorage }

class ImageConfig {
  static const host = ImageHost.auto;

  // Só usados com Cloudinary (preencha para ter links https reais).
  static const cloudinaryCloudName = 'SEU_CLOUD_NAME';
  static const cloudinaryUploadPreset = 'SEU_UPLOAD_PRESET';

  /// Tempo máximo para qualquer envio: nada fica girando para sempre.
  static const timeout = Duration(seconds: 30);

  /// Limite por foto quando gravada no Firestore (documento aceita ~1 MB).
  static const maxBytesInline = 110 * 1024;

  static bool get cloudinaryConfigurado =>
      cloudinaryCloudName != 'SEU_CLOUD_NAME' &&
      cloudinaryUploadPreset != 'SEU_UPLOAD_PRESET';

  static ImageHost get efetivo {
    if (host != ImageHost.auto) return host;
    return cloudinaryConfigurado ? ImageHost.cloudinary : ImageHost.firestoreInline;
  }
}

/// Imagem escolhida pelo usuário, já em bytes (funciona no Chrome e no Android).
class PickedImg {
  final Uint8List bytes;
  final String name;
  const PickedImg(this.bytes, this.name);
}

class UploadException implements Exception {
  final String message;
  const UploadException(this.message);
}

class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();

  static bool get _inline => ImageConfig.efetivo == ImageHost.firestoreInline;
  static double get _largura => _inline ? 800 : 1400;
  static int get _qualidade => _inline ? 60 : 80;

  static Future<PickedImg?> escolher() async {
    final x = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: _largura, imageQuality: _qualidade);
    if (x == null) return null;
    return PickedImg(await x.readAsBytes(), x.name);
  }

  static Future<List<PickedImg>> escolherVarias({int limite = 5}) async {
    final xs = await _picker.pickMultiImage(maxWidth: _largura, imageQuality: _qualidade);
    final out = <PickedImg>[];
    for (final x in xs.take(limite)) {
      out.add(PickedImg(await x.readAsBytes(), x.name));
    }
    return out;
  }

  /// Envia a imagem e devolve o texto (link ou data-URL) que deve ser gravado
  /// no documento do Firestore. Sempre termina: ou devolve ou lança erro.
  static Future<String> enviar(PickedImg img, String pasta) async {
    final ext = _extensao(img.name);
    final nome = '${DateTime.now().microsecondsSinceEpoch}.$ext';
    switch (ImageConfig.efetivo) {
      case ImageHost.cloudinary:
        return _comTimeout(_enviarCloudinary(img.bytes, nome, pasta));
      case ImageHost.firebaseStorage:
        return _comTimeout(_enviarStorage(img.bytes, nome, ext, pasta));
      case ImageHost.firestoreInline:
      case ImageHost.auto:
        return _paraDataUrl(img.bytes, ext);
    }
  }

  static Future<String> _comTimeout(Future<String> f) => f.timeout(
        ImageConfig.timeout,
        onTimeout: () => throw const UploadException(
            'O envio da foto demorou demais e foi cancelado. Confira a internet e o serviço de imagens (veja o README).'),
      );

  static String _paraDataUrl(Uint8List bytes, String ext) {
    if (bytes.length > ImageConfig.maxBytesInline) {
      throw UploadException(
          'Essa foto ficou pesada demais (${(bytes.length / 1024).round()} KB). Escolha outra ou use uma foto menor.');
    }
    return 'data:${_mime(ext)};base64,${base64Encode(bytes)}';
  }

  static Future<String> _enviarStorage(
      Uint8List bytes, String nome, String ext, String pasta) async {
    final ref = FirebaseStorage.instance.ref('$pasta/$nome');
    await ref.putData(bytes, SettableMetadata(contentType: _mime(ext)));
    return ref.getDownloadURL();
  }

  static Future<String> _enviarCloudinary(
      Uint8List bytes, String nome, String pasta) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${ImageConfig.cloudinaryCloudName}/image/upload');
    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = ImageConfig.cloudinaryUploadPreset
      ..fields['folder'] = pasta
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: nome));
    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode != 200) {
      throw UploadException(
          'Cloudinary recusou o envio (${res.statusCode}). Confira o cloud name e o upload preset.');
    }
    return (jsonDecode(res.body) as Map<String, dynamic>)['secure_url'] as String;
  }

  static String _extensao(String nome) {
    final i = nome.lastIndexOf('.');
    final e = i == -1 ? '' : nome.substring(i + 1).toLowerCase();
    return const ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(e) ? e : 'jpg';
  }

  static String _mime(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  static String mensagemDeErro(Object e) {
    if (e is UploadException) return e.message;
    if (e is FirebaseException && e.plugin == 'firebase_storage') {
      switch (e.code) {
        case 'unauthorized':
          return 'Sem permissão no Storage. Confira as regras (firebase_rules/storage.rules).';
        case 'bucket-not-found':
        case 'project-not-found':
        case 'object-not-found':
          return 'O Storage não está ativo neste projeto (exige plano Blaze). Veja o README.';
        case 'quota-exceeded':
          return 'A cota do Storage acabou.';
      }
      return 'Falha ao enviar a imagem (${e.code}).';
    }
    return AuthService.mensagemDeErro(e);
  }
}
