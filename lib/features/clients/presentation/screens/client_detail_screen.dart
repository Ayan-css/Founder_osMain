import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../services/database/repositories/client_repository.dart';
import '../../../../services/database/repositories/transaction_repository.dart';
import '../../../../services/database/collections/transaction_collection.dart';
import '../../../../core/utils/pdf_generator.dart';
import '../../../../core/utils/whatsapp_helper.dart';

class ClientDetailScreen extends ConsumerWidget {
  final String id;
  const ClientDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final clients = ref.watch(allClientsProvider);

    return clients.when(
      data: (items) {
        final client = items.where((c) => c.id == id).firstOrNull;
        if (client == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Client not found')));
        final pending = client.projectValue - client.amountReceived;

        return DefaultTabController(
          length: 5,
          child: Scaffold(
            appBar: AppBar(
              title: Text(client.name),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                  tooltip: 'WhatsApp Client',
                  onSelected: (value) async {
                    if (client.phone == null || client.phone!.isEmpty) {
                      if (context.mounted) context.showSnackBar('No phone number for this client', isError: true);
                      return;
                    }
                    
                    String message = '';
                    switch (value) {
                      case 'hello':
                        message = "Assalamu Alaikum ${client.name},";
                        break;
                      case 'welcome':
                        message = WhatsAppHelper.getWelcomeMessage(client.name, 'Right Craft Media'); // Using agency name fallback
                        break;
                      case 'farewell':
                        message = WhatsAppHelper.getFarewellMessage(client.name);
                        break;
                      case 'payment':
                        message = WhatsAppHelper.getPaymentReminderMessage(client.name, 'the project', pending.toString(), 'soon');
                        break;
                    }
                    
                    try {
                      await WhatsAppHelper.launchWhatsApp(client.phone!, message);
                    } catch (e) {
                      if (context.mounted) context.showSnackBar(e.toString(), isError: true);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'hello', child: Text('Send Hello')),
                    const PopupMenuItem(value: 'welcome', child: Text('Send Welcome')),
                    const PopupMenuItem(value: 'payment', child: Text('Send Payment Reminder')),
                    const PopupMenuItem(value: 'farewell', child: Text('Send Farewell')),
                  ],
                ),
                IconButton(icon: const Icon(Icons.picture_as_pdf_outlined), tooltip: 'Generate Project Brief', onPressed: () => PdfGenerator.generateClientBrief(client)),
                IconButton(icon: const Icon(Icons.receipt_long_outlined), tooltip: 'Generate Invoice', onPressed: () => context.push('/finance/invoice/generate', extra: client.id)),
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/clients/edit', extra: client)),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { ref.read(clientRepositoryProvider).delete(id); ref.invalidate(allClientsProvider); Navigator.pop(context); }),
              ],
              bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'Overview'), Tab(text: 'Financial'), Tab(text: 'Transactions'), Tab(text: 'Projects'), Tab(text: 'Notes')]),
            ),
            body: TabBarView(children: [
              // Overview
              SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: CircleAvatar(radius: 40, backgroundColor: colors.primaryContainer, child: Text(client.name[0].toUpperCase(), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: colors.onPrimaryContainer)))),
                const SizedBox(height: 16),
                Center(child: Text(client.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700))),
                if (client.businessName != null) Center(child: Text(client.businessName!, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface.withValues(alpha: 0.75)))),
                const SizedBox(height: 24),
                _DetailTile(icon: Icons.email, label: 'Email', value: client.email ?? 'Not set'),
                _DetailTile(icon: Icons.phone, label: 'Phone', value: client.phone ?? 'Not set'),
                _DetailTile(icon: Icons.language, label: 'Website', value: client.website ?? 'Not set'),
                _DetailTile(icon: Icons.circle, label: 'Status', value: client.status),
                if (client.deadline != null)
                  _DetailTile(icon: Icons.event, label: 'Deadline', value: '${client.deadline!.day}/${client.deadline!.month}/${client.deadline!.year}'),
                if (client.socialLinks.isNotEmpty)
                  _DetailTile(icon: Icons.link, label: 'Social Links', value: client.socialLinks.join('\n')),
              ])),
              // Financial
              SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (client.isRetainer) ...[
                  _FinanceCard(label: 'Monthly Retainer (MRR)', value: AppFormatters.currency(client.retainerAmount), color: context.statusColors.info),
                  _FinanceCard(label: 'Lifetime Value (Received)', value: AppFormatters.currency(client.amountReceived), color: context.statusColors.success),
                ] else ...[
                  _FinanceCard(label: 'Project Value', value: AppFormatters.currency(client.projectValue), color: context.statusColors.info),
                  _FinanceCard(label: 'Received', value: AppFormatters.currency(client.amountReceived), color: context.statusColors.success),
                  _FinanceCard(label: 'Pending', value: AppFormatters.currency(pending), color: pending > 0 ? context.statusColors.error : colors.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  if (client.projectValue > 0) LinearProgressIndicator(value: client.amountReceived / client.projectValue, backgroundColor: colors.surfaceContainerHighest, color: context.statusColors.success, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                ],
              ])),
              // Transactions
              _ClientTransactionsTab(clientId: id),
              // Projects & Assets
              SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (client.deliverables.isNotEmpty) ...[
                  Text('Deliverables', style: theme.textTheme.titleSmall), const SizedBox(height: 8),
                  ...client.deliverables.map((d) => Row(children: [const Icon(Icons.check_circle_outline, size: 16), const SizedBox(width: 8), Expanded(child: Text(d))])),
                  const SizedBox(height: 24),
                ],
                if (client.brandColors.isNotEmpty) ...[
                  Text('Brand Colors', style: theme.textTheme.titleSmall), const SizedBox(height: 8),
                  Wrap(spacing: 8, children: client.brandColors.map((c) => Chip(label: Text(c), padding: EdgeInsets.zero)).toList()),
                  const SizedBox(height: 24),
                ],
                if (client.brandGuidelines != null) ...[
                  Text('Brand Guidelines', style: theme.textTheme.titleSmall), const SizedBox(height: 8),
                  Text(client.brandGuidelines!, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface.withValues(alpha: 0.9))),
                  const SizedBox(height: 24),
                ],
                if (client.driveLinks.isNotEmpty) ...[
                  Text('Drive Links', style: theme.textTheme.titleSmall), const SizedBox(height: 8),
                  ...client.driveLinks.map((l) => Row(children: [const Icon(Icons.folder_shared, size: 16), const SizedBox(width: 8), Expanded(child: Text(l))])),
                  const SizedBox(height: 24),
                ],
                if (client.socialMediaAccess != null) ...[
                  Text('Social Media Access', style: theme.textTheme.titleSmall), const SizedBox(height: 8),
                  Text(client.socialMediaAccess!, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface.withValues(alpha: 0.9))),
                ],
                if (client.deliverables.isEmpty && client.brandColors.isEmpty && client.driveLinks.isEmpty && client.brandGuidelines == null && client.socialMediaAccess == null)
                  Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.folder_outlined, size: 48, color: colors.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text('No project assets or deliverables', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface.withValues(alpha: 0.65))),
                  ]))),
              ])),
              // Notes
              SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Meeting Notes', style: theme.textTheme.titleSmall), const SizedBox(height: 8),
                Text(client.meetingNotes ?? 'No meeting notes yet', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface.withValues(alpha: 0.75))),
                const SizedBox(height: 24),
                Text('Internal Notes', style: theme.textTheme.titleSmall), const SizedBox(height: 8),
                Text(client.internalNotes ?? 'No internal notes yet', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface.withValues(alpha: 0.75))),
              ])),
            ]),
          ),
        );
      },
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
    );
  }
}

class _ClientTransactionsTab extends ConsumerWidget {
  final String clientId;
  const _ClientTransactionsTab({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return FutureBuilder<List<TransactionItem>>(
      future: ref.read(transactionRepositoryProvider).getByClientId(clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final transactions = snapshot.data ?? [];
        if (transactions.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.receipt_long, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No transactions linked', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.65))),
          ]));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16), itemCount: transactions.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final t = transactions[index];
            final isRevenue = t.type == 'revenue';
            return Card(margin: EdgeInsets.zero, child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (isRevenue ? context.statusColors.success : context.statusColors.error).withValues(alpha: 0.15),
                child: Icon(isRevenue ? Icons.arrow_downward : Icons.arrow_upward, size: 18, color: isRevenue ? context.statusColors.success : context.statusColors.error),
              ),
              title: Text(t.description ?? t.category, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(t.date.formatted, style: theme.textTheme.labelSmall),
              trailing: Text(
                '${isRevenue ? '+' : '-'}${AppFormatters.currency(t.amount)}',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: isRevenue ? context.statusColors.success : context.statusColors.error),
              ),
            ));
          },
        );
      },
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _DetailTile({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [
      Icon(icon, size: 20, color: theme.colorScheme.primary.withValues(alpha: 0.8)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: theme.textTheme.labelSmall),
        Text(value, style: theme.textTheme.bodyMedium),
      ]),
    ]));
  }
}

class _FinanceCard extends StatelessWidget {
  final String label; final String value; final Color color;
  const _FinanceCard({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color)),
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}
