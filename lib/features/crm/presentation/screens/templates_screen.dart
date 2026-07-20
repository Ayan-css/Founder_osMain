import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../services/database/collections/template_collection.dart';
import '../../../../services/database/repositories/template_repository.dart';
import '../../../../core/extensions/context_extensions.dart';

const _platforms = ['LinkedIn', 'Email', 'Instagram', 'WhatsApp', 'Cold Call', 'Other'];

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  void _showAddEditSheet(BuildContext context, WidgetRef ref, TemplateItem? editing) {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final subjectCtrl = TextEditingController(text: editing?.subject ?? '');
    final bodyCtrl = TextEditingController(text: editing?.body ?? '');
    String platform = editing?.platform ?? _platforms.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  editing == null ? 'Create Template' : 'Edit Template',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Template Name *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: platform,
                  decoration: const InputDecoration(labelText: 'Platform'),
                  items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setSheetState(() => platform = v!),
                ),
                const SizedBox(height: 12),
                if (platform == 'Email') ...[
                  TextField(
                    controller: subjectCtrl,
                    decoration: const InputDecoration(labelText: 'Subject Line (Optional)'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: bodyCtrl,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Template Body *',
                    alignLabelWithHint: true,
                    helperText: 'Use placeholders like {{name}} or {{company}}',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) {
                        context.showSnackBar('Name and body are required', isError: true);
                        return;
                      }
                      
                      final repo = ref.read(templateRepositoryProvider);
                      if (editing == null) {
                        await repo.create(
                          name: nameCtrl.text.trim(),
                          platform: platform,
                          subject: subjectCtrl.text.trim().isEmpty ? null : subjectCtrl.text.trim(),
                          body: bodyCtrl.text.trim(),
                        );
                      } else {
                        editing.name = nameCtrl.text.trim();
                        editing.platform = platform;
                        editing.subject = subjectCtrl.text.trim().isEmpty ? null : subjectCtrl.text.trim();
                        editing.body = bodyCtrl.text.trim();
                        await repo.update(editing);
                      }
                      
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(editing == null ? 'Create' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, TemplateItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Template?'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.error),
            onPressed: () async {
              await ref.read(templateRepositoryProvider).delete(item.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(allTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates Hub'),
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.article_outlined,
              title: 'No Templates Yet',
              subtitle: 'Create templates to speed up your outreach',
              actionLabel: 'Create Template',
              onAction: () => _showAddEditSheet(context, ref, null),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(template.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.share_outlined, size: 14, color: context.colors.primary),
                                    const SizedBox(width: 4),
                                    Text(template.platform, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.primary, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showAddEditSheet(context, ref, template),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: context.colors.error),
                            onPressed: () => _confirmDelete(context, ref, template),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (template.subject != null) ...[
                        Text('Subject: ${template.subject}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                      ],
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          template.body,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy to Clipboard'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: template.body));
                            context.showSnackBar('Template copied to clipboard');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditSheet(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
