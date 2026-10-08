import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/estilos.dart';
import '../../models/store.dart';
import '../../services/firestore_service.dart';
import '../../services/image_upload_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/net_image.dart';

/// Editar perfil da loja. Logo e capa vão para o Storage; os LINKS ficam em
/// stores/{id}.logo_url / capa_url (e a logo também vira users/{dono}.foto_url).
class EditStoreScreen extends StatefulWidget {
  final AppUser usuario;
  final Store loja;
  const EditStoreScreen({super.key, required this.usuario, required this.loja});

  @override
  State<EditStoreScreen> createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  final _fs = FirestoreService();
  late final _nome = TextEditingController(text: widget.loja.nome);
  late final _descricao = TextEditingController(text: widget.loja.descricao);
  late final _whats = TextEditingController(text: widget.loja.whatsapp ?? '');
  late final _insta = TextEditingController(text: widget.loja.instagram ?? '');
  late final _horario = TextEditingController(text: widget.loja.horarioFuncionamento ?? '');
  late final _rua = TextEditingController(text: widget.loja.logradouro);
  late final _numero = TextEditingController(text: widget.loja.numero);
  late final _bairro = TextEditingController(text: widget.loja.bairro);
  late final _cidade = TextEditingController(text: widget.loja.cidade);
  late final _estado = TextEditingController(text: widget.loja.estado);
  late final Set<String> _estilos = {...widget.loja.estilos};
  late String _atendimento =
      const ['fisico', 'online', 'hibrido'].contains(widget.loja.tipoAtendimento)
          ? widget.loja.tipoAtendimento
          : 'fisico';
  PickedImg? _novoLogo;
  PickedImg? _novaCapa;
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    for (final c in [
      _nome, _descricao, _whats, _insta, _horario, _rua, _numero, _bairro, _cidade, _estado
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _escolher(bool logo) async {
    final img = await ImageUploadService.escolher();
    if (img == null || !mounted) return;
    setState(() => logo ? _novoLogo = img : _novaCapa = img);
  }

  Future<void> _salvar() async {
    if (_nome.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o nome da loja.');
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final id = widget.loja.id;
      var logo = widget.loja.logoUrl;
      var capa = widget.loja.capaUrl;
      if (_novoLogo != null) logo = await ImageUploadService.enviar(_novoLogo!, 'stores/$id');
      if (_novaCapa != null) capa = await ImageUploadService.enviar(_novaCapa!, 'stores/$id');
      await _fs.atualizarLoja(id, {
        'nome': _nome.text.trim(),
        'descricao': _descricao.text.trim(),
        'logo_url': logo,
        'capa_url': capa,
        'estilos': _estilos.toList(),
        'tipo_atendimento': _atendimento,
        'horario_funcionamento': _horario.text.trim(),
        'whatsapp': _whats.text.trim(),
        'instagram': _insta.text.trim(),
        'endereco': {
          'logradouro': _rua.text.trim(),
          'numero': _numero.text.trim(),
          'bairro': _bairro.text.trim(),
          'cidade': _cidade.text.trim(),
          'estado': _estado.text.trim(),
        },
      });
      if (_novoLogo != null && logo != null) {
        await _fs.atualizarUsuario(widget.loja.ownerId, {'foto_url': logo});
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _erro = ImageUploadService.mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _foto(String titulo, PickedImg? nova, String? atual, bool logo) {
    final Widget img = nova != null
        ? Image.memory(nova.bytes, fit: BoxFit.cover)
        : NetImage(url: atual, icon: logo ? Icons.storefront : Icons.image_outlined);
    return Column(
      children: [
        InkWell(
          onTap: () => _escolher(logo),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(logo ? 48 : 12),
            child: SizedBox(width: logo ? 96 : 200, height: 96, child: img),
          ),
        ),
        TextButton(onPressed: () => _escolher(logo), child: Text(titulo)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar loja')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _foto('Trocar logo', _novoLogo, widget.loja.logoUrl, true),
              _foto('Trocar capa', _novaCapa, widget.loja.capaUrl, false),
            ],
          ),
          const SizedBox(height: 12),
          FormInput(controller: _nome, label: 'Nome da loja'),
          FormInput(controller: _descricao, label: 'Descrição', maxLines: 3),
          FormInput(
              controller: _whats,
              label: 'WhatsApp (com DDD)',
              keyboard: TextInputType.phone),
          FormInput(controller: _insta, label: 'Instagram'),
          FormInput(controller: _horario, label: 'Horário de funcionamento'),
          FormDropdown(
            label: 'Atendimento',
            value: _atendimento,
            items: const [
              DropdownMenuItem(value: 'fisico', child: Text('Loja física')),
              DropdownMenuItem(value: 'online', child: Text('Loja online')),
              DropdownMenuItem(value: 'hibrido', child: Text('Física e online')),
            ],
            onChanged: (v) => setState(() => _atendimento = v ?? 'fisico'),
          ),
          if (_atendimento != 'online') ...[
            FormInput(controller: _rua, label: 'Rua'),
            FormInput(controller: _numero, label: 'Número'),
            FormInput(controller: _bairro, label: 'Bairro'),
            FormInput(controller: _cidade, label: 'Cidade'),
            FormInput(controller: _estado, label: 'Estado (UF)'),
          ],
          const Text('Estilos da loja', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in kEstilos)
                FilterChip(
                  label: Text(e),
                  selected: _estilos.contains(e.toLowerCase()),
                  showCheckmark: false,
                  selectedColor: AppColors.terracota,
                  backgroundColor: AppColors.creme,
                  side: BorderSide(
                      color: _estilos.contains(e.toLowerCase())
                          ? AppColors.terracota
                          : AppColors.verde),
                  labelStyle: TextStyle(
                      color: _estilos.contains(e.toLowerCase())
                          ? Colors.white
                          : AppColors.verde),
                  onSelected: (s) => setState(
                      () => s ? _estilos.add(e.toLowerCase()) : _estilos.remove(e.toLowerCase())),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AuthError(_erro),
          AuthPrimaryButton(
              dark: false, label: 'Salvar', onPressed: _salvar, loading: _salvando),
        ],
      ),
    );
  }
}
