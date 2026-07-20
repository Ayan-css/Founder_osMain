import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/database/repositories/content_repository.dart';
import '../../../../core/constants/app_constants.dart';

class ContentDetailScreen extends ConsumerWidget {
  final String id;
  const ContentDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final contentAsync = ref.watch(allContentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Detail'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {
            ref.read(contentRepositoryProvider).delete(id);
            ref.invalidate(allContentProvider);
            Navigator.pop(context);
          }),
        ],
      ),
      body: contentAsync.when(
        data: (items) {
          final item = items.where((i) => i.id == id).firstOrNull;
          if (item == null) return const Center(child: Text('Content not found'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                // Stage selector
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.contentStages.map((stage) {
                    final isActive = item.stage == stage;
                    return ChoiceChip(
                      label: Text(stage, style: const TextStyle(fontSize: 12)),
                      selected: isActive,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(contentRepositoryProvider).moveToStage(id, stage);
                          ref.invalidate(allContentProvider);
                          ref.invalidate(contentByStageProvider);
                        }
                      },
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                if (item.description != null) ...[
                  Text('Description', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(item.description!, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                ],
                _DetailRow(label: 'Platform', value: item.platform ?? 'Not set'),
                _DetailRow(label: 'Format', value: item.format ?? 'Not set'),
                _DetailRow(label: 'Priority', value: item.priority),
                _DetailRow(label: 'Category', value: item.category ?? 'Not set'),
                if (item.dueDate != null)
                  _DetailRow(label: 'Due Date', value: '${item.dueDate!.day}/${item.dueDate!.month}/${item.dueDate!.year}'),
                if (item.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Tags', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: item.tags.map((t) => Chip(label: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                  ),
                ],
                if (item.notes != null) ...[
                  const SizedBox(height: 16),
                  Text('Notes', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(item.notes!, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 16),
                Text('Version ${item.version}', style: theme.textTheme.labelSmall),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
