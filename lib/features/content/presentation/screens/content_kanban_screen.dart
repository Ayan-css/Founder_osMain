import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/database/repositories/content_repository.dart';
import '../../../../services/database/collections/content_collection.dart';

class ContentKanbanScreen extends ConsumerWidget {
  const ContentKanbanScreen({super.key});

  Color _stageColor(BuildContext context, String stage) {
    final map = {
      'Raw Thought': context.colors.onSurface.withValues(alpha: 0.4), 'Idea': context.statusColors.info, 'Hook': context.statusColors.warning,
      'Script': context.statusColors.info, 'Recording': context.statusColors.error, 'Editing': context.statusColors.info,
      'Review': context.statusColors.info, 'Scheduled': context.statusColors.warning, 'Posted': context.statusColors.success,
      'Repurposed': context.statusColors.info,
    };
    return map[stage] ?? context.colors.onSurface.withValues(alpha: 0.4);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentByStage = ref.watch(contentByStageProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return contentByStage.when(
      data: (grouped) {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          itemCount: AppConstants.contentStages.length,
          itemBuilder: (context, index) {
            final stage = AppConstants.contentStages[index];
            final items = grouped[stage] ?? [];
            final color = _stageColor(context, stage);

            return DragTarget<_DragData>(
              onWillAcceptWithDetails: (details) => details.data.fromStage != stage,
              onAcceptWithDetails: (details) async {
                await ref.read(contentRepositoryProvider).moveToStage(details.data.item.id, stage);
                ref.invalidate(contentByStageProvider);
                ref.invalidate(allContentProvider);
              },
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 280,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: isHovering
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
                          color: color.withValues(alpha: 0.04),
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stage header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
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

                      // Cards
                      Expanded(
                        child: items.isEmpty
                            ? Center(
                                child: Text(
                                  isHovering ? 'Drop here' : 'No items',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isHovering ? color : colors.onSurface.withValues(alpha: 0.3),
                                    fontWeight: isHovering ? FontWeight.w600 : null,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final item = items[i];
                                  return LongPressDraggable<_DragData>(
                                    data: _DragData(item: item, fromStage: stage),
                                    feedback: Material(
                                      elevation: 8,
                                      borderRadius: BorderRadius.circular(16),
                                      child: SizedBox(
                                        width: 260,
                                        child: _KanbanCard(item: item, stageColor: color),
                                      ),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.3,
                                      child: _KanbanCard(item: item, stageColor: color),
                                    ),
                                    child: _KanbanCard(item: item, stageColor: color),
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
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _DragData {
  final ContentItem item;
  final String fromStage;
  const _DragData({required this.item, required this.fromStage});
}

class _KanbanCard extends StatelessWidget {
  final ContentItem item;
  final Color stageColor;
  const _KanbanCard({required this.item, required this.stageColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                if (item.platform != null) ...[
                  Icon(Icons.play_circle_outline, size: 14, color: colors.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(item.platform!, style: theme.textTheme.labelSmall),
                ],
                if (item.format != null) ...[
                  if (item.platform != null) const SizedBox(width: 8),
                  Text('• ${item.format!}', style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.6))),
                ],
                const Spacer(),
                if (item.priority == 'Critical' || item.priority == 'High')
                  if (item.priority == 'High' || item.priority == 'Critical') Icon(Icons.warning_amber_rounded, size: 14,
                    color: item.priority == 'Critical' ? context.statusColors.error : context.statusColors.warning,
                  ),
              ],
            ),
            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: item.tags.take(2).map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(t, style: const TextStyle(fontSize: 10)),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
