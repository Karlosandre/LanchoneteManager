// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/common_widgets.dart';
import '../models/models.dart';
import 'pedidos_screen.dart';
import 'produtos_screen.dart';
import 'estoque_screen.dart';
import 'funcionarios_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final _screens = [
    const DashboardScreen(),
    const PedidosScreen(),
    const ProdutosScreen(),
    const EstoqueScreen(),
    const FuncionariosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Pedidos'),
          NavigationDestination(icon: Icon(Icons.lunch_dining_outlined), selectedIcon: Icon(Icons.lunch_dining_rounded), label: 'Cardápio'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_rounded), label: 'Estoque'),
          NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Equipe'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DatabaseService();
  Map<String, dynamic> _stats = {};
  List<Pedido> _recentPedidos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await _db.getDashboardStats();
    final pedidos = await _db.getPedidos();
    setState(() {
      _stats = stats;
      _recentPedidos = pedidos.take(5).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(size: 32),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: AppColors.primary),
            onPressed: themeProvider.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => const ConfirmDialog(
                  title: 'Sair',
                  content: 'Deseja realmente sair do sistema?',
                  confirmLabel: 'Sair',
                  confirmColor: AppColors.primary,
                ),
              );
              if (confirm == true) await auth.logout();
            },
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(theme),
                  const SizedBox(height: 24),
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  if ((_stats['estoqueBaixo'] ?? 0) > 0) ...[
                    _buildAlertBanner(theme),
                    const SizedBox(height: 24),
                  ],
                  const SectionHeader(title: 'Pedidos Recentes'),
                  _buildRecentPedidos(theme),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildGreeting(ThemeData theme) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bom dia!' : hour < 18 ? 'Boa tarde!' : 'Boa noite!';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greeting, style: theme.textTheme.displayLarge),
        Text('Aqui está o resumo de hoje', style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 500 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          children: [
            StatCard(
              title: 'Pedidos Hoje',
              value: '${_stats['pedidosHoje'] ?? 0}',
              icon: Icons.receipt_long_rounded,
              color: AppColors.primary,
            ),
            StatCard(
              title: 'Faturamento',
              value: 'R\$ ${((_stats['vendasHoje'] ?? 0) as num).toStringAsFixed(0)}',
              icon: Icons.attach_money_rounded,
              color: AppColors.success,
            ),
            StatCard(
              title: 'Em Andamento',
              value: '${_stats['pedidosPendentes'] ?? 0}',
              icon: Icons.timelapse_rounded,
              color: AppColors.warning,
            ),
            StatCard(
              title: 'Estoque Baixo',
              value: '${_stats['estoqueBaixo'] ?? 0}',
              icon: Icons.warning_amber_rounded,
              color: AppColors.error,
              subtitle: 'itens',
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlertBanner(ThemeData theme) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.error.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.error.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.error),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${_stats['estoqueBaixo']} ingrediente(s) com estoque abaixo do mínimo. Verifique o estoque.',
            style: GoogleFonts.dmSans(color: AppColors.error, fontSize: 13),
          ),
        ),
      ],
    ),
  );

  Widget _buildRecentPedidos(ThemeData theme) {
    if (_recentPedidos.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Nenhum pedido hoje',
        subtitle: 'Os pedidos aparecerão aqui',
      );
    }
    return Column(
      children: _recentPedidos.map((p) => _PedidoTile(pedido: p, onTap: () {})).toList(),
    );
  }
}

class _PedidoTile extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onTap;
  const _PedidoTile({required this.pedido, required this.onTap});

  Color _statusColor() {
    switch (pedido.status) {
      case StatusPedido.pendente: return AppColors.warning;
      case StatusPedido.preparando: return AppColors.info;
      case StatusPedido.pronto: return AppColors.success;
      case StatusPedido.entregue: return AppColors.primary;
      case StatusPedido.cancelado: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _statusColor().withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_long_rounded, color: _statusColor(), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pedido.cliente, style: theme.textTheme.titleMedium),
                Text('${pedido.itens.length} item(ns) • R\$ ${pedido.total.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          StatusBadge(label: pedido.status.label, color: _statusColor()),
        ],
      ),
    );
  }
}
