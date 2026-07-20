import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../services/database/repositories/transaction_repository.dart';
import '../../../../services/database/repositories/client_repository.dart';
import '../../../../services/database/repositories/lead_repository.dart';
import '../../../../services/database/repositories/content_repository.dart';
import '../../../../services/database/repositories/focus_repository.dart';
import '../../../../services/database/repositories/task_repository.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Quick stats
          Text('Overview', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          GridView.count(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.5,
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: [
              StatCard(title: 'Revenue', icon: Icons.trending_up_rounded, iconColor: context.statusColors.success,
                value: ref.watch(totalRevenueProvider).when(data: (v) => AppFormatters.currency(v), loading: () => '...', error: (_, __) => '—')),
              StatCard(title: 'Expenses', icon: Icons.trending_down_rounded, iconColor: context.statusColors.error,
                value: ref.watch(totalExpensesProvider).when(data: (v) => AppFormatters.currency(v), loading: () => '...', error: (_, __) => '—')),
              StatCard(title: 'Clients', icon: Icons.business_center_rounded, iconColor: context.statusColors.info,
                value: ref.watch(activeClientCountProvider).when(data: (v) => '$v', loading: () => '...', error: (_, __) => '—')),
              StatCard(title: 'Focus Hours', icon: Icons.timer_rounded, iconColor: context.statusColors.info,
                value: ref.watch(monthFocusMinutesProvider).when(data: (v) => AppFormatters.duration(v), loading: () => '...', error: (_, __) => '—')),
          ]),
          const SizedBox(height: 24),

          // Report cards
          Text('Generate Reports', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _ReportCard(icon: Icons.attach_money, title: 'Financial Report', subtitle: 'Revenue, expenses, profit summary', color: context.statusColors.success, onTap: () => _showFinancialReport(context, ref)),
          _ReportCard(icon: Icons.people, title: 'Client Report', subtitle: 'Client activity & payments', color: context.statusColors.info, onTap: () => _showClientReport(context, ref)),
          _ReportCard(icon: Icons.leaderboard, title: 'Sales Report', subtitle: 'Pipeline analytics & conversion rates', color: context.statusColors.info, onTap: () => _showSalesReport(context, ref)),
          _ReportCard(icon: Icons.article, title: 'Content Report', subtitle: 'Production pipeline & publishing stats', color: context.statusColors.warning, onTap: () => _showContentReport(context, ref)),
          _ReportCard(icon: Icons.timer, title: 'Productivity Report', subtitle: 'Focus time & productivity streaks', color: context.statusColors.info, onTap: () => _showProductivityReport(context, ref)),
          const SizedBox(height: 24),

          // Export
          Text('Export Data', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _exportPdf(context, ref), icon: const Icon(Icons.picture_as_pdf, size: 18), label: const Text('PDF'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14)))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: () => _exportCsv(context, ref), icon: const Icon(Icons.table_chart, size: 18), label: const Text('CSV'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14)))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: () => _exportCsv(context, ref, asExcel: true), icon: const Icon(Icons.grid_on, size: 18), label: const Text('Excel'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14)))),
          ]),
        ]),
      ),
    );
  }

  // ── Financial Report ──
  void _showFinancialReport(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final transactions = await ref.read(transactionRepositoryProvider).getAll();
    final revenue = transactions.where((t) => t.type == 'revenue').fold<double>(0, (s, t) => s + t.amount);
    final expenses = transactions.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
    final profit = revenue - expenses;

    // Category breakdown
    final expenseByCategory = <String, double>{};
    final revenueByCategory = <String, double>{};
    for (final t in transactions) {
      if (t.type == 'expense') expenseByCategory[t.category] = (expenseByCategory[t.category] ?? 0) + t.amount;
      if (t.type == 'revenue') revenueByCategory[t.category] = (revenueByCategory[t.category] ?? 0) + t.amount;
    }

    // Monthly trend (last 6 months)
    final now = DateTime.now();
    final monthlyData = <Map<String, dynamic>>[];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);
      final monthTxns = transactions.where((t) => t.date.isAfter(month.subtract(const Duration(days: 1))) && t.date.isBefore(monthEnd.add(const Duration(days: 1))));
      final mRev = monthTxns.where((t) => t.type == 'revenue').fold<double>(0, (s, t) => s + t.amount);
      final mExp = monthTxns.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
      monthlyData.add({'month': '${month.month}/${month.year % 100}', 'revenue': mRev, 'expenses': mExp, 'profit': mRev - mExp});
    }

    if (!context.mounted) return;
    _showReportSheet(context, 'Financial Report', (theme, colors) => [
      _ReportStat(label: 'Total Revenue', value: AppFormatters.currency(revenue), color: context.statusColors.success),
      _ReportStat(label: 'Total Expenses', value: AppFormatters.currency(expenses), color: context.statusColors.error),
      _ReportStat(label: 'Net Profit', value: AppFormatters.currency(profit), color: profit >= 0 ? context.statusColors.info : context.statusColors.error),
      const SizedBox(height: 8),
      Text('${transactions.length} transactions total', style: theme.textTheme.bodySmall),
      if (expenseByCategory.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('Expense Breakdown', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...expenseByCategory.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(child: Text(e.key, style: theme.textTheme.bodyMedium)),
            Text(AppFormatters.currency(e.value), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ]),
        )),
      ],
      if (revenueByCategory.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('Revenue Sources', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...revenueByCategory.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(child: Text(e.key, style: theme.textTheme.bodyMedium)),
            Text(AppFormatters.currency(e.value), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: context.statusColors.success)),
          ]),
        )),
      ],
    ]);
  }

  // ── Client Report ──
  void _showClientReport(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final clients = await ref.read(clientRepositoryProvider).getAll();
    final transactions = await ref.read(transactionRepositoryProvider).getAll();

    final activeClients = clients.where((c) => c.status == 'Active').length;
    final totalProjectValue = clients.fold<double>(0, (s, c) => s + c.projectValue);
    final totalReceived = clients.fold<double>(0, (s, c) => s + c.amountReceived);
    final totalPending = totalProjectValue - totalReceived;

    // Top clients by value
    final sortedClients = List.from(clients)..sort((a, b) => b.projectValue.compareTo(a.projectValue));

    if (!context.mounted) return;
    _showReportSheet(context, 'Client Report', (theme, colors) => [
      _ReportStat(label: 'Active Clients', value: '$activeClients', color: context.statusColors.info),
      _ReportStat(label: 'Total Project Value', value: AppFormatters.currency(totalProjectValue), color: context.statusColors.info),
      _ReportStat(label: 'Amount Received', value: AppFormatters.currency(totalReceived), color: context.statusColors.success),
      _ReportStat(label: 'Pending Payments', value: AppFormatters.currency(totalPending), color: totalPending > 0 ? context.statusColors.error : colors.onSurface.withValues(alpha: 0.4)),
      const SizedBox(height: 8),
      if (totalProjectValue > 0) ...[
        LinearProgressIndicator(value: totalReceived / totalProjectValue, backgroundColor: colors.surfaceContainerHighest, color: context.statusColors.success, minHeight: 8, borderRadius: BorderRadius.circular(4)),
        const SizedBox(height: 4),
        Text('${(totalReceived / totalProjectValue * 100).toStringAsFixed(0)}% collected', style: theme.textTheme.labelSmall),
      ],
      if (sortedClients.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('Top Clients', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...sortedClients.take(5).map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(child: Text(c.name, style: theme.textTheme.bodyMedium)),
            Text(AppFormatters.currency(c.projectValue), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ]),
        )),
      ],
    ]);
  }

  // ── Sales Report ──
  void _showSalesReport(BuildContext context, WidgetRef ref) async {
    final leads = await ref.read(leadRepositoryProvider).getAll();
    final totalLeads = leads.length;
    final pipelineValue = leads.fold<double>(0, (s, l) => s + l.dealValue);
    final wonLeads = leads.where((l) => l.stage == 'Won');
    final wonValue = wonLeads.fold<double>(0, (s, l) => s + l.dealValue);
    final lostLeads = leads.where((l) => l.stage == 'Lost').length;
    final winRate = totalLeads > 0 ? (wonLeads.length / (wonLeads.length + lostLeads)) * 100 : 0.0;

    // Leads by stage
    final byStage = <String, int>{};
    for (final l in leads) { byStage[l.stage] = (byStage[l.stage] ?? 0) + 1; }

    if (!context.mounted) return;
    _showReportSheet(context, 'Sales Report', (theme, colors) => [
      _ReportStat(label: 'Total Leads', value: '$totalLeads', color: context.statusColors.info),
      _ReportStat(label: 'Pipeline Value', value: AppFormatters.currency(pipelineValue), color: context.statusColors.info),
      _ReportStat(label: 'Won Value', value: AppFormatters.currency(wonValue), color: context.statusColors.success),
      _ReportStat(label: 'Win Rate', value: winRate.isNaN ? 'N/A' : '${winRate.toStringAsFixed(0)}%', color: context.statusColors.warning),
      if (byStage.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('Conversion Funnel', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...byStage.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            SizedBox(width: 120, child: Text(e.key, style: theme.textTheme.bodyMedium)),
            Expanded(child: LinearProgressIndicator(
              value: totalLeads > 0 ? e.value / totalLeads : 0,
              backgroundColor: colors.surfaceContainerHighest,
              color: e.key == 'Won' ? context.statusColors.success : e.key == 'Lost' ? context.statusColors.error : context.statusColors.info,
              minHeight: 8, borderRadius: BorderRadius.circular(4),
            )),
            const SizedBox(width: 8),
            Text('${e.value}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          ]),
        )),
      ],
    ]);
  }

  // ── Content Report ──
  void _showContentReport(BuildContext context, WidgetRef ref) async {
    final content = await ref.read(contentRepositoryProvider).getAll();
    final total = content.length;
    final posted = content.where((c) => c.stage == 'Posted').length;
    final inPipeline = content.where((c) => !['Posted', 'Repurposed'].contains(c.stage)).length;
    final repurposed = content.where((c) => c.stage == 'Repurposed').length;

    // By stage
    final byStage = <String, int>{};
    for (final c in content) { byStage[c.stage] = (byStage[c.stage] ?? 0) + 1; }

    // By platform
    final byPlatform = <String, int>{};
    for (final c in content) {
      if (c.platform != null) { byPlatform[c.platform!] = (byPlatform[c.platform!] ?? 0) + 1; }
    }

    if (!context.mounted) return;
    _showReportSheet(context, 'Content Report', (theme, colors) => [
      _ReportStat(label: 'Total Content', value: '$total', color: context.statusColors.warning),
      _ReportStat(label: 'Published', value: '$posted', color: context.statusColors.success),
      _ReportStat(label: 'In Pipeline', value: '$inPipeline', color: context.statusColors.info),
      _ReportStat(label: 'Repurposed', value: '$repurposed', color: context.statusColors.info),
      if (byStage.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('Content by Stage', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...byStage.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            SizedBox(width: 100, child: Text(e.key, style: theme.textTheme.bodySmall)),
            Expanded(child: LinearProgressIndicator(
              value: total > 0 ? e.value / total : 0,
              backgroundColor: colors.surfaceContainerHighest,
              color: context.statusColors.warning,
              minHeight: 6, borderRadius: BorderRadius.circular(4),
            )),
            const SizedBox(width: 8),
            Text('${e.value}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          ]),
        )),
      ],
      if (byPlatform.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('Platform Distribution', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...byPlatform.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(child: Text(e.key, style: theme.textTheme.bodyMedium)),
            Text('${e.value}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ]),
        )),
      ],
    ]);
  }

  // ── Productivity Report ──
  void _showProductivityReport(BuildContext context, WidgetRef ref) async {
    final todayMins = await ref.read(todayFocusMinutesProvider.future);
    final weekMins = await ref.read(weekFocusMinutesProvider.future);
    final monthMins = await ref.read(monthFocusMinutesProvider.future);
    final tasks = await ref.read(taskRepositoryProvider).getAll();
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final totalTasks = tasks.length;

    if (!context.mounted) return;
    _showReportSheet(context, 'Productivity Report', (theme, colors) => [
      _ReportStat(label: 'Focus Today', value: AppFormatters.duration(todayMins), color: context.statusColors.info),
      _ReportStat(label: 'Focus This Week', value: AppFormatters.duration(weekMins), color: context.statusColors.info),
      _ReportStat(label: 'Focus This Month', value: AppFormatters.duration(monthMins), color: context.statusColors.success),
      _ReportStat(label: 'Daily Average', value: monthMins > 0 ? AppFormatters.duration(monthMins ~/ 30) : '0m', color: context.statusColors.warning),
      const SizedBox(height: 8),
      _ReportStat(label: 'Tasks Completed', value: '$completedTasks / $totalTasks', color: context.statusColors.info),
      if (totalTasks > 0) ...[
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: completedTasks / totalTasks,
          backgroundColor: colors.surfaceContainerHighest,
          color: context.statusColors.info,
          minHeight: 8, borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text('${(completedTasks / totalTasks * 100).toStringAsFixed(0)}% completion rate', style: theme.textTheme.labelSmall),
      ],
    ]);
  }

  // ── PDF Export ──
  void _exportPdf(BuildContext context, WidgetRef ref) async {
    final transactions = await ref.read(transactionRepositoryProvider).getAll();
    final clients = await ref.read(clientRepositoryProvider).getAll();
    final leads = await ref.read(leadRepositoryProvider).getAll();

    final revenue = transactions.where((t) => t.type == 'revenue').fold<double>(0, (s, t) => s + t.amount);
    final expenses = transactions.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
    final profit = revenue - expenses;

    final ttf = await PdfGoogleFonts.robotoRegular();
    final ttfBold = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: ttf,
        bold: ttfBold,
      ),
    );
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context ctx) => [
        pw.Header(level: 0, child: pw.Text('RCM OS  Business Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
        pw.Paragraph(text: 'Generated on: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
        pw.SizedBox(height: 20),

        pw.Header(level: 1, child: pw.Text('Financial Summary')),
        pw.Table.fromTextArray(
          context: ctx,
          data: [
            ['Metric', 'Value'],
            ['Total Revenue', AppFormatters.currency(revenue)],
            ['Total Expenses', AppFormatters.currency(expenses)],
            ['Net Profit', AppFormatters.currency(profit)],
            ['Transactions', '${transactions.length}'],
          ],
        ),
        pw.SizedBox(height: 20),

        pw.Header(level: 1, child: pw.Text('Client Summary')),
        pw.Table.fromTextArray(
          context: ctx,
          data: [
            ['Client', 'Status', 'Project Value', 'Received'],
            ...clients.map((c) => [c.name, c.status, AppFormatters.currency(c.projectValue), AppFormatters.currency(c.amountReceived)]),
          ],
        ),
        pw.SizedBox(height: 20),

        pw.Header(level: 1, child: pw.Text('Sales Pipeline')),
        pw.Table.fromTextArray(
          context: ctx,
          data: [
            ['Lead', 'Stage', 'Deal Value'],
            ...leads.map((l) => [l.name, l.stage, AppFormatters.currency(l.dealValue)]),
          ],
        ),

        if (transactions.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Recent Transactions')),
          pw.Table.fromTextArray(
            context: ctx,
            data: [
              ['Date', 'Type', 'Category', 'Amount'],
              ...transactions.take(50).map((t) => [
                '${t.date.day}/${t.date.month}/${t.date.year}',
                t.type,
                t.category,
                AppFormatters.currency(t.amount),
              ]),
            ],
          ),
        ],
      ],
    ));

    if (!context.mounted) return;
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'rcm_os_report.pdf');
    if (context.mounted) context.showSuccess('PDF exported');
  }

  // ── CSV Export ──
  Future<void> _exportCsv(BuildContext context, WidgetRef ref, {bool asExcel = false}) async {
    final transactions = await ref.read(transactionRepositoryProvider).getAll();
    final clients = await ref.read(clientRepositoryProvider).getAll();
    final leads = await ref.read(leadRepositoryProvider).getAll();

    if (transactions.isEmpty && clients.isEmpty && leads.isEmpty) {
      if (context.mounted) context.showSnackBar('No data to export', isError: true);
      return;
    }

    // Transactions sheet
    final txnRows = <List<String>>[
      ['--- TRANSACTIONS ---', '', '', '', '', ''],
      ['Date', 'Type', 'Category', 'Amount', 'Client', 'Description'],
      ...transactions.map((t) => [
        '${t.date.day}/${t.date.month}/${t.date.year}',
        t.type, t.category, t.amount.toStringAsFixed(2),
        t.clientName ?? '', t.description ?? '',
      ]),
      ['', '', '', '', '', ''],
      ['--- CLIENTS ---', '', '', '', '', ''],
      ['Name', 'Status', 'Project Value', 'Received', 'Email', 'Phone'],
      ...clients.map((c) => [
        c.name, c.status, c.projectValue.toStringAsFixed(2),
        c.amountReceived.toStringAsFixed(2), c.email ?? '', c.phone ?? '',
      ]),
      ['', '', '', '', '', ''],
      ['--- LEADS ---', '', '', '', '', ''],
      ['Name', 'Stage', 'Deal Value', 'Company', 'Source', 'Email'],
      ...leads.map((l) => [
        l.name, l.stage, l.dealValue.toStringAsFixed(2),
        l.company ?? '', l.leadSource ?? '', l.email ?? '',
      ]),
    ];

    final csvData = const ListToCsvConverter().convert(txnRows);
    final dir = await getTemporaryDirectory();
    final ext = asExcel ? 'xlsx' : 'csv';
    final file = File('${dir.path}/rcm_os_export.$ext');
    await file.writeAsString(csvData);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'RCM OS - Data Export',
    );
    if (context.mounted) context.showSuccess('${asExcel ? "Excel" : "CSV"} exported');
  }

  // ── Helper: Show report bottom sheet ──
  void _showReportSheet(BuildContext context, String title, List<Widget> Function(ThemeData, ColorScheme) builder) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: colors.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)))),
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text('Generated ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 20),
            ...builder(theme, colors),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
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

class _ReportCard extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final Color color; final VoidCallback onTap;
  const _ReportCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
          child: Icon(icon, size: 20, color: color)),
        title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: theme.textTheme.labelSmall),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
