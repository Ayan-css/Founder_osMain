import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../services/database/repositories/transaction_repository.dart';
import '../../../../services/database/repositories/client_repository.dart';
import '../../../../core/utils/pdf_generator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/workspace_service.dart';
import 'invoice_list_screen.dart';
import '../../../../core/widgets/premium_background.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});
  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Generate Invoice',
            onPressed: () => context.push('/finance/invoice/generate'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Revenue'),
            Tab(text: 'Expenses'),
            Tab(text: 'Invoices'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: PremiumBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(),
            _TransactionListTab(type: 'revenue'),
            _TransactionListTab(type: 'expense'),
            const InvoiceListScreen(),
            _ReportsTab(),
          ],
        ),
      ),
      floatingActionButton: ref.watch(workspaceServiceProvider).isViewer 
        ? null 
        : FloatingActionButton.extended(
            onPressed: () => context.go('/finance/create'),
            icon: const Icon(Icons.add),
            label: const Text('Add Transaction'),
          ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final revenue = ref.watch(totalRevenueProvider);
    final expenses = ref.watch(totalExpensesProvider);
    final profit = ref.watch(totalProfitProvider);
    final expensesByCategory = ref.watch(expensesByCategoryProvider);
    final trend = ref.watch(monthlyTrendProvider);

    final revColor = context.statusColors.success;
    final expColor = context.statusColors.error;
    final profitColor = context.statusColors.info;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial stats
          Row(children: [
            Expanded(child: StatCard(
              title: 'Revenue', icon: Icons.trending_up_rounded, iconColor: revColor,
              value: revenue.when(data: (v) => AppFormatters.currency(v), loading: () => '...', error: (_, __) => '—'),
            )),
            const SizedBox(width: 10),
            Expanded(child: StatCard(
              title: 'Expenses', icon: Icons.trending_down_rounded, iconColor: expColor,
              value: expenses.when(data: (v) => AppFormatters.currency(v), loading: () => '...', error: (_, __) => '—'),
            )),
          ]),
          const SizedBox(height: 10),
          StatCard(
            title: 'Net Profit', icon: Icons.account_balance_rounded, iconColor: profitColor,
            value: profit.when(data: (v) => AppFormatters.currency(v), loading: () => '...', error: (_, __) => '—'),
            isPositiveTrend: profit.valueOrNull != null && profit.valueOrNull! >= 0,
          ),
          const SizedBox(height: 24),

          // Profit trend chart
          Text('Profit Trend', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          trend.when(
            data: (data) {
              if (data.every((m) => m['profit'] == 0)) {
                return AppCard(child: SizedBox(height: 180, child: Center(child: Text('Add transactions to see trends', style: theme.textTheme.bodySmall))));
              }
              final maxVal = data.fold<double>(0, (max, m) {
                final p = (m['profit'] ?? 0).abs();
                return p > max ? p : max;
              });
              return AppCard(
                child: SizedBox(
                  height: 180,
                  child: LineChart(LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxVal > 0 ? maxVal / 3 : 1,
                      getDrawingHorizontalLine: (v) => FlLine(color: colors.outline.withValues(alpha: 0.08), strokeWidth: 1)),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                        final labels = ['6m', '5m', '4m', '3m', '2m', '1m'];
                        final i = v.toInt();
                        return i >= 0 && i < labels.length ? Text(labels[i], style: TextStyle(fontSize: 10, color: colors.onSurface.withValues(alpha: 0.4))) : const SizedBox();
                      })),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (v, _) => Text(AppFormatters.compactNumber(v), style: TextStyle(fontSize: 10, color: colors.onSurface.withValues(alpha: 0.4))))),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]['profit'] ?? 0)),
                          isCurved: true, color: profitColor, barWidth: 3, dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: profitColor.withValues(alpha: 0.1)),
                        )
                      ],
                  )),
                ),
              );
            },
            loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 24),

          // Expense breakdown
          Text('Expense Breakdown', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          expensesByCategory.when(
            data: (data) {
              if (data.isEmpty) return AppCard(child: Padding(padding: const EdgeInsets.all(16), child: Text('No expenses recorded', style: theme.textTheme.bodySmall)));
              final colors2 = (theme.extension<AppStatusColors>()!.success == theme.colorScheme.onSurface) 
                  ? [theme.colorScheme.onSurface, theme.colorScheme.error] 
                  : [context.statusColors.info, context.statusColors.error, context.statusColors.warning, context.statusColors.success, const Color(0xFF8B5CF6), const Color(0xFFEC4899), const Color(0xFF06B6D4)];
              return AppCard(
                child: Column(children: [
                  SizedBox(
                    height: 160,
                    child: PieChart(PieChartData(
                      sectionsSpace: 2, centerSpaceRadius: 40,
                      sections: data.entries.toList().asMap().entries.map((e) {
                        final color = colors2[e.key % colors2.length];
                        return PieChartSectionData(value: e.value.value, title: '', color: color, radius: 30);
                      }).toList(),
                    )),
                  ),
                  const SizedBox(height: 12),
                  ...data.entries.toList().asMap().entries.map((e) {
                    final color = colors2[e.key % colors2.length];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.value.key, style: theme.textTheme.bodySmall)),
                        Text(AppFormatters.currency(e.value.value), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      ]),
                    );
                  }),
                ]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class _TransactionListTab extends ConsumerWidget {
  final String type;
  const _TransactionListTab({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final all = ref.watch(allTransactionsProvider);

    return all.when(
      data: (items) {
        final filtered = items.where((t) => type == 'revenue' ? (t.type == 'revenue' || t.type == 'refund') : t.type == type).toList();
        if (filtered.isEmpty) {
          return EmptyStateWidget(
            icon: type == 'revenue' ? Icons.trending_up : Icons.trending_down,
            title: 'No ${type == 'revenue' ? 'revenue' : 'expenses'} recorded',
            subtitle: 'Add your first transaction',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16), itemCount: filtered.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final t = filtered[index];
            final isRevenue = t.type == 'revenue';
            final isRefund = t.type == 'refund';
            final color = isRevenue 
                ? context.statusColors.success 
                : (isRefund ? context.statusColors.warning : context.statusColors.error);
            final icon = isRevenue ? Icons.arrow_downward : (isRefund ? Icons.assignment_return : Icons.arrow_upward);
            final sign = isRevenue ? '+' : '-';

            return Dismissible(
              key: ValueKey(t.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Transaction?'),
                    content: Text('Delete ${t.description ?? t.category} (${AppFormatters.currency(t.amount)})? This cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ) ?? false;
              },
              onDismissed: (_) async {
                // Reverse client payment if linked
                if (t.clientId != null) {
                  if (t.type == 'revenue') {
                    await ref.read(clientRepositoryProvider).addPayment(t.clientId!, -t.amount);
                  } else if (t.type == 'refund') {
                    await ref.read(clientRepositoryProvider).addPayment(t.clientId!, t.amount);
                  }
                }
                await ref.read(transactionRepositoryProvider).delete(t.id);
                ref.invalidate(allTransactionsProvider);
                ref.invalidate(totalRevenueProvider);
                ref.invalidate(totalExpensesProvider);
                ref.invalidate(totalProfitProvider);
                ref.invalidate(expensesByCategoryProvider);
                ref.invalidate(monthlyTrendProvider);
                ref.invalidate(allClientsProvider);
                ref.invalidate(pendingPaymentsProvider);
                ref.invalidate(activeClientCountProvider);
                if (context.mounted) context.showSuccess('Transaction deleted');
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
              ),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  title: Text(t.description ?? t.category, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text('${t.category} • ${t.date.formatted}', style: theme.textTheme.labelSmall),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$sign${AppFormatters.currency(t.amount)}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: color),
                      ),
                      if (isRevenue) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.receipt_long_outlined, size: 20),
                          tooltip: 'Generate Receipt',
                          onPressed: () => PdfGenerator.generatePaymentReceipt(t),
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                  onTap: () => context.push('/finance/create', extra: t),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _ReportTile(icon: Icons.calendar_month, title: 'Monthly Report', subtitle: 'Revenue, expenses & profit for this month', onTap: () => _showReport(context, ref, 'monthly')),
        _ReportTile(icon: Icons.date_range, title: 'Quarterly Report', subtitle: 'Last 3 months overview', onTap: () => _showReport(context, ref, 'quarterly')),
        _ReportTile(icon: Icons.assessment, title: 'Annual Report', subtitle: 'Full year financial summary', onTap: () => _showReport(context, ref, 'annual')),
        const SizedBox(height: 24),
        Text('Export Options', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => _exportCsv(context, ref), icon: const Icon(Icons.table_chart, size: 18), label: const Text('CSV'))),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton.icon(onPressed: () => _exportCsv(context, ref, asExcel: true), icon: const Icon(Icons.grid_on, size: 18), label: const Text('Excel'))),
        ]),
      ]),
    );
  }

  void _showReport(BuildContext context, WidgetRef ref, String period) async {
    final theme = Theme.of(context);
    final repo = ref.read(transactionRepositoryProvider);
    final now = DateTime.now();

    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    String title;

    switch (period) {
      case 'monthly':
        start = DateTime(now.year, now.month, 1);
        title = 'Monthly Report';
        break;
      case 'quarterly':
        start = DateTime(now.year, now.month - 2, 1);
        title = 'Quarterly Report';
        break;
      case 'annual':
        start = DateTime(now.year, 1, 1);
        title = 'Annual Report';
        break;
      default:
        return;
    }

    final transactions = await repo.getByDateRange(start, end);
    final revRaw = transactions.where((t) => t.type == 'revenue').fold<double>(0, (s, t) => s + t.amount);
    final refunds = transactions.where((t) => t.type == 'refund').fold<double>(0, (s, t) => s + t.amount);
    final revenue = revRaw - refunds;
    final expenses = transactions.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
    final profit = revenue - expenses;

    // Category breakdown for expenses
    final expenseBreakdown = <String, double>{};
    for (final t in transactions.where((t) => t.type == 'expense')) {
      expenseBreakdown[t.category] = (expenseBreakdown[t.category] ?? 0) + t.amount;
    }

    final revColor = context.statusColors.success;
    final expColor = context.statusColors.error;
    final profitColor = profit >= 0 ? context.statusColors.info : context.statusColors.error;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)))),
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text('${start.day}/${start.month}/${start.year} — ${end.day}/${end.month}/${end.year}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 24),
            _ReportStat(label: 'Total Revenue', value: AppFormatters.currency(revenue), color: revColor),
            _ReportStat(label: 'Total Expenses', value: AppFormatters.currency(expenses), color: expColor),
            _ReportStat(label: 'Net Profit', value: AppFormatters.currency(profit), color: profitColor),
            const SizedBox(height: 8),
            Text('Transactions: ${transactions.length}', style: theme.textTheme.bodySmall),
            if (expenseBreakdown.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Expense Breakdown', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...expenseBreakdown.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: Text(e.key, style: theme.textTheme.bodyMedium)),
                  Text(AppFormatters.currency(e.value), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ]),
              )),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export to PDF'),
                onPressed: () {
                  PdfGenerator.generateFinancialReport(
                    title: title,
                    dateRange: '${start.day}/${start.month}/${start.year} — ${end.day}/${end.month}/${end.year}',
                    revenue: revenue,
                    expenses: expenses,
                    profit: profit,
                    expenseBreakdown: expenseBreakdown,
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref, {bool asExcel = false}) async {
    final transactions = await ref.read(transactionRepositoryProvider).getAll();
    if (transactions.isEmpty) {
      if (context.mounted) context.showSnackBar('No transactions to export', isError: true);
      return;
    }

    final rows = <List<String>>[
      ['Date', 'Type', 'Category', 'Amount', 'Client', 'Description', 'Resource'],
      ...transactions.map((t) => [
        '${t.date.day}/${t.date.month}/${t.date.year}',
        t.type,
        t.category,
        t.amount.toStringAsFixed(2),
        t.clientName ?? '',
        t.description ?? '',
        t.resourceName ?? '',
      ]),
    ];

    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final ext = asExcel ? 'xlsx' : 'csv';
    final file = File('${dir.path}/transactions_export.$ext');
    await file.writeAsString(csvData);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'RCM OS - Transactions Export',
    );
    if (context.mounted) context.showSuccess('Export ready');
  }
}

class _ReportStat extends StatelessWidget {
  final String label; final String value; final Color color;
  const _ReportStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
      child: Row(children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final VoidCallback onTap;
  const _ReportTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: theme.textTheme.labelSmall),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
