import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../services/database/repositories/knowledge_repository.dart';

class KnowledgeCreateScreen extends ConsumerStatefulWidget {
  const KnowledgeCreateScreen({super.key});
  @override
  ConsumerState<KnowledgeCreateScreen> createState() => _KnowledgeCreateScreenState();
}

class _KnowledgeCreateScreenState extends ConsumerState<KnowledgeCreateScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _category = AppConstants.knowledgeCategories.first;
  final _tagController = TextEditingController();
  final List<String> _tags = [];
  bool _isSaving = false;

  @override
  void dispose() { _titleController.dispose(); _contentController.dispose(); _tagController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Knowledge Item'),
        actions: [
          FilledButton(onPressed: _isSaving ? null : _save, child: const Text('Save')),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title *')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: AppConstants.knowledgeCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextField(controller: _contentController, decoration: const InputDecoration(labelText: 'Content *', hintText: 'Knowledge content...'), maxLines: 8),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _tagController, decoration: const InputDecoration(labelText: 'Tags'))),
                IconButton(icon: const Icon(Icons.add), onPressed: () {
                  if (_tagController.text.trim().isNotEmpty) { setState(() { _tags.add(_tagController.text.trim()); _tagController.clear(); }); }
                }),
              ],
            ),
            if (_tags.isNotEmpty) Wrap(spacing: 8, children: _tags.map((t) => Chip(label: Text(t), onDeleted: () => setState(() => _tags.remove(t)))).toList()),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) { context.showSnackBar('Title and content are required', isError: true); return; }
    setState(() => _isSaving = true);
    await ref.read(knowledgeRepositoryProvider).create(title: _titleController.text.trim(), content: _contentController.text.trim(), category: _category, tags: _tags);
    ref.invalidate(allKnowledgeProvider);
    if (mounted) { context.showSuccess('Knowledge saved'); context.pop(); }
  }
}
