import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_user.dart';
import '../../models/pedido.dart';
import '../../models/product.dart';
import '../../services/firestore_service.dart';
import '../../services/image_upload_service.dart' show ImageUploadService;
import '../../state/cart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/net_image.dart';
import '../chat/chat_screen.dart';
import 'meus_pedidos_screen.dart';

String _real(int centavos) => 'R\$ ${(centavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';

/// Compra dentro do app: entrega, forma de pagamento e confirmação.
/// ATENÇÃO: o pagamento é SIMULADO (projeto acadêmico). Nenhum dado de cartão
/// é enviado ou gravado; só o método escolhido fica no pedido.
class CheckoutScreen extends StatefulWidget {
  final AppUser usuario;
  final String storeId;
  final List<Product> itens;
  const CheckoutScreen(
      {super.key, required this.usuario, required this.storeId, required this.itens});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _fs = FirestoreService();
  final _endereco = TextEditingController();
  final _cartaoNome = TextEditingController();
  final _cartaoNumero = TextEditingController();
  final _cartaoValidade = TextEditingController();
  final _cartaoCvv = TextEditingController();
  String _entrega = 'retirada';
  String _pagamento = 'pix';
  bool _processando = false;
  String? _erro;

  int get _total => widget.itens.fold<int>(0, (s, p) => s + p.precoCentavos);
  String get _lojaNome => widget.itens.first.lojaNome;

  @override
  void dispose() {
    for (final c in [_endereco, _cartaoNome, _cartaoNumero, _cartaoValidade, _cartaoCvv]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validar() {
    if (_entrega == 'entrega' && _endereco.text.trim().length < 8) {
      return 'Informe o endereço de entrega completo.';
    }
    if (_pagamento == 'cartao') {
      final digitos = _cartaoNumero.text.replaceAll(RegExp(r'\D'), '');
      if (_cartaoNome.text.trim().isEmpty) return 'Informe o nome impresso no cartão.';
      if (digitos.length < 13) return 'Número do cartão inválido.';
      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(_cartaoValidade.text.trim())) {
        return 'Validade no formato MM/AA.';
      }
      if (_cartaoCvv.text.trim().length < 3) return 'CVV inválido.';
    }
    return null;
  }

  Future<bool> _dialogoPix() async {
    final codigo =
        '00020126REVESTE${DateTime.now().millisecondsSinceEpoch}${_total}BR5909REVESTE';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pagar com Pix'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valor: ${_real(_total)}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            const Text('Código Pix copia e cola (simulado):'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.creme, borderRadius: BorderRadius.circular(10)),
              child: SelectableText(codigo, style: const TextStyle(fontSize: 11)),
            ),
            TextButton.icon(
              onPressed: () => Clipboard.setData(ClipboardData(text: codigo)),
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copiar código'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Já paguei')),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _confirmar() async {
    final erro = _validar();
    if (erro != null) return setState(() => _erro = erro);
    if (_pagamento == 'pix' && !await _dialogoPix()) return;
    setState(() {
      _processando = true;
      _erro = null;
    });
    try {
      if (_pagamento == 'cartao') {
        await Future.delayed(const Duration(milliseconds: 1500)); // "operadora"
      }
      final id = await _fs.criarPedido(
        usuario: widget.usuario,
        storeId: widget.storeId,
        lojaNome: _lojaNome,
        itens: widget.itens,
        metodoPagamento: _pagamento,
        entrega: _entrega,
        enderecoEntrega: _entrega == 'entrega' ? _endereco.text.trim() : null,
      );
      Cart.instance.removerDaLoja(widget.storeId);
      await _avisarBrecho(id);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => PedidoConfirmadoScreen(
          usuario: widget.usuario,
          pedidoId: id,
          storeId: widget.storeId,
          lojaNome: _lojaNome,
        ),
      ));
    } on PecaIndisponivelException catch (e) {
      Cart.instance.remover(e.produtoId);
      if (mounted) {
        setState(() => _erro =
            '"${e.nome}" acabou de ser vendida e saiu do seu carrinho. Volte e revise a compra.');
      }
    } catch (e) {
      if (mounted) setState(() => _erro = ImageUploadService.mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  /// Mensagem automática no chat para o brechó ver o pedido (se falhar, o pedido
  /// já está salvo e aparece na aba Pedidos do brechó de qualquer forma).
  Future<void> _avisarBrecho(String pedidoId) async {
    try {
      final codigo = pedidoId.length > 6 ? pedidoId.substring(0, 6).toUpperCase() : pedidoId;
      final lista = widget.itens.map((p) => '• ${p.nome}').join('\n');
      final entrega = _entrega == 'entrega' ? 'entrega' : 'retirada na loja';
      await _fs.enviarMensagem(
        consumidorId: widget.usuario.id,
        consumidorNome: widget.usuario.nome,
        storeId: widget.storeId,
        lojaNome: _lojaNome,
        autorId: widget.usuario.id,
        texto: 'Fiz o pedido #$codigo ($entrega):\n$lista\nTotal: ${_real(_total)}',
      );
    } catch (_) {}
  }

  Widget _secao(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(t, style: Theme.of(context).textTheme.titleMedium),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar compra')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(_lojaNome, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final p in widget.itens)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(width: 52, height: 52, child: NetImage(url: p.imagemCapa)),
              ),
              title: Text(p.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('Tam. ${p.tamanho}'),
              trailing: Text(p.precoFormatado,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          const Divider(),
          _secao('Entrega'),
          _Opcao(
            icone: Icons.storefront_outlined,
            titulo: 'Retirar na loja',
            subtitulo: 'Sem custo. O brechó avisa quando estiver pronto.',
            selecionada: _entrega == 'retirada',
            onTap: () => setState(() => _entrega = 'retirada'),
          ),
          _Opcao(
            icone: Icons.local_shipping_outlined,
            titulo: 'Receber em casa',
            subtitulo: 'Frete combinado com o brechó pelo chat.',
            selecionada: _entrega == 'entrega',
            onTap: () => setState(() {
              _entrega = 'entrega';
              if (_pagamento == 'na_retirada') _pagamento = 'pix';
            }),
          ),
          if (_entrega == 'entrega') ...[
            const SizedBox(height: 8),
            FormInput(controller: _endereco, label: 'Endereço de entrega', maxLines: 2),
          ],
          _secao('Pagamento'),
          _Opcao(
            icone: Icons.pix,
            titulo: 'Pix',
            subtitulo: 'Pagamento na hora, gerado no app.',
            selecionada: _pagamento == 'pix',
            onTap: () => setState(() => _pagamento = 'pix'),
          ),
          _Opcao(
            icone: Icons.credit_card,
            titulo: 'Cartão de crédito',
            subtitulo: 'Ambiente de demonstração: nada é cobrado nem guardado.',
            selecionada: _pagamento == 'cartao',
            onTap: () => setState(() => _pagamento = 'cartao'),
          ),
          if (_entrega == 'retirada')
            _Opcao(
              icone: Icons.payments_outlined,
              titulo: 'Pagar na retirada',
              subtitulo: 'Você paga direto no brechó ao buscar a peça.',
              selecionada: _pagamento == 'na_retirada',
              onTap: () => setState(() => _pagamento = 'na_retirada'),
            ),
          if (_pagamento == 'cartao') ...[
            const SizedBox(height: 8),
            FormInput(controller: _cartaoNome, label: 'Nome no cartão'),
            FormInput(
                controller: _cartaoNumero,
                label: 'Número do cartão',
                keyboard: TextInputType.number),
            Row(
              children: [
                Expanded(
                    child: FormInput(
                        controller: _cartaoValidade,
                        label: 'Validade',
                        hint: 'MM/AA',
                        keyboard: TextInputType.datetime)),
                const SizedBox(width: 12),
                Expanded(
                    child: FormInput(
                        controller: _cartaoCvv,
                        label: 'CVV',
                        keyboard: TextInputType.number)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 16)),
              Text(_real(_total),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.verde)),
            ],
          ),
          const SizedBox(height: 12),
          AuthError(_erro),
          AuthPrimaryButton(
            dark: false,
            label: _pagamento == 'na_retirada'
                ? 'Confirmar pedido'
                : 'Pagar ${_real(_total)}',
            onPressed: _confirmar,
            loading: _processando,
          ),
        ],
      ),
    );
  }
}

class _Opcao extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final bool selecionada;
  final VoidCallback onTap;
  const _Opcao({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.selecionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: selecionada ? AppColors.verde : AppColors.salvia,
                  width: selecionada ? 2 : 1),
            ),
            child: Row(
              children: [
                Icon(icone, color: AppColors.verde),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(subtitulo, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Icon(selecionada ? Icons.check_circle : Icons.circle_outlined,
                    color: selecionada ? AppColors.verde : AppColors.salvia),
              ],
            ),
          ),
        ),
      );
}

class PedidoConfirmadoScreen extends StatelessWidget {
  final AppUser usuario;
  final String pedidoId;
  final String storeId;
  final String lojaNome;
  const PedidoConfirmadoScreen({
    super.key,
    required this.usuario,
    required this.pedidoId,
    required this.storeId,
    required this.lojaNome,
  });

  @override
  Widget build(BuildContext context) {
    final codigo = pedidoId.length > 6 ? pedidoId.substring(0, 6).toUpperCase() : pedidoId;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle, size: 88, color: AppColors.verde),
              const SizedBox(height: 16),
              Text('Pedido realizado!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Pedido #$codigo enviado para $lojaNome.\nAcompanhe o andamento em "Minhas compras".',
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => abrirChatComLoja(context, usuario: usuario, storeId: storeId),
                child: const Text('Falar com o brechó'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => MeusPedidosScreen(usuario: usuario))),
                child: const Text('Minhas compras'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
