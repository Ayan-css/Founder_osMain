import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../services/database/repositories/task_repository.dart';
import '../../../../services/database/collections/task_collection.dart';
import '../../../../core/widgets/premium_background.dart';

class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key});
  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tasks = ref.watch(allTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, size: 22),
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (_) => ['All', 'Critical', 'High', 'Medium', 'Low']
                .map((f) => PopupMenuItem(value: f, child: Text(f)))
                .toList(),
          ),
        ],
      ),
      body: PremiumBackground(
        child: tasks.when(
          data: (items) {
          var filtered = items;
          if (_filter != 'All') {
            filtered = items.where((t) => t.priority == _filter).toList();
          }
          if (filtered.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.task_alt, size: 48, color: colors.onSurface.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(_filter == 'All' ? 'No tasks yet' : 'No $_filter tasks',
                    style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface.withValues(alpha: 0.5))),
              ]),
            );
          }
          // Sort: pinned first, then by priority, then by date
          final sorted = List<TaskItem>.from(filtered);
          sorted.sort((a, b) {
            if (a.isPinned && !b.isPinned) return -1;
            if (!a.isPinned && b.isPinned) return 1;
            if (a.isCompleted && !b.isCompleted) return 1;
            if (!a.isCompleted && b.isCompleted) return -1;
            return b.createdAt.compareTo(a.createdAt);
          });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = sorted[index];
              return _TaskCard(
                task: task,
                onToggle: () async {
                  await ref.read(taskRepositoryProvider).toggleComplete(task.id);
                  ref.invalidate(allTasksProvider);
                  ref.invalidate(openTaskCountProvider);
                },
                onPin: () async {
                  await ref.read(taskRepositoryProvider).togglePin(task.id);
                  ref.invalidate(allTasksProvider);
                  ref.invalidate(pinnedTasksProvider);
                },
                onDelete: () async {
                  await ref.read(taskRepositoryProvider).delete(task.id);
                  ref.invalidate(allTasksProvider);
                  ref.invalidate(openTaskCountProvider);
                  if (context.mounted) context.showSuccess('Task deleted');
                },
                onEdit: () => _showEditDialog(context, task),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'Medium';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Task'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Title *'), textCapitalization: TextCapitalization.sentences),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['Critical', 'High', 'Medium', 'Low'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setDialogState(() => priority = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            Consumer(builder: (context, ref, _) => FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await ref.read(taskRepositoryProvider).create(title: titleCtrl.text.trim(), description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), priority: priority);
                ref.invalidate(allTasksProvider);
                ref.invalidate(openTaskCountProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Add'),
            )),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, TaskItem task) {
    final titleCtrl = TextEditingController(text: task.title);
    final descCtrl = TextEditingController(text: task.description ?? '');
    String priority = task.priority;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title *'), textCapitalization: TextCapitalization.sentences),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['Critical', 'High', 'Medium', 'Low'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setDialogState(() => priority = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            Consumer(builder: (context, ref, _) => FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                task.title = titleCtrl.text.trim();
                task.description = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();
                task.priority = priority;
                await ref.read(taskRepositoryProvider).update(task);
                ref.invalidate(allTasksProvider);
                ref.invalidate(openTaskCountProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            )),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TaskCard({required this.task, required this.onToggle, required this.onPin, required this.onDelete, required this.onEdit});

  Color _priorityColor(BuildContext context, String priority) {
    switch (priority) {
      case 'Critical': return context.statusColors.error;
      case 'High': return context.statusColors.warning;
      case 'Medium': return context.statusColors.info;
      default: return context.colors.onSurface.withValues(alpha: 0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final pColor = _priorityColor(context, task.priority);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: (_) => onToggle(),
              shape: const CircleBorder(),
            ),
            Container(width: 4, height: 32, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: pColor, borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(task.title, style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted ? colors.onSurface.withValues(alpha: 0.4) : null,
                )),
                if (task.description != null) Text(task.description!, style: theme.textTheme.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            if (task.isPinned) Icon(Icons.push_pin, size: 16, color: colors.primary),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: colors.onSurface.withValues(alpha: 0.5)),
              onSelected: (v) {
                if (v == 'pin') onPin();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'pin', child: Text(task.isPinned ? 'Unpin' : 'Pin')),
                PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: context.statusColors.error))),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
