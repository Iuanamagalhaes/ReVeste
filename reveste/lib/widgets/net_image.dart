import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Imagem da internet com placeholder (sem foto, carregando ou erro).
class NetImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final IconData icon;

  const NetImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.icon = Icons.checkroom,
  });

  /// Fotos gravadas direto no Firestore (data-URL): decodifica uma vez só.
  static final Map<String, Uint8List> _cache = {};

  Widget _placeholder() => Container(
        color: AppColors.salvia.withValues(alpha: 0.35),
        alignment: Alignment.center,
        child: Icon(icon, size: 36, color: AppColors.verde.withValues(alpha: 0.6)),
      );

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return _placeholder();
    if (u.startsWith('data:')) {
      try {
        final bytes = _cache.putIfAbsent(u, () => UriData.parse(u).contentAsBytes());
        return Image.memory(bytes,
            fit: fit, gaplessPlayback: true, errorBuilder: (c, e, s) => _placeholder());
      } catch (_) {
        return _placeholder();
      }
    }
    return Image.network(
      u,
      fit: fit,
      // No Chrome, evita erro de CORS ao exibir imagens do Storage.
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      loadingBuilder: (c, child, progress) => progress == null ? child : _placeholder(),
      errorBuilder: (c, e, s) => _placeholder(),
    );
  }
}

/// Foto redonda (perfil / logo).
class Avatar extends StatelessWidget {
  final String? url;
  final double size;
  final IconData icon;
  const Avatar({super.key, required this.url, this.size = 64, this.icon = Icons.person});

  @override
  Widget build(BuildContext context) => ClipOval(
        child: SizedBox(width: size, height: size, child: NetImage(url: url, icon: icon)),
      );
}
