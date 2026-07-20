import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/database/repositories/invoice_repository.dart';
import '../../../../services/database/collections/client_collection.dart';
import '../../../../services/pdf/invoice_generator_service.dart';
import '../../../../services/settings_service.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../../core/extensions/context_extensions.dart';

class InvoicePreviewScreen extends ConsumerWidget {
  final String invoiceId;
  final ClientItem? client; // passed from generator

  const InvoicePreviewScreen({super.key, required this.invoiceId, this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(allInvoicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          invoiceAsync.maybeWhen(
            data: (invoices) {
              try {
                final invoice = invoices.firstWhere((i) => i.id == invoiceId);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.message, color: Colors.green),
                      tooltip: 'Send WhatsApp Reminder',
                      onPressed: () async {
                        if (client == null) {
                          context.showSnackBar('Client data missing', isError: true);
                          return;
                        }
                        if (client!.phone == null || client!.phone!.isEmpty) {
                          context.showSnackBar('Client phone number not available', isError: true);
                          return;
                        }
                        
                        final msg = WhatsAppHelper.getPaymentReminderMessage(
                          client!.name, 
                          invoice.serviceName, 
                          invoice.totalAmount.toStringAsFixed(0), 
                          invoice.dueDate.toIso8601String().substring(0, 10),
                        );
                        
                        try {
                          await WhatsAppHelper.launchWhatsApp(client!.phone!, msg);
                        } catch (e) {
                          if (context.mounted) context.showSnackBar(e.toString(), isError: true);
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                      tooltip: 'Delete Invoice',
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Invoice?'),
                            content: Text('Delete invoice for ${invoice.clientName}? This cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await ref.read(invoiceRepositoryProvider).delete(invoiceId);
                          ref.invalidate(allInvoicesProvider);
                          if (context.mounted) {
                            context.showSuccess('Invoice deleted');
                            context.pop();
                          }
                        }
                      },
                    ),
                  ],
                );
              } catch (_) {
                return const SizedBox.shrink();
              }
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: invoiceAsync.when(
        data: (invoices) {
          final invoice = invoices.firstWhere((i) => i.id == invoiceId, orElse: () => throw Exception('Invoice not found'));
          final settings = ref.read(settingsServiceProvider);
          
          return PdfPreview(
            build: (format) async {
              // If client isn't passed, we'd fetch it, but here we assume it's passed or we can fetch it.
              // For simplicity, we just use the passed client or fetch it synchronously.
              if (client == null) {
                throw Exception('Client data is missing for preview');
              }
              final pdf = await InvoiceGeneratorService.generate(invoice, client!, settings);
              return pdf.save();
            },
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            pdfFileName: 'Invoice_${invoice.clientName.replaceAll(' ', '_')}_${invoice.issueDate.toIso8601String().substring(0,10)}.pdf',
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
