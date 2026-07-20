import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../services/database/repositories/resource_repository.dart';

class ResourceCreateScreen extends ConsumerStatefulWidget {
  const ResourceCreateScreen({super.key});
  @override
  ConsumerState<ResourceCreateScreen> createState() => _ResourceCreateScreenState();
}

class _ResourceCreateScreenState extends ConsumerState<ResourceCreateScreen> {
  final _nameCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String _type = AppConstants.resourceTypes.first;
  String _priority = 'Medium';
  bool _isPurchased = true;
  DateTime? _renewalDate;
  DateTime? _targetDate;
  bool _isSaving = false;

  @override
  void dispose() { _nameCtrl.dispose(); _costCtrl.dispose(); _descCtrl.dispose(); _reasonCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Resource'), actions: [FilledButton(onPressed: _isSaving ? null : _save, child: const Text('Save')), const SizedBox(width: 12)]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          SegmentedButton<bool>(segments: const [
            ButtonSegment(value: true, label: Text('Existing')), ButtonSegment(value: false, label: Text('Wishlist'))
          ], selected: {_isPurchased}, onSelectionChanged: (v) => setState(() => _isPurchased = v.first)),
          const SizedBox(height: 20),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(initialValue: _type, decoration: const InputDecoration(labelText: 'Type'),
            items: AppConstants.resourceTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _type = v!)),
          const SizedBox(height: 16),
          TextField(controller: _costCtrl, decoration: InputDecoration(labelText: _isPurchased ? 'Cost (₹)' : 'Estimated Cost (₹)', prefixText: '₹ '), keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
          if (_isPurchased) ...[
            const SizedBox(height: 16),
            ListTile(contentPadding: EdgeInsets.zero,
              title: Text(_renewalDate != null ? 'Renewal: ${_renewalDate!.day}/${_renewalDate!.month}/${_renewalDate!.year}' : 'Set Renewal Date'),
              trailing: const Icon(Icons.calendar_today, size: 20),
              onTap: () async { final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2030)); if (d != null) setState(() => _renewalDate = d); }),
          ] else ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(initialValue: _priority, decoration: const InputDecoration(labelText: 'Priority'),
              items: AppConstants.priorityLevels.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (v) => setState(() => _priority = v!)),
            const SizedBox(height: 16),
            TextField(controller: _reasonCtrl, decoration: const InputDecoration(labelText: 'Purchase Reason'), maxLines: 2),
            const SizedBox(height: 16),
            ListTile(contentPadding: EdgeInsets.zero,
              title: Text(_targetDate != null ? 'Target: ${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}' : 'Target Purchase Date'),
              trailing: const Icon(Icons.calendar_today, size: 20),
              onTap: () async { final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2030)); if (d != null) setState(() => _targetDate = d); }),
          ],
        ]),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) { context.showSnackBar('Name required', isError: true); return; }
    setState(() => _isSaving = true);
    await ref.read(resourceRepositoryProvider).create(
      name: _nameCtrl.text.trim(), type: _type, isPurchased: _isPurchased,
      cost: _isPurchased ? (double.tryParse(_costCtrl.text) ?? 0) : 0,
      estimatedCost: !_isPurchased ? (double.tryParse(_costCtrl.text) ?? 0) : 0,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      renewalDate: _renewalDate, priority: _priority,
      purchaseReason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
      targetPurchaseDate: _targetDate,
    );
    ref.invalidate(allResourcesProvider); ref.invalidate(existingResourcesProvider); ref.invalidate(wishlistResourcesProvider);
    if (mounted) { context.showSuccess('Resource added'); context.pop(); }
  }
}
