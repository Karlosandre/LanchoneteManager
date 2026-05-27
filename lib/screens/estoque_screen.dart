// lib/screens/estoque_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});
  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  final _db = DatabaseService();
  List<Ingrediente> _ingredientes = [];
  List<Ingrediente> _filtered = [];
  bool _loading = true;
  bool _showLowOnly = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _db.getIngredientes(); // already sorted A-Z by DB
    setState(() { _ingredientes = items; _loading = false; _applyFilter(); });
  }

  void _applyFilter() {
    setState(() {
      _filtered = _ingredientes.where((i) {
        final matchSearch = i.nome.toLowerCase().contains(_search.toLowerCase());
        final matchLow = !_showLowOnly || i.estoqueBaixo;
        return matchSearch && matchLow;
      }).toList();
    });
  }

  void _openForm([Ingrediente? ingrediente]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IngredienteForm(
        ingrediente: ingrediente,
        onSaved: (i) async {
          if (ingrediente == null) {
            await _db.insertIngrediente(i);
          } else {
            await _db.updateIngrediente(i);
          }
          await _load();
        },
      ),
    );
  }

  Future<void> _delete(Ingrediente i) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Remover ingrediente',
        content: 'Deseja remover "${i.nome}" do estoque?',
      ),
    );
    if (ok == true) {
      await _db.deleteIngrediente(i.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowCount = _ingredientes.where((i) => i.estoqueBaixo).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Estoque', style: theme.appBarTheme.titleTextStyle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) { _search = v; _applyFilter(); },
              decoration: const InputDecoration(
                hintText: 'Buscar ingrediente...',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo Ingrediente'),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : Column(
            children: [
              if (lowCount > 0)
                GestureDetector(
                  onTap: () { _showLowOnly = !_showLowOnly; _applyFilter(); },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_showLowOnly ? AppColors.error : AppColors.error.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                          color: _showLowOnly ? Colors.white : AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          '$lowCount ingrediente(s) com estoque baixo — toque para filtrar',
                          style: GoogleFonts.dmSans(
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: _showLowOnly ? Colors.white : AppColors.error,
                          ),
                        )),
                        if (_showLowOnly) const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(children: [
                  const Icon(Icons.sort_by_alpha_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('Ordenado A–Z (${_filtered.length} itens)',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
                ]),
              ),
              Expanded(
                child: _filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: _search.isNotEmpty ? 'Nenhum resultado' : 'Estoque vazio',
                      subtitle: 'Adicione ingredientes para controlar o estoque',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final item = _filtered[i];
                        final pct = (item.quantidade / (item.quantidadeMinima * 3)).clamp(0.0, 1.0);
                        return _IngredienteCard(
                          ingrediente: item,
                          pct: pct,
                          onEdit: () => _openForm(item),
                          onDelete: () => _delete(item),
                        );
                      },
                    ),
              ),
            ],
          ),
    );
  }
}

class _IngredienteCard extends StatelessWidget {
  final Ingrediente ingrediente;
  final double pct;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _IngredienteCard({required this.ingrediente, required this.pct, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final low = ingrediente.estoqueBaixo;
    final color = low ? AppColors.error : pct < 0.5 ? AppColors.warning : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: low ? AppColors.error.withOpacity(0.4) : theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(low ? Icons.warning_amber_rounded : Icons.inventory_2_rounded,
                  color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ingrediente.nome, style: theme.textTheme.titleMedium),
                  Text('${ingrediente.quantidade} ${ingrediente.unidade} disponível',
                    style: theme.textTheme.bodyMedium),
                ],
              )),
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
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            )),
            const SizedBox(width: 10),
            Text('Mín: ${ingrediente.quantidadeMinima} ${ingrediente.unidade}',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
          ]),
          if (low) ...[
            const SizedBox(height: 6),
            Text('⚠ Estoque abaixo do mínimo — solicite reposição',
              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}

class _IngredienteForm extends StatefulWidget {
  final Ingrediente? ingrediente;
  final Function(Ingrediente) onSaved;
  const _IngredienteForm({this.ingrediente, required this.onSaved});
  @override
  State<_IngredienteForm> createState() => _IngredienteFormState();
}

class _IngredienteFormState extends State<_IngredienteForm> {
  final _nomeCtrl = TextEditingController();
  final _qtdCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _custoCtrl = TextEditingController();
  String _unidade = 'kg';
  static const unidades = ['kg', 'g', 'L', 'ml', 'un', 'pç', 'cx', 'sc'];

  @override
  void initState() {
    super.initState();
    if (widget.ingrediente != null) {
      _nomeCtrl.text = widget.ingrediente!.nome;
      _qtdCtrl.text = widget.ingrediente!.quantidade.toString();
      _minCtrl.text = widget.ingrediente!.quantidadeMinima.toString();
      _custoCtrl.text = widget.ingrediente!.custoUnitario.toString();
      _unidade = widget.ingrediente!.unidade;
    }
  }

  void _save() {
    if (_nomeCtrl.text.isEmpty) return;
    final i = Ingrediente(
      id: widget.ingrediente?.id ?? const Uuid().v4(),
      nome: _nomeCtrl.text.trim(),
      quantidade: double.tryParse(_qtdCtrl.text) ?? 0,
      unidade: _unidade,
      quantidadeMinima: double.tryParse(_minCtrl.text) ?? 0,
      custoUnitario: double.tryParse(_custoCtrl.text) ?? 0,
      atualizadoEm: DateTime.now(),
    );
    widget.onSaved(i);
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
            Text(widget.ingrediente == null ? 'Novo Ingrediente' : 'Editar Ingrediente',
              style: theme.textTheme.headlineMedium),
            const SizedBox(height: 20),
            TextField(controller: _nomeCtrl, decoration: const InputDecoration(labelText: 'Nome do ingrediente *')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _qtdCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Quantidade atual'))),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _unidade,
                onChanged: (v) => setState(() => _unidade = v!),
                items: unidades.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                underline: const SizedBox(),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _minCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Qtd. mínima'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _custoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Custo/unidade', prefixText: 'R\$ '))),
            ]),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton(onPressed: _save, child: Text(widget.ingrediente == null ? 'Adicionar' : 'Salvar'))),
            ]),
          ],
        ),
      ),
    );
  }
}
