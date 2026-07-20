import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../services/database/repositories/invoice_repository.dart';
import '../../../../services/database/repositories/client_repository.dart';
import '../../../../services/database/collections/invoice_collection.dart';

class InvoiceListScreen extends ConsumerWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final invoicesAsync = ref.watch(allInvoicesProvider);

    return invoicesAsync.when(
      data: (invoices) {
        if (invoices.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.receipt_long_outlined,
            title: 'No invoices yet',
            subtitle: 'Generate your first invoice from the Finance screen',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: invoices.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            return _InvoiceCard(invoice: invoice);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _InvoiceCard extends ConsumerWidget {
  final InvoiceItem invoice;
  const _InvoiceCard({required this.invoice});

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'Paid':
        return const Color(0xFF22C55E);
      case 'Sent':
        return const Color(0xFF3B82F6);
      case 'Overdue':
        return const Color(0xFFEF4444);
      default:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = _statusColor(context, invoice.status);
    final remaining = (invoice.totalAmount - invoice.amountPaidPreviously).clamp(0, double.infinity);

    return Dismissible(
      key: ValueKey(invoice.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Invoice?'),
            content: Text('Delete invoice for ${invoice.clientName}? This cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: colors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) async {
        await ref.read(invoiceRepositoryProvider).delete(invoice.id);
        ref.invalidate(allInvoicesProvider);
        if (context.mounted) context.showSuccess('Invoice deleted');
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.1),
            child: Icon(Icons.receipt_long, size: 20, color: statusColor),
          ),
          title: Text(
            invoice.clientName,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${invoice.serviceName} • ${invoice.duration}',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'Issued ${DateFormat('dd MMM yyyy').format(invoice.issueDate)} • Due ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}',
                style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatters.currency(invoice.totalAmount),
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  invoice.status,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            ],
          ),
          onTap: () async {
            // Fetch client to pass to preview
            final client = await ref.read(clientRepositoryProvider).getById(invoice.clientId);
            if (context.mounted) {
              context.push('/finance/invoices/${invoice.id}/preview', extra: client);
            }
          },
        ),
      ),
    );
  }
}
