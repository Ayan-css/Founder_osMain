import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../services/database/repositories/content_repository.dart';

class ContentCreateScreen extends ConsumerStatefulWidget {
  const ContentCreateScreen({super.key});
  @override
  ConsumerState<ContentCreateScreen> createState() => _ContentCreateScreenState();
}

class _ContentCreateScreenState extends ConsumerState<ContentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagController = TextEditingController();
  String _stage = 'Raw Thought';
  String _priority = 'Medium';
  String? _platform;
  String? _format;
  String? _category;
  DateTime? _dueDate;
  final List<String> _tags = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Content'),
        actions: [
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *', hintText: 'Content title...'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'What is this content about?'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _stage,
                decoration: const InputDecoration(labelText: 'Stage'),
                items: AppConstants.contentStages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _stage = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: AppConstants.priorityLevels.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _platform,
                decoration: const InputDecoration(labelText: 'Platform'),
                items: AppConstants.contentPlatforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _platform = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _format,
                decoration: const InputDecoration(labelText: 'Format'),
                items: AppConstants.contentFormats.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (v) => setState(() => _format = v),
              ),
              const SizedBox(height: 16),
              // Due Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_dueDate != null ? 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}' : 'Set Due Date'),
                trailing: const Icon(Icons.calendar_today, size: 20),
                onTap: () async {
                  final date = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2030));
                  if (date != null) setState(() => _dueDate = date);
                },
              ),
              const SizedBox(height: 16),
              // Tags
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(labelText: 'Add Tags', hintText: 'Tag name'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_tagController.text.trim().isNotEmpty) {
                        setState(() { _tags.add(_tagController.text.trim()); _tagController.clear(); });
                      }
                    },
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _tags.map((t) => Chip(
                    label: Text(t, style: const TextStyle(fontSize: 12)),
                    onDeleted: () => setState(() => _tags.remove(t)),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes', hintText: 'Additional notes...'),
                maxLines: 4,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(contentRepositoryProvider).create(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        stage: _stage,
        priority: _priority,
        format: _format,
        platform: _platform,
        dueDate: _dueDate,
        tags: _tags,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      ref.invalidate(allContentProvider);
      ref.invalidate(contentByStageProvider);
      if (mounted) {
        context.showSuccess('Content created');
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
