import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../services/database/repositories/task_repository.dart';

class CriticalTasksWidget extends ConsumerWidget {
  const CriticalTasksWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedTasks = ref.watch(pinnedTasksProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return pinnedTasks.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return AppCard(
            child: InkWell(
              onTap: () => _showAddTaskDialog(context, ref),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.push_pin_outlined, color: colors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pin your top 3 tasks', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text('Tap to add your most important tasks', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Icon(Icons.add, color: colors.primary),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            ...tasks.take(3).map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                child: Row(
                  children: [
                    // Checkbox
                    InkWell(
                      onTap: () {
                        ref.read(taskRepositoryProvider).toggleComplete(task.id);
                        ref.invalidate(pinnedTasksProvider);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: task.isCompleted ? context.statusColors.success : colors.outline.withValues(alpha: 0.4),
                            width: 2,
                          ),
                          color: task.isCompleted ? context.statusColors.success : Colors.transparent,
                        ),
                        child: task.isCompleted
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Task info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted ? colors.onSurface.withValues(alpha: 0.4) : null,
                            ),
                          ),
                          if (task.dueDate != null)
                            Text(
                              'Due ${task.dueDate!.day}/${task.dueDate!.month}',
                              style: theme.textTheme.labelSmall,
                            ),
                        ],
                      ),
                    ),

                    // Priority chip
                    _PriorityDot(priority: task.priority),
                    const SizedBox(width: 8),

                    // Pin icon
                    Icon(Icons.push_pin, size: 16, color: colors.primary.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            )),

            // Add more button if less than 3
            if (tasks.length < 3)
              TextButton.icon(
                onPressed: () => _showAddTaskDialog(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Critical Task'),
              ),
          ],
        );
      },
      loading: () => const LoadingSkeleton(height: 100),
      error: (_, __) => const Text('Error loading tasks'),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    String priority = 'Critical';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Critical Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Task title...',
                prefixIcon: Icon(Icons.task_alt, size: 20),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ref.read(taskRepositoryProvider).create(
                  title: controller.text.trim(),
                  priority: priority,
                  isPinned: true,
                );
                ref.invalidate(pinnedTasksProvider);
                ref.invalidate(openTaskCountProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  final String priority;
  const _PriorityDot({required this.priority});

  Color getColor(BuildContext context) {
    switch (priority) {
      case 'Critical': return context.statusColors.error;
      case 'High': return context.statusColors.warning;
      case 'Medium': return context.statusColors.info;
      default: return context.colors.onSurface.withValues(alpha: 0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: getColor(context)),
    );
  }
}
