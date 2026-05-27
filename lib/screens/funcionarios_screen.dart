// lib/screens/funcionarios_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class FuncionariosScreen extends StatefulWidget {
  const FuncionariosScreen({super.key});
  @override
  State<FuncionariosScreen> createState() => _FuncionariosScreenState();
}

class _FuncionariosScreenState extends State<FuncionariosScreen> {
  final _db = DatabaseService();
  List<Funcionario> _funcionarios = [];
  List<Funcionario> _filtered = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _db.getFuncionarios(); // sorted A-Z
    setState(() { _funcionarios = items; _loading = false; _applyFilter(); });
  }

  void _applyFilter() {
    setState(() {
      _filtered = _funcionarios.where((f) =>
        f.nome.toLowerCase().contains(_search.toLowerCase()) ||
        f.cargo.toLowerCase().contains(_search.toLowerCase())
      ).toList();
    });
  }

  void _openForm([Funcionario? f]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FuncionarioForm(
        funcionario: f,
        onSaved: (fn) async {
          if (f == null) {
            await _db.insertFuncionario(fn);
          } else {
            await _db.updateFuncionario(fn);
          }
          await _load();
        },
      ),
    );
  }

  Future<void> _delete(Funcionario f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Remover funcionário',
        content: 'Deseja remover ${f.nome} da equipe?',
      ),
    );
    if (ok == true) {
      await _db.deleteFuncionario(f.id);
      await _load();
    }
  }

  Color _cargoColor(String cargo) {
    switch (cargo.toLowerCase()) {
      case 'gerente': return AppColors.primary;
      case 'cozinheiro': case 'cozinheira': return AppColors.accent;
      case 'atendente': return AppColors.info;
      case 'caixa': return AppColors.success;
      default: return AppColors.warning;
    }
  }

  String _initials(String nome) {
    final parts = nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return nome.substring(0, nome.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Equipe', style: theme.appBarTheme.titleTextStyle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) { _search = v; _applyFilter(); },
              decoration: const InputDecoration(
                hintText: 'Buscar funcionário...',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Novo Funcionário'),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(children: [
                  const Icon(Icons.sort_by_alpha_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('${_filtered.length} funcionário(s) • ordenado A–Z',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
                ]),
              ),
              Expanded(
                child: _filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline_rounded,
                      title: _search.isNotEmpty ? 'Nenhum resultado' : 'Equipe vazia',
                      subtitle: 'Adicione membros à sua equipe',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final f = _filtered[i];
                        final color = _cargoColor(f.cargo);
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
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(child: Text(_initials(f.nome),
                                  style: GoogleFonts.playfairDisplay(
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                    fontSize: 16,
                                  ))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(child: Text(f.nome, style: theme.textTheme.titleMedium)),
                                      StatusBadge(label: f.cargo, color: color),
                                    ]),
                                    const SizedBox(height: 2),
                                    Row(children: [
                                      Icon(Icons.phone_outlined, size: 12, color: theme.textTheme.bodyMedium?.color),
                                      const SizedBox(width: 4),
                                      Text(f.telefone, style: theme.textTheme.bodyMedium),
                                      const SizedBox(width: 12),
                                      Icon(Icons.email_outlined, size: 12, color: theme.textTheme.bodyMedium?.color),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text(f.email, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
                                    ]),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) { if (v == 'edit') {
                                  _openForm(f);
                                } else {
                                  _delete(f);
                                } },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Editar')])),
                                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.person_remove_outlined, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Remover', style: TextStyle(color: AppColors.error))])),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
    );
  }
}

class _FuncionarioForm extends StatefulWidget {
  final Funcionario? funcionario;
  final Function(Funcionario) onSaved;
  const _FuncionarioForm({this.funcionario, required this.onSaved});
  @override
  State<_FuncionarioForm> createState() => _FuncionarioFormState();
}

class _FuncionarioFormState extends State<_FuncionarioForm> {
  final _nomeCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _cargo = 'Atendente';
  static const cargos = ['Gerente', 'Cozinheiro', 'Cozinheira', 'Atendente', 'Caixa', 'Auxiliar', 'Entregador'];

  @override
  void initState() {
    super.initState();
    if (widget.funcionario != null) {
      _nomeCtrl.text = widget.funcionario!.nome;
      _telCtrl.text = widget.funcionario!.telefone;
      _emailCtrl.text = widget.funcionario!.email;
      _cargo = widget.funcionario!.cargo;
    }
  }

  void _save() {
    if (_nomeCtrl.text.isEmpty) return;
    final f = Funcionario(
      id: widget.funcionario?.id ?? const Uuid().v4(),
      nome: _nomeCtrl.text.trim(),
      cargo: _cargo,
      telefone: _telCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      admissaoEm: widget.funcionario?.admissaoEm ?? DateTime.now(),
    );
    widget.onSaved(f);
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
            Text(widget.funcionario == null ? 'Novo Funcionário' : 'Editar Funcionário',
              style: theme.textTheme.headlineMedium),
            const SizedBox(height: 20),
            TextField(controller: _nomeCtrl, decoration: const InputDecoration(labelText: 'Nome completo *', prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _cargo,
              decoration: const InputDecoration(labelText: 'Cargo', prefixIcon: Icon(Icons.work_outline_rounded, color: AppColors.primary)),
              onChanged: (v) => setState(() => _cargo = v!),
              items: cargos.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            ),
            const SizedBox(height: 12),
            TextField(controller: _telCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefone', prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary))),
            const SizedBox(height: 12),
            TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary))),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton(onPressed: _save, child: Text(widget.funcionario == null ? 'Adicionar' : 'Salvar'))),
            ]),
          ],
        ),
      ),
    );
  }
}
