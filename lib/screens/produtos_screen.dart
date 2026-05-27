// lib/screens/produtos_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});
  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  final _db = DatabaseService();
  List<Produto> _produtos = [];
  List<Produto> _filtered = [];
  bool _loading = true;
  String _search = '';
  String? _categoriaFilter;

  static const categorias = ['Lanches', 'Bebidas', 'Acompanhamentos', 'Sobremesas', 'Outros'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final produtos = await _db.getProdutos();
    setState(() {
      _produtos = produtos; // already sorted by name from DB
      _loading = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    setState(() {
      _filtered = _produtos.where((p) {
        final matchSearch = p.nome.toLowerCase().contains(_search.toLowerCase()) ||
            p.categoria.toLowerCase().contains(_search.toLowerCase());
        final matchCat = _categoriaFilter == null || p.categoria == _categoriaFilter;
        return matchSearch && matchCat;
      }).toList();
    });
  }

  void _openForm([Produto? produto]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProdutoForm(
        produto: produto,
        onSaved: (p) async {
          if (produto == null) {
            await _db.insertProduto(p);
          } else {
            await _db.updateProduto(p);
          }
          await _load();
        },
      ),
    );
  }

  Future<void> _delete(Produto p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Excluir produto',
        content: 'Deseja excluir "${p.nome}"? Esta ação não pode ser desfeita.',
      ),
    );
    if (ok == true) {
      await _db.deleteProduto(p.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${p.nome} excluído')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Cardápio', style: theme.appBarTheme.titleTextStyle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) { _search = v; _applyFilter(); },
                  decoration: const InputDecoration(
                    hintText: 'Buscar produto...',
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(label: 'Todos', selected: _categoriaFilter == null,
                        onTap: () { _categoriaFilter = null; _applyFilter(); }),
                      ...categorias.map((c) => _FilterChip(
                        label: c,
                        selected: _categoriaFilter == c,
                        onTap: () { _categoriaFilter = c; _applyFilter(); },
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo Produto'),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _filtered.isEmpty
          ? EmptyState(
              icon: Icons.lunch_dining_outlined,
              title: _search.isNotEmpty ? 'Nenhum resultado' : 'Cardápio vazio',
              subtitle: _search.isNotEmpty
                ? 'Tente outro termo de busca'
                : 'Adicione produtos ao seu cardápio',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _ProdutoCard(
                produto: _filtered[i],
                onEdit: () => _openForm(_filtered[i]),
                onDelete: () => _delete(_filtered[i]),
              ),
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(label,
          style: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? AppColors.lightText : Theme.of(context).textTheme.bodyMedium?.color,
          )),
      ),
    ),
  );
}

class _ProdutoCard extends StatelessWidget {
  final Produto produto;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ProdutoCard({required this.produto, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lunch_dining_rounded, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(produto.nome, style: theme.textTheme.titleMedium)),
                    StatusBadge(label: produto.categoria, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'R\$ ${produto.preco.toStringAsFixed(2)} • Estoque: ${produto.estoque} ${produto.unidade}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (produto.descricao != null && produto.descricao!.isNotEmpty)
                  Text(produto.descricao!, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) { if (v == 'edit') {
              onEdit();
            } else {
              onDelete();
            } },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Editar')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Excluir', style: TextStyle(color: AppColors.error))])),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProdutoForm extends StatefulWidget {
  final Produto? produto;
  final Function(Produto) onSaved;
  const _ProdutoForm({this.produto, required this.onSaved});

  @override
  State<_ProdutoForm> createState() => _ProdutoFormState();
}

class _ProdutoFormState extends State<_ProdutoForm> {
  final _nomeCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  final _estoqueCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _categoria = 'Lanches';
  String _unidade = 'un';

  static const categorias = ['Lanches', 'Bebidas', 'Acompanhamentos', 'Sobremesas', 'Outros'];
  static const unidades = ['un', 'kg', 'g', 'L', 'ml', 'pç', 'cx'];

  @override
  void initState() {
    super.initState();
    if (widget.produto != null) {
      _nomeCtrl.text = widget.produto!.nome;
      _precoCtrl.text = widget.produto!.preco.toString();
      _estoqueCtrl.text = widget.produto!.estoque.toString();
      _descCtrl.text = widget.produto!.descricao ?? '';
      _categoria = widget.produto!.categoria;
      _unidade = widget.produto!.unidade;
    }
  }

  void _save() {
    if (_nomeCtrl.text.isEmpty) return;
    final p = Produto(
      id: widget.produto?.id ?? const Uuid().v4(),
      nome: _nomeCtrl.text.trim(),
      categoria: _categoria,
      preco: double.tryParse(_precoCtrl.text) ?? 0,
      estoque: int.tryParse(_estoqueCtrl.text) ?? 0,
      unidade: _unidade,
      descricao: _descCtrl.text.isEmpty ? null : _descCtrl.text.trim(),
      criadoEm: widget.produto?.criadoEm ?? DateTime.now(),
    );
    widget.onSaved(p);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(widget.produto == null ? 'Novo Produto' : 'Editar Produto',
              style: theme.textTheme.headlineMedium),
            const SizedBox(height: 20),
            TextField(controller: _nomeCtrl, decoration: const InputDecoration(labelText: 'Nome do produto *')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _precoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Preço (R\$)', prefixText: 'R\$ '))),
              const SizedBox(width: 12),
              Expanded(child: Row(children: [
                Expanded(child: TextField(controller: _estoqueCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Estoque'))),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _unidade,
                  onChanged: (v) => setState(() => _unidade = v!),
                  items: unidades.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  underline: const SizedBox(),
                ),
              ])),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(labelText: 'Categoria'),
              onChanged: (v) => setState(() => _categoria = v!),
              items: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            ),
            const SizedBox(height: 12),
            TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Descrição (opcional)'), maxLines: 2),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton(onPressed: _save, child: Text(widget.produto == null ? 'Adicionar' : 'Salvar'))),
            ]),
          ],
        ),
      ),
    );
  }
}
