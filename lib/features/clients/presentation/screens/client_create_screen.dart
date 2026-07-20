import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../services/database/repositories/client_repository.dart';
import '../../../../services/database/collections/client_collection.dart';
import '../../../../services/settings_service.dart';
import '../../../../core/utils/whatsapp_helper.dart';

class ClientCreateScreen extends ConsumerStatefulWidget {
  final ClientItem? editingClient;
  const ClientCreateScreen({super.key, this.editingClient});
  @override
  ConsumerState<ClientCreateScreen> createState() => _ClientCreateScreenState();
}

class _ClientCreateScreenState extends ConsumerState<ClientCreateScreen> {
  int _currentStep = 0;

  final _nameCtrl = TextEditingController(); 
  final _bizCtrl = TextEditingController(); 
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(); 
  final _webCtrl = TextEditingController(); 
  final _addressCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _retainerCtrl = TextEditingController();
  
  final _deliverablesCtrl = TextEditingController();
  final _socialLinksCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();
  final _brandColorsCtrl = TextEditingController();
  final _brandGuidelinesCtrl = TextEditingController();
  final _driveLinksCtrl = TextEditingController();
  final _socialAccessCtrl = TextEditingController();
  final _meetingNotesCtrl = TextEditingController();
  final _internalNotesCtrl = TextEditingController();

  DateTime? _deadline;
  String _status = 'Active';
  bool _isSaving = false;
  bool _isRetainer = false;

  bool get _isEditing => widget.editingClient != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.editingClient!;
      _nameCtrl.text = c.name;
      _bizCtrl.text = c.businessName ?? '';
      _emailCtrl.text = c.email ?? '';
      _phoneCtrl.text = c.phone ?? '';
      _webCtrl.text = c.website ?? '';
      _addressCtrl.text = c.address ?? '';
      _gstCtrl.text = c.gstNumber ?? '';
      _valueCtrl.text = c.projectValue > 0 ? c.projectValue.toString() : '';
      _retainerCtrl.text = c.retainerAmount > 0 ? c.retainerAmount.toString() : '';
      _isRetainer = c.isRetainer;
      
      _status = c.status;
      _deadline = c.deadline;
      _deliverablesCtrl.text = c.deliverables.join(', ');
      _socialLinksCtrl.text = c.socialLinks.join(', ');
      _logoUrlCtrl.text = c.logoUrl ?? '';
      _brandColorsCtrl.text = c.brandColors.join(', ');
      _brandGuidelinesCtrl.text = c.brandGuidelines ?? '';
      _driveLinksCtrl.text = c.driveLinks.join(', ');
      _socialAccessCtrl.text = c.socialMediaAccess ?? '';
      _meetingNotesCtrl.text = c.meetingNotes ?? '';
      _internalNotesCtrl.text = c.internalNotes ?? '';
    }
  }

  @override
  void dispose() { 
    _nameCtrl.dispose(); _bizCtrl.dispose(); _emailCtrl.dispose(); 
    _phoneCtrl.dispose(); _webCtrl.dispose(); _addressCtrl.dispose(); 
    _gstCtrl.dispose(); _valueCtrl.dispose(); 
    _retainerCtrl.dispose(); _deliverablesCtrl.dispose(); _socialLinksCtrl.dispose();
    _logoUrlCtrl.dispose(); _brandColorsCtrl.dispose(); _brandGuidelinesCtrl.dispose();
    _driveLinksCtrl.dispose(); _socialAccessCtrl.dispose(); _meetingNotesCtrl.dispose();
    _internalNotesCtrl.dispose();
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Client' : 'Add Client'), actions: [
        FilledButton(onPressed: _isSaving ? null : _save, child: const Text('Save')), 
        const SizedBox(width: 12)
      ]),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 5) {
            setState(() => _currentStep += 1);
          } else {
            _save();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        onStepTapped: (step) => setState(() => _currentStep = step),
        controlsBuilder: (context, details) {
          final isLast = _currentStep == 5;
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: [
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: Text(isLast ? 'Save Client' : 'Continue'),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Basic Information'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
            content: Column(children: [
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Client Name *')),
              const SizedBox(height: 16), 
              TextField(controller: _bizCtrl, decoration: const InputDecoration(labelText: 'Business Name')),
              const SizedBox(height: 16), 
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['Active', 'Completed', 'On Hold', 'Cancelled']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16), 
              TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16), 
              TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
              const SizedBox(height: 16), 
              TextField(controller: _webCtrl, decoration: const InputDecoration(labelText: 'Website')),
              const SizedBox(height: 16), 
              TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
              const SizedBox(height: 16), 
              TextField(controller: _gstCtrl, decoration: const InputDecoration(labelText: 'GST Number')),
            ]),
          ),
          Step(
            title: const Text('Financials'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
            content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Fixed Project')),
                  ButtonSegment(value: true, label: Text('Monthly Retainer')),
                ],
                selected: {_isRetainer},
                onSelectionChanged: (v) => setState(() => _isRetainer = v.first),
              ),
              const SizedBox(height: 16),
              if (!_isRetainer)
                TextField(controller: _valueCtrl, decoration: const InputDecoration(labelText: 'Fixed Project Value (₹)'), keyboardType: TextInputType.number)
              else
                TextField(controller: _retainerCtrl, decoration: const InputDecoration(labelText: 'Monthly Retainer Amount - MRR (₹)'), keyboardType: TextInputType.number),
            ]),
          ),
          Step(
            title: const Text('Project Details'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.editing,
            content: Column(children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_deadline == null ? 'Set Deadline' : 'Deadline: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'),
                trailing: const Icon(Icons.calendar_today, size: 20),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context, 
                    initialDate: _deadline ?? DateTime.now(), 
                    firstDate: DateTime(2020), 
                    lastDate: DateTime.now().add(const Duration(days: 3650))
                  );
                  if (d != null) setState(() => _deadline = d);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _deliverablesCtrl, 
                decoration: const InputDecoration(labelText: 'Deliverables (comma separated)'),
                maxLines: 2,
              ),
            ]),
          ),
          Step(
            title: const Text('Brand Assets'),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.editing,
            content: Column(children: [
              TextField(controller: _logoUrlCtrl, decoration: const InputDecoration(labelText: 'Logo URL')),
              const SizedBox(height: 16),
              TextField(
                controller: _brandColorsCtrl, 
                decoration: const InputDecoration(labelText: 'Brand Colors (comma separated HEX codes)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _brandGuidelinesCtrl, 
                decoration: const InputDecoration(labelText: 'Brand Guidelines / Typography Notes'),
                maxLines: 2,
              ),
            ]),
          ),
          Step(
            title: const Text('Links & Access'),
            isActive: _currentStep >= 4,
            state: _currentStep > 4 ? StepState.complete : StepState.editing,
            content: Column(children: [
              TextField(
                controller: _driveLinksCtrl, 
                decoration: const InputDecoration(labelText: 'Drive/Folder Links (comma separated)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _socialLinksCtrl, 
                decoration: const InputDecoration(labelText: 'Social Media Links (comma separated)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _socialAccessCtrl, 
                decoration: const InputDecoration(labelText: 'Social Media Access Credentials'),
                maxLines: 2,
              ),
            ]),
          ),
          Step(
            title: const Text('Notes'),
            isActive: _currentStep >= 5,
            state: StepState.editing,
            content: Column(children: [
              TextField(
                controller: _meetingNotesCtrl, 
                decoration: const InputDecoration(labelText: 'Meeting Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _internalNotesCtrl, 
                decoration: const InputDecoration(labelText: 'Internal Notes'),
                maxLines: 3,
              ),
            ]),
          ),
        ],
      ),
    );
  }

  List<String> _parseList(String text) {
    return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) { context.showSnackBar('Name required', isError: true); return; }
    setState(() => _isSaving = true);

    if (_isEditing) {
      final c = widget.editingClient!;
      c.name = _nameCtrl.text.trim();
      c.businessName = _bizCtrl.text.trim().isEmpty ? null : _bizCtrl.text.trim();
      c.email = _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim();
      c.phone = _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim();
      c.website = _webCtrl.text.trim().isEmpty ? null : _webCtrl.text.trim();
      c.address = _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim();
      c.gstNumber = _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim();
      c.isRetainer = _isRetainer;
      c.projectValue = !_isRetainer ? (double.tryParse(_valueCtrl.text) ?? 0) : 0;
      c.retainerAmount = _isRetainer ? (double.tryParse(_retainerCtrl.text) ?? 0) : 0;
      
      c.status = _status;
      c.deadline = _deadline;
      c.deliverables = _parseList(_deliverablesCtrl.text);
      c.socialLinks = _parseList(_socialLinksCtrl.text);
      c.logoUrl = _logoUrlCtrl.text.trim().isEmpty ? null : _logoUrlCtrl.text.trim();
      c.brandColors = _parseList(_brandColorsCtrl.text);
      c.brandGuidelines = _brandGuidelinesCtrl.text.trim().isEmpty ? null : _brandGuidelinesCtrl.text.trim();
      c.driveLinks = _parseList(_driveLinksCtrl.text);
      c.socialMediaAccess = _socialAccessCtrl.text.trim().isEmpty ? null : _socialAccessCtrl.text.trim();
      c.meetingNotes = _meetingNotesCtrl.text.trim().isEmpty ? null : _meetingNotesCtrl.text.trim();
      c.internalNotes = _internalNotesCtrl.text.trim().isEmpty ? null : _internalNotesCtrl.text.trim();
      
      await ref.read(clientRepositoryProvider).update(c);
    } else {
      await ref.read(clientRepositoryProvider).create(
        name: _nameCtrl.text.trim(), 
        businessName: _bizCtrl.text.trim().isEmpty ? null : _bizCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(), 
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        website: _webCtrl.text.trim().isEmpty ? null : _webCtrl.text.trim(), 
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        gstNumber: _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim(),
        projectValue: !_isRetainer ? (double.tryParse(_valueCtrl.text) ?? 0) : 0,
        isRetainer: _isRetainer, 
        retainerAmount: _isRetainer ? (double.tryParse(_retainerCtrl.text) ?? 0) : 0,
        status: _status,
        deadline: _deadline,
        deliverables: _parseList(_deliverablesCtrl.text),
        socialLinks: _parseList(_socialLinksCtrl.text),
        logoUrl: _logoUrlCtrl.text.trim().isEmpty ? null : _logoUrlCtrl.text.trim(),
        brandColors: _parseList(_brandColorsCtrl.text),
        brandGuidelines: _brandGuidelinesCtrl.text.trim().isEmpty ? null : _brandGuidelinesCtrl.text.trim(),
        driveLinks: _parseList(_driveLinksCtrl.text),
        socialMediaAccess: _socialAccessCtrl.text.trim().isEmpty ? null : _socialAccessCtrl.text.trim(),
        meetingNotes: _meetingNotesCtrl.text.trim().isEmpty ? null : _meetingNotesCtrl.text.trim(),
        internalNotes: _internalNotesCtrl.text.trim().isEmpty ? null : _internalNotesCtrl.text.trim(),
      );
    }

    ref.invalidate(allClientsProvider); 
    ref.invalidate(activeClientCountProvider); 
    ref.invalidate(pendingPaymentsProvider);
    
    if (mounted) { 
      if (!_isEditing && _phoneCtrl.text.trim().isNotEmpty) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Send Welcome Message?'),
            content: const Text('Would you like to send an Islamic welcome message to this client via WhatsApp?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.pop();
                }, 
                child: const Text('Skip')
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  context.pop();
                  final settings = ref.read(settingsServiceProvider);
                  final agencyName = settings.agencyName.isEmpty ? 'Our Agency' : settings.agencyName;
                  final msg = WhatsAppHelper.getWelcomeMessage(_nameCtrl.text.trim(), agencyName);
                  try {
                    await WhatsAppHelper.launchWhatsApp(_phoneCtrl.text.trim(), msg);
                  } catch (e) {
                    if (mounted) context.showSnackBar(e.toString(), isError: true);
                  }
                }, 
                child: const Text('Send via WhatsApp')
              ),
            ]
          )
        );
      } else {
        context.showSuccess(_isEditing ? 'Client updated' : 'Client added'); 
        context.pop(); 
      }
    }
  }
}
