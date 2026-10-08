import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../services/image_upload_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/net_image.dart';
import '../home_router.dart';
import 'edit_profile_screen.dart';
import 'meus_pedidos_screen.dart';
import '../chat/chat_screen.dart';

class ProfileTab extends StatefulWidget {
  final AppUser usuario;
  const ProfileTab({super.key, required this.usuario});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _fs = FirestoreService();
  late final Stream<AppUser?> _stream = _fs.usuarioStream(widget.usuario.id);
  bool _enviando = false;

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  /// Escolhe a foto, envia para o Storage e grava o LINK em users/{uid}.foto_url.
  Future<void> _trocarFoto() async {
    final img = await ImageUploadService.escolher();
    if (img == null) return;
    setState(() => _enviando = true);
    try {
      final url = await ImageUploadService.enviar(img, 'users/${widget.usuario.id}');
      await _fs.atualizarUsuario(widget.usuario.id, {'foto_url': url});
      _msg('Foto atualizada!');
    } catch (e) {
      _msg(ImageUploadService.mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<AppUser?>(
        stream: _stream,
        builder: (context, s) {
          final u = s.data ?? widget.usuario;
          final regiao = [u.bairro, u.cidade].where((e) => (e ?? '').isNotEmpty).join(' · ');
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Stack(
                  children: [
                    Avatar(url: u.fotoUrl, size: 104),
                    if (_enviando)
                      const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: InkWell(
                        onTap: _enviando ? null : _trocarFoto,
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.terracota,
                          child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(u.nome, style: Theme.of(context).textTheme.titleLarge),
                Text(u.email,
                    style: TextStyle(color: AppColors.grafite.withValues(alpha: 0.6), fontSize: 12)),
                if (regiao.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(regiao, style: const TextStyle(fontSize: 12)),
                  ),
                if (u.estilos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [for (final e in u.estilos) Chip(label: Text(e))],
                  ),
                ],
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => EditProfileScreen(usuario: u))),
                  child: const Text('Meus detalhes'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => MeusPedidosScreen(usuario: u))),
                  child: const Text('Minhas compras'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => MensagensScreen(usuario: u))),
                  child: const Text('Mensagens'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => sairDoApp(context),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
