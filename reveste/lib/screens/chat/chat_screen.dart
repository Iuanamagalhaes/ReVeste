import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/chat.dart';
import '../../models/product.dart';
import '../../models/store.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../services/image_upload_service.dart' show ImageUploadService;

String _dois(int n) => n.toString().padLeft(2, '0');

String _hora(DateTime? d) {
  if (d == null) return '';
  final agora = DateTime.now();
  final hoje = d.year == agora.year && d.month == agora.month && d.day == agora.day;
  return hoje ? '${_dois(d.hour)}:${_dois(d.minute)}' : '${_dois(d.day)}/${_dois(d.month)}';
}

/// Texto pronto de interesse, usado para preencher o campo de mensagem.
String textoDeInteresse(String lojaNome, List<Product> itens) {
  final lista = itens.map((p) => '• ${p.nome} (${p.precoFormatado})').join('\n');
  return 'Olá, $lojaNome! Vi no app ReVeste e tenho interesse em:\n$lista\n\nAinda estão disponíveis?';
}

/// Abre a conversa do consumidor com um brechó (cria ao enviar a 1ª mensagem).
/// [textoInicial] já aparece digitado, e o consumidor decide se envia.
Future<void> abrirChatComLoja(
  BuildContext context, {
  required AppUser usuario,
  Store? loja,
  String? storeId,
  String? textoInicial,
}) async {
  Store? l = loja;
  if (l == null && storeId != null) {
    try {
      l = await FirestoreService().loja(storeId).timeout(const Duration(seconds: 15));
    } catch (_) {
      l = null;
    }
  }
  if (!context.mounted) return;
  if (l == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Não encontramos esse brechó.')));
    return;
  }
  final Store alvo = l;
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => ChatScreen(
      usuario: usuario,
      consumidorId: usuario.id,
      consumidorNome: usuario.nome,
      storeId: alvo.id,
      lojaNome: alvo.nome,
      titulo: alvo.nome,
      textoInicial: textoInicial,
    ),
  ));
}

/// Conversa dentro do app entre consumidor e brechó.
class ChatScreen extends StatefulWidget {
  final AppUser usuario; // quem está usando o app agora
  final String consumidorId;
  final String consumidorNome;
  final String storeId;
  final String lojaNome;
  final String titulo; // nome da outra pessoa
  final String? textoInicial;

  const ChatScreen({
    super.key,
    required this.usuario,
    required this.consumidorId,
    required this.consumidorNome,
    required this.storeId,
    required this.lojaNome,
    required this.titulo,
    this.textoInicial,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _fs = FirestoreService();
  late final _ctrl = TextEditingController(text: widget.textoInicial ?? '');
  late final Stream<List<Mensagem>> _stream =
      _fs.mensagens(Conversa.idDe(widget.consumidorId, widget.storeId));
  bool _enviando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    try {
      await _fs.enviarMensagem(
        consumidorId: widget.consumidorId,
        consumidorNome: widget.consumidorNome,
        storeId: widget.storeId,
        lojaNome: widget.lojaNome,
        autorId: widget.usuario.id,
        texto: texto,
      );
      _ctrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ImageUploadService.mensagemDeErro(e))));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Mensagem>>(
              stream: _stream,
              builder: (context, s) {
                if (s.hasError) {
                  return const Center(child: Text('Não foi possível carregar a conversa.'));
                }
                if (!s.hasData) return const Center(child: CircularProgressIndicator());
                final msgs = s.data!;
                if (msgs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Nenhuma mensagem ainda. Diga olá! 👋',
                          textAlign: TextAlign.center),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[msgs.length - 1 - i];
                    return _Balao(msg: m, minha: m.autorId == widget.usuario.id);
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Escreva uma mensagem'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _enviando
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton.filled(
                          style: IconButton.styleFrom(backgroundColor: AppColors.verde),
                          onPressed: _enviar,
                          icon: const Icon(Icons.send, color: Colors.white),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Balao extends StatelessWidget {
  final Mensagem msg;
  final bool minha;
  const _Balao({required this.msg, required this.minha});

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width * 0.75;
    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: largura),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: minha ? AppColors.verde : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(minha ? 16 : 4),
            bottomRight: Radius.circular(minha ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(msg.texto,
                  style: TextStyle(color: minha ? Colors.white : AppColors.grafite)),
            ),
            const SizedBox(height: 2),
            Text(_hora(msg.criadoEm),
                style: TextStyle(
                    fontSize: 10, color: minha ? Colors.white70 : Colors.black45)),
          ],
        ),
      ),
    );
  }
}

/// Lista de conversas. [storeId] preenchido = visão do brechó; vazio = consumidor.
class ConversasLista extends StatefulWidget {
  final AppUser usuario;
  final String? storeId;
  const ConversasLista({super.key, required this.usuario, this.storeId});

  @override
  State<ConversasLista> createState() => _ConversasListaState();
}

class _ConversasListaState extends State<ConversasLista> {
  late final Stream<List<Conversa>> _stream = widget.storeId != null
      ? FirestoreService().conversasDaLoja(widget.storeId!)
      : FirestoreService().conversasDoConsumidor(widget.usuario.id);

  @override
  Widget build(BuildContext context) {
    final visaoLoja = widget.storeId != null;
    return StreamBuilder<List<Conversa>>(
      stream: _stream,
      builder: (context, s) {
        if (s.hasError) return const Center(child: Text('Não foi possível carregar.'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final l = s.data!;
        if (l.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                  visaoLoja
                      ? 'Nenhuma mensagem recebida ainda.'
                      : 'Você ainda não conversou com nenhum brechó.\nAbra uma peça e toque no ícone de conversa.',
                  textAlign: TextAlign.center),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: l.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final c = l[i];
            final nome = visaoLoja ? c.consumidorNome : c.lojaNome;
            final minha = c.ultimoAutorId == widget.usuario.id;
            return Card(
              margin: EdgeInsets.zero,
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.salvia,
                  child: Text(nome.isEmpty ? '?' : nome[0].toUpperCase(),
                      style: const TextStyle(color: AppColors.grafite)),
                ),
                title: Text(nome, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${minha ? 'Você: ' : ''}${c.ultimaMensagem}',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(_hora(c.atualizadoEm), style: const TextStyle(fontSize: 11)),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    usuario: widget.usuario,
                    consumidorId: c.consumidorId,
                    consumidorNome: c.consumidorNome,
                    storeId: c.storeId,
                    lojaNome: c.lojaNome,
                    titulo: nome,
                  ),
                )),
              ),
            );
          },
        );
      },
    );
  }
}

/// Tela do consumidor com todas as conversas.
class MensagensScreen extends StatelessWidget {
  final AppUser usuario;
  const MensagensScreen({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mensagens')),
        body: ConversasLista(usuario: usuario),
      );
}
