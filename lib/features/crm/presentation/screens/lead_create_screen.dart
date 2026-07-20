import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../services/database/repositories/lead_repository.dart';
import '../../../../services/database/collections/lead_collection.dart';

class LeadCreateScreen extends ConsumerStatefulWidget {
  final LeadItem? editingLead;
  const LeadCreateScreen({super.key, this.editingLead});
  @override
  ConsumerState<LeadCreateScreen> createState() => _LeadCreateScreenState();
}

class _LeadCreateScreenState extends ConsumerState<LeadCreateScreen> {
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dealController = TextEditingController();
  final _notesController = TextEditingController();
  String _stage = 'New Lead';
  String? _source;
  String? _industry;
  DateTime? _followUp;
  bool _isSaving = false;

  bool get _isEditing => widget.editingLead != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final lead = widget.editingLead!;
      _nameController.text = lead.name;
      _companyController.text = lead.company ?? '';
      _emailController.text = lead.email ?? '';
      _phoneController.text = lead.phone ?? '';
      _dealController.text = lead.dealValue > 0 ? lead.dealValue.toString() : '';
      _notesController.text = lead.notes ?? '';
      _stage = lead.stage;
      _source = lead.leadSource;
      _industry = lead.industry;
      _followUp = lead.followUpDate;
    }
  }

  @override
  void dispose() { _nameController.dispose(); _companyController.dispose(); _emailController.dispose(); _phoneController.dispose(); _dealController.dispose(); _notesController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Lead' : 'Add Lead'), actions: [FilledButton(onPressed: _isSaving ? null : _save, child: const Text('Save')), const SizedBox(width: 12)]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name *')),
          const SizedBox(height: 16),
          TextField(controller: _companyController, decoration: const InputDecoration(labelText: 'Company')),
          const SizedBox(height: 16),
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          TextField(controller: _dealController, decoration: const InputDecoration(labelText: 'Deal Value (₹)', prefixText: '₹ '), keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(initialValue: _stage, decoration: const InputDecoration(labelText: 'Stage'), items: AppConstants.crmStages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _stage = v!)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(initialValue: _source, decoration: const InputDecoration(labelText: 'Lead Source'), items: AppConstants.leadSources.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _source = v)),
          const SizedBox(height: 16),
          ListTile(contentPadding: EdgeInsets.zero, title: Text(_followUp != null ? 'Follow-up: ${_followUp!.day}/${_followUp!.month}/${_followUp!.year}' : 'Set Follow-up Date'), trailing: const Icon(Icons.calendar_today, size: 20), onTap: () async {
            final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2030));
            if (d != null) setState(() => _followUp = d);
          }),
          const SizedBox(height: 16),
          TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) { context.showSnackBar('Name is required', isError: true); return; }
    setState(() => _isSaving = true);

    if (_isEditing) {
      final lead = widget.editingLead!;
      lead.name = _nameController.text.trim();
      lead.company = _companyController.text.trim().isEmpty ? null : _companyController.text.trim();
      lead.email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
      lead.phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
      lead.dealValue = double.tryParse(_dealController.text) ?? 0;
      lead.stage = _stage;
      lead.leadSource = _source;
      lead.followUpDate = _followUp;
      lead.notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
      await ref.read(leadRepositoryProvider).update(lead);
    } else {
      await ref.read(leadRepositoryProvider).create(
        name: _nameController.text.trim(), company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(), phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        dealValue: double.tryParse(_dealController.text) ?? 0, stage: _stage, leadSource: _source, followUpDate: _followUp,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    }

    ref.invalidate(allLeadsProvider); ref.invalidate(leadsByStageProvider); ref.invalidate(activeLeadCountProvider); ref.invalidate(pipelineValueProvider);
    if (mounted) { context.showSuccess(_isEditing ? 'Lead updated' : 'Lead added'); context.pop(); }
  }
}
