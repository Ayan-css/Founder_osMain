import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/database/repositories/lead_repository.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/pdf_generator.dart';

class LeadDetailScreen extends ConsumerWidget {
  final String id;
  const LeadDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final leads = ref.watch(allLeadsProvider);

    return leads.when(
        data: (items) {
          final lead = items.where((l) => l.id == id).firstOrNull;
          if (lead == null) return Scaffold(appBar: AppBar(title: const Text('Lead Details')), body: const Center(child: Text('Lead not found')));
          return Scaffold(
            appBar: AppBar(title: const Text('Lead Details'), actions: [
              IconButton(icon: const Icon(Icons.picture_as_pdf_outlined), tooltip: 'Generate Prospect Brief', onPressed: () => PdfGenerator.generateLeadBrief(lead)),
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {
                context.push('/crm/edit', extra: lead);
              }),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { ref.read(leadRepositoryProvider).delete(id); ref.invalidate(allLeadsProvider); ref.invalidate(leadsByStageProvider); Navigator.pop(context); }),
            ]),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lead.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  if (lead.company != null) Text(lead.company!, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(height: 16),
                  // Stage chips
                  Wrap(spacing: 8, runSpacing: 8, children: AppConstants.crmStages.map((stage) {
                    return ChoiceChip(label: Text(stage, style: const TextStyle(fontSize: 12)), selected: lead.stage == stage, onSelected: (s) {
                      if (s) { ref.read(leadRepositoryProvider).moveToStage(id, stage); ref.invalidate(allLeadsProvider); ref.invalidate(leadsByStageProvider); }
                    }, visualDensity: VisualDensity.compact);
                  }).toList()),
                  const SizedBox(height: 24),
                  _InfoCard(label: 'Deal Value', value: AppFormatters.currency(lead.dealValue)),
                  _InfoCard(label: 'Email', value: lead.email ?? 'Not set'),
                  _InfoCard(label: 'Phone', value: lead.phone ?? 'Not set'),
                  _InfoCard(label: 'Source', value: lead.leadSource ?? 'Not set'),
                  _InfoCard(label: 'Industry', value: lead.industry ?? 'Not set'),
                  if (lead.followUpDate != null) _InfoCard(label: 'Follow Up', value: '${lead.followUpDate!.day}/${lead.followUpDate!.month}/${lead.followUpDate!.year}'),
                  if (lead.notes != null) ...[const SizedBox(height: 16), Text('Notes', style: theme.textTheme.titleSmall), const SizedBox(height: 8), Text(lead.notes!)],
                ],
              ),
            ),
          );
        },
        loading: () => Scaffold(appBar: AppBar(title: const Text('Lead Details')), body: const Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(appBar: AppBar(title: const Text('Lead Details')), body: Center(child: Text('Error: $e'))),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label; final String value;
  const _InfoCard({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
    ]));
  }
}
