import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../services/database/repositories/outreach_repository.dart';
import '../../../../core/extensions/context_extensions.dart';

class FollowUpWidget extends ConsumerWidget {
  const FollowUpWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final outreachItemsAsync = ref.watch(allOutreachProvider);

    return outreachItemsAsync.when(
      data: (items) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        // Items with follow-up date today or earlier (overdue), and not converted/not interested
        final followUps = items.where((i) {
          if (i.followUpDate == null) return false;
          if (i.status == 'Converted' || i.status == 'Not Interested') return false;
          
          final fDate = DateTime(i.followUpDate!.year, i.followUpDate!.month, i.followUpDate!.day);
          return fDate.isBefore(today.add(const Duration(days: 1)));
        }).toList();

        // Sort by date ascending (most overdue first)
        followUps.sort((a, b) => a.followUpDate!.compareTo(b.followUpDate!));

        if (followUps.isEmpty) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: context.statusColors.success, size: 24),
                  const SizedBox(width: 12),
                  const Text('No pending follow-ups! You\'re all caught up.'),
                ],
              ),
            ),
          );
        }

        return Column(
          children: followUps.take(3).map((item) {
            final fDate = DateTime(item.followUpDate!.year, item.followUpDate!.month, item.followUpDate!.day);
            final isOverdue = fDate.isBefore(today);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                onTap: () => context.push('${RouteNames.outreach}/${item.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isOverdue ? context.statusColors.error : context.statusColors.warning,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                Text(item.platform, style: theme.textTheme.bodySmall),
                                if (item.company != null) ...[
                                  const SizedBox(width: 4),
                                  const Text('•'),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(item.company!, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isOverdue ? 'OVERDUE' : 'TODAY',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isOverdue ? context.statusColors.error : context.statusColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(Icons.chevron_right, size: 16, color: colors.onSurface.withValues(alpha: 0.3)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const LoadingSkeleton(height: 80),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
