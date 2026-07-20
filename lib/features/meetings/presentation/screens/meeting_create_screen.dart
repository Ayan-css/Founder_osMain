import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../services/database/repositories/meeting_repository.dart';
import '../../../../services/database/collections/meeting_collection.dart';

class MeetingCreateScreen extends ConsumerStatefulWidget {
  final MeetingItem? editingMeeting;
  const MeetingCreateScreen({super.key, this.editingMeeting});
  @override
  ConsumerState<MeetingCreateScreen> createState() => _MeetingCreateScreenState();
}

class _MeetingCreateScreenState extends ConsumerState<MeetingCreateScreen> {
  final _titleCtrl = TextEditingController();
  final _agendaCtrl = TextEditingController();
  final _participantCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _requirementsCtrl = TextEditingController();
  final _decisionsCtrl = TextEditingController();
  final _actionItemCtrl = TextEditingController();
  String _type = 'internal';
  DateTime _date = DateTime.now().add(const Duration(hours: 1));
  final List<String> _participants = [];
  final List<String> _actionItems = [];
  String? _clientName;
  bool _isSaving = false;

  bool get _isEditing => widget.editingMeeting != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final m = widget.editingMeeting!;
      _titleCtrl.text = m.title;
      _agendaCtrl.text = m.agenda ?? '';
      _notesCtrl.text = m.notes ?? '';
      _requirementsCtrl.text = m.requirements ?? '';
      _decisionsCtrl.text = m.decisions ?? '';
      _type = m.type;
      _date = m.date;
      _participants.addAll(m.participants);
      _actionItems.addAll(m.actionItems);
      _clientName = m.clientName;
    }
  }

  @override
  void dispose() { _titleCtrl.dispose(); _agendaCtrl.dispose(); _participantCtrl.dispose(); _notesCtrl.dispose(); _requirementsCtrl.dispose(); _decisionsCtrl.dispose(); _actionItemCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Meeting' : 'Schedule Meeting'), actions: [FilledButton(onPressed: _isSaving ? null : _save, child: const Text('Save')), const SizedBox(width: 12)]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        SegmentedButton<String>(segments: const [
          ButtonSegment(value: 'internal', label: Text('Internal')), ButtonSegment(value: 'client', label: Text('Client')),
        ], selected: {_type}, onSelectionChanged: (v) => setState(() => _type = v.first)),
        const SizedBox(height: 20),
        TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Meeting Title *')),
        const SizedBox(height: 16),
        if (_type == 'client') ...[
          TextField(
            onChanged: (v) => _clientName = v,
            decoration: const InputDecoration(labelText: 'Client Name'),
            controller: TextEditingController(text: _clientName),
          ),
          const SizedBox(height: 16),
        ],
        ListTile(contentPadding: EdgeInsets.zero, title: Text('${_date.day}/${_date.month}/${_date.year} at ${_date.hour}:${_date.minute.toString().padLeft(2, '0')}'),
          subtitle: const Text('Tap to change date & time'), trailing: const Icon(Icons.calendar_today, size: 20),
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(2030));
            if (d != null && context.mounted) {
              final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
              if (t != null) setState(() => _date = DateTime(d.year, d.month, d.day, t.hour, t.minute));
            }
          }),
        const SizedBox(height: 16),
        TextField(controller: _agendaCtrl, decoration: const InputDecoration(labelText: 'Agenda'), maxLines: 3),
        const SizedBox(height: 16),

        // Participants
        Row(children: [
          Expanded(child: TextField(controller: _participantCtrl, decoration: const InputDecoration(labelText: 'Add Participant'))),
          IconButton(icon: const Icon(Icons.add), onPressed: () {
            if (_participantCtrl.text.trim().isNotEmpty) { setState(() { _participants.add(_participantCtrl.text.trim()); _participantCtrl.clear(); }); }
          }),
        ]),
        if (_participants.isNotEmpty) Wrap(spacing: 8, children: _participants.map((p) => Chip(label: Text(p), onDeleted: () => setState(() => _participants.remove(p)))).toList()),

        if (_isEditing) ...[
          const SizedBox(height: 24),
          Text('Post-Meeting Notes', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Meeting Notes'), maxLines: 3),
          const SizedBox(height: 16),
          TextField(controller: _requirementsCtrl, decoration: const InputDecoration(labelText: 'Requirements'), maxLines: 2),
          const SizedBox(height: 16),
          TextField(controller: _decisionsCtrl, decoration: const InputDecoration(labelText: 'Decisions Made'), maxLines: 2),
          const SizedBox(height: 16),

          // Action Items
          Row(children: [
            Expanded(child: TextField(controller: _actionItemCtrl, decoration: const InputDecoration(labelText: 'Add Action Item'))),
            IconButton(icon: const Icon(Icons.add), onPressed: () {
              if (_actionItemCtrl.text.trim().isNotEmpty) { setState(() { _actionItems.add(_actionItemCtrl.text.trim()); _actionItemCtrl.clear(); }); }
            }),
          ]),
          if (_actionItems.isNotEmpty) ...[ 
            const SizedBox(height: 8),
            ..._actionItems.asMap().entries.map((e) => ListTile(
              contentPadding: EdgeInsets.zero, dense: true,
              leading: Icon(Icons.check_circle_outline, size: 18, color: theme.colorScheme.primary),
              title: Text(e.value, style: theme.textTheme.bodySmall),
              trailing: IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _actionItems.removeAt(e.key))),
            )),
          ],
        ],
      ])),
    );
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty) { context.showSnackBar('Title required', isError: true); return; }
    setState(() => _isSaving = true);

    if (_isEditing) {
      final m = widget.editingMeeting!;
      m.type = _type;
      m.title = _titleCtrl.text.trim();
      m.date = _date;
      m.agenda = _agendaCtrl.text.trim().isEmpty ? null : _agendaCtrl.text.trim();
      m.participants = _participants;
      m.clientName = _clientName;
      m.notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
      m.requirements = _requirementsCtrl.text.trim().isEmpty ? null : _requirementsCtrl.text.trim();
      m.decisions = _decisionsCtrl.text.trim().isEmpty ? null : _decisionsCtrl.text.trim();
      m.actionItems = _actionItems;
      await ref.read(meetingRepositoryProvider).update(m);
    } else {
      await ref.read(meetingRepositoryProvider).create(
        type: _type, title: _titleCtrl.text.trim(), date: _date,
        agenda: _agendaCtrl.text.trim().isEmpty ? null : _agendaCtrl.text.trim(),
        participants: _participants, clientName: _clientName,
      );
    }

    ref.invalidate(allMeetingsProvider); ref.invalidate(upcomingMeetingsProvider); ref.invalidate(todayMeetingsProvider);
    if (mounted) { context.showSuccess(_isEditing ? 'Meeting updated' : 'Meeting scheduled'); context.pop(); }
  }
}
