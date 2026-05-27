// lib/screens/pedidos_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});
  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> with SingleTickerProviderStateMixin {
  final _db = DatabaseService();
  List<Pedido> _pedidos = [];
  bool _loading = true;
  late TabController _tab;

  final _tabs = const [
    ('Todos', null),
    ('Pendente', StatusPedido.pendente),
    ('Preparando', StatusPedido.preparando),
    ('Pronto', StatusPedido.pronto),
    ('Entregue', StatusPedido.entregue),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final pedidos = await _db.getPedidos();
    setState(() { _pedidos = pedidos; _loading = false; });
  }

  List<Pedido> _filtered(StatusPedido? status) =>
      status == null ? _pedidos : _pedidos.where((p) => p.status == status).toList();

  Color _statusColor(StatusPedido s) {
    switch (s) {
      case StatusPedido.pendente:   return AppColors.warning;
      case StatusPedido.preparando: return AppColors.info;
      case StatusPedido.pronto:     return AppColors.success;
      case StatusPedido.entregue:   return AppColors.primary;
      case StatusPedido.cancelado:  return AppColors.error;
    }
  }

  Future<void> _updateStatus(Pedido p, StatusPedido newStatus) async {
    await _db.updatePedidoStatus(p.id, newStatus);
    await _load();
  }

  Future<void> _delete(Pedido p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmDialog(
        title: 'Cancelar pedido',
        content: 'Deseja cancelar este pedido? Ele será removido permanentemente.',
      ),
    );
    if (ok == true) {
      await _db.deletePedido(p.id);
      await _load();
    }
  }

  void _openNewPedido() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NovoPedidoForm(
        onSaved: (p) async {
          await _db.insertPedido(p);
          await _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedidos', style: theme.appBarTheme.titleTextStyle),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color,
          indicatorColor: AppColors.primary,
          labelStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewPedido,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo Pedido'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tab,
              children: _tabs.map((t) {
                final list = _filtered(t.$2);
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Nenhum pedido',
                    subtitle: t.$2 == null
                        ? 'Crie um novo pedido'
                        : 'Sem pedidos com status "${t.$1}"',
                  );
                }
                return RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _PedidoCard(
                      pedido: list[i],
                      statusColor: _statusColor(list[i].status),
                      onUpdateStatus: (s) => _updateStatus(list[i], s),
                      onDelete: () => _delete(list[i]),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final Color statusColor;
  final Function(StatusPedido) onUpdateStatus;
  final VoidCallback onDelete;

  const _PedidoCard({
    required this.pedido,
    required this.statusColor,
    required this.onUpdateStatus,
    required this.onDelete,
  });

  StatusPedido? _nextStatus(StatusPedido s) {
    switch (s) {
      case StatusPedido.pendente:   return StatusPedido.preparando;
      case StatusPedido.preparando: return StatusPedido.pronto;
      case StatusPedido.pronto:     return StatusPedido.entregue;
      default: return null;
    }
  }

  String _nextLabel(StatusPedido s) {
    switch (s) {
      case StatusPedido.pendente:   return 'Iniciar';
      case StatusPedido.preparando: return 'Pronto!';
      case StatusPedido.pronto:     return 'Entregar';
      default: return '';
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora mesmo';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextStatus = _nextStatus(pedido.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pedido.cliente, style: theme.textTheme.titleMedium),
                Text(_formatTime(pedido.criadoEm), style: theme.textTheme.bodyMedium),
              ],
            )),
            StatusBadge(label: pedido.status.label, color: statusColor),
          ]),
          const SizedBox(height: 10),
          // Itens
          ...pedido.itens.map((i) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Text('${i.quantidade}×',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(child: Text(i.nomeProduto,
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13))),
              Text('R\$ ${i.subtotal.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
            ]),
          )),
          // Observação
          if (pedido.observacao != null && pedido.observacao!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.notes_rounded, size: 14, color: AppColors.warning),
                const SizedBox(width: 6),
                Expanded(child: Text(pedido.observacao!,
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.warning))),
              ]),
            ),
          ],
          const Divider(height: 16),
          // Footer
          Row(children: [
            Text('Total: R\$ ${pedido.total.toStringAsFixed(2)}',
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 16)),
            const Spacer(),
            if (pedido.status != StatusPedido.entregue &&
                pedido.status != StatusPedido.cancelado)
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                label: const Text('Cancelar',
                  style: TextStyle(color: AppColors.error, fontSize: 12)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            if (nextStatus != null) ...[
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: () => onUpdateStatus(nextStatus),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                child: Text(_nextLabel(pedido.status)),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

// ─── Novo Pedido Form ───────────────────────────────────────────────────────

class _NovoPedidoForm extends StatefulWidget {
  final Function(Pedido) onSaved;
  const _NovoPedidoForm({required this.onSaved});
  @override
  State<_NovoPedidoForm> createState() => _NovoPedidoFormState();
}

class _NovoPedidoFormState extends State<_NovoPedidoForm> {
  final _db = DatabaseService();
  final _clienteCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  List<Produto> _produtos = [];
  final Map<Produto, int> _cart = {};
  bool _loadingProdutos = true;

  @override
  void initState() {
    super.initState();
    _db.getProdutos().then((p) => setState(() {
      _produtos = p;
      _loadingProdutos = false;
    }));
  }

  double get _total => _cart.entries.fold(0, (s, e) => s + e.key.preco * e.value);

  void _save() {
    if (_clienteCtrl.text.trim().isEmpty || _cart.isEmpty) return;
    final pedidoId = const Uuid().v4();
    final itens = _cart.entries.map((e) => ItemPedido(
      id: const Uuid().v4(),
      pedidoId: pedidoId,
      produtoId: e.key.id,
      nomeProduto: e.key.nome,
      quantidade: e.value,
      precoUnitario: e.key.preco,
    )).toList();
    final pedido = Pedido(
      id: pedidoId,
      cliente: _clienteCtrl.text.trim(),
      itens: itens,
      status: StatusPedido.pendente,
      criadoEm: DateTime.now(),
      observacao: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    );
    widget.onSaved(pedido);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header area
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Novo Pedido', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 16),
              TextField(controller: _clienteCtrl, decoration: const InputDecoration(
                labelText: 'Nome do cliente *',
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
              )),
              const SizedBox(height: 12),
              TextField(controller: _obsCtrl, decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                prefixIcon: Icon(Icons.notes_rounded, color: AppColors.primary),
              )),
              const SizedBox(height: 16),
              Text('Itens do Pedido', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
            ]),
          ),
          // Products list
          Expanded(
            child: _loadingProdutos
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _produtos.isEmpty
                ? const EmptyState(icon: Icons.lunch_dining_outlined,
                    title: 'Sem produtos', subtitle: 'Cadastre produtos no Cardápio primeiro')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _produtos.length,
                    itemBuilder: (_, i) {
                      final p = _produtos[i];
                      final qty = _cart[p] ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: qty > 0
                              ? AppColors.primary.withOpacity(0.08)
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: qty > 0
                                ? AppColors.primary.withOpacity(0.4)
                                : theme.dividerColor),
                        ),
                        child: Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.nome, style: theme.textTheme.titleMedium),
                              Text('R\$ ${p.preco.toStringAsFixed(2)}',
                                style: theme.textTheme.bodyMedium),
                            ],
                          )),
                          Row(children: [
                            if (qty > 0) ...[
                              GestureDetector(
                                onTap: () => setState(() {
                                  if (qty > 1) {
                                    _cart[p] = qty - 1;
                                  } else {
                                    _cart.remove(p);
                                  }
                                }),
                                child: Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.remove_rounded, size: 16, color: AppColors.error)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text('$qty',
                                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700,
                                    color: AppColors.primary, fontSize: 15))),
                            ],
                            GestureDetector(
                              onTap: () => setState(() => _cart[p] = qty + 1),
                              child: Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary)),
                            ),
                          ]),
                        ]),
                      );
                    },
                  ),
          ),
          // Bottom confirm bar
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20,
              MediaQuery.of(context).viewInsets.bottom + 20),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Total', style: theme.textTheme.bodyMedium),
                Text('R\$ ${_total.toStringAsFixed(2)}',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ]),
              const SizedBox(width: 16),
              Expanded(child: ElevatedButton(
                onPressed: (_cart.isEmpty || _clienteCtrl.text.trim().isEmpty)
                    ? null : _save,
                child: const Text('Confirmar Pedido'),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}
