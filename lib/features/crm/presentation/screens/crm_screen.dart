import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../services/database/repositories/lead_repository.dart';
import '../../../../core/widgets/premium_background.dart';

class CrmScreen extends ConsumerWidget {
  const CrmScreen({super.key});

  Color _stageColor(BuildContext context, String stage) {
    final map = {'New Lead': context.statusColors.info, 'Contacted': context.statusColors.info, 'Discovery Call': context.statusColors.warning,
      'Proposal Sent': context.statusColors.info, 'Negotiation': context.statusColors.warning, 'Won': context.statusColors.success, 'Lost': context.statusColors.error};
    return map[stage] ?? context.colors.onSurface.withValues(alpha: 0.4);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final leadsByStage = ref.watch(leadsByStageProvider);
    final pipelineValue = ref.watch(pipelineValueProvider);
    final activeLeads = ref.watch(activeLeadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM Pipeline'),
        actions: [
          IconButton(icon: const Icon(Icons.search, size: 22), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list, size: 22), onPressed: () {}),
        ],
      ),
      body: PremiumBackground(
        child: Column(
          children: [
          // Stats bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: StatCard(
                  title: 'Active Leads',
                  value: activeLeads.when(data: (v) => '$v', loading: () => '...', error: (_, __) => '—'),
                  icon: Icons.people_outline,
                  iconColor: context.statusColors.info,
                )),
                const SizedBox(width: 10),
                Expanded(child: StatCard(
                  title: 'Pipeline Value',
                  value: pipelineValue.when(data: (v) => AppFormatters.currency(v), loading: () => '...', error: (_, __) => '—'),
                  icon: Icons.monetization_on_outlined,
                  iconColor: context.statusColors.success,
                )),
              ],
            ),
          ),
          // Pipeline board
          Expanded(
            child: leadsByStage.when(
              data: (grouped) {
                if (grouped.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.people_outlined,
                    title: 'No leads yet',
                    subtitle: 'Add your first lead to start tracking',
                    actionLabel: 'Add Lead',
                    onAction: () => context.go('/crm/create'),
                  );
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  itemCount: AppConstants.crmStages.length,
                  itemBuilder: (context, index) {
                    final stage = AppConstants.crmStages[index];
                    final items = grouped[stage] ?? [];
                    final color = _stageColor(context, stage);
                    return Container(
                      width: 260,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(stage, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                                Text('${items.length}', style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: items.isEmpty
                                ? Center(child: Text('No leads', style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.3))))
                                : ListView.separated(
                                    itemCount: items.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (context, i) {
                                      final lead = items[i];
                                      return Card(
                                        margin: EdgeInsets.zero,
                                        child: InkWell(
                                          onTap: () => context.go('/crm/${lead.id}'),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(lead.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                                if (lead.company != null) Text(lead.company!, style: theme.textTheme.labelSmall),
                                                const SizedBox(height: 8),
                                                Text(AppFormatters.currency(lead.dealValue), style: theme.textTheme.bodySmall?.copyWith(color: context.statusColors.success, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/crm/create'),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Lead'),
      ),
    );
  }
}
