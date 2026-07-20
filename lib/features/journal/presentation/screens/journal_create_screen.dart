import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../services/database/repositories/journal_repository.dart';

class JournalCreateScreen extends ConsumerStatefulWidget {
  const JournalCreateScreen({super.key});
  @override
  ConsumerState<JournalCreateScreen> createState() => _JournalCreateScreenState();
}

class _JournalCreateScreenState extends ConsumerState<JournalCreateScreen> {
  final _wellCtrl = TextEditingController();
  final _notWellCtrl = TextEditingController();
  final _lessonsCtrl = TextEditingController();
  final _winsCtrl = TextEditingController();
  final _mistakesCtrl = TextEditingController();
  final _gratitudeCtrl = TextEditingController();
  final _tomorrowCtrl = TextEditingController();
  int _mood = 3;
  bool _isSaving = false;

  @override
  void dispose() { _wellCtrl.dispose(); _notWellCtrl.dispose(); _lessonsCtrl.dispose(); _winsCtrl.dispose(); _mistakesCtrl.dispose(); _gratitudeCtrl.dispose(); _tomorrowCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Reflection'), actions: [FilledButton(onPressed: _isSaving ? null : _save, child: const Text('Save')), const SizedBox(width: 12)]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Mood selector
          Text('How are you feeling?', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (i) {
            final mood = i + 1;
            final emojis = ['😔', '😕', '😐', '🙂', '😊'];
            final selected = _mood == mood;
            return GestureDetector(
              onTap: () => setState(() => _mood = mood),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? colors.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? colors.primary : colors.outline.withValues(alpha: 0.2), width: selected ? 2 : 1),
                ),
                child: Text(emojis[i], style: TextStyle(fontSize: selected ? 32 : 24)),
              ),
            );
          })),
          const SizedBox(height: 24),
          _JournalField(controller: _wellCtrl, label: '✅ What Went Well', hint: 'Celebrate your wins...'),
          _JournalField(controller: _notWellCtrl, label: '❌ What Didn\'t Go Well', hint: 'Be honest with yourself...'),
          _JournalField(controller: _lessonsCtrl, label: '📚 Lessons Learned', hint: 'What did you learn today?'),
          _JournalField(controller: _winsCtrl, label: '🏆 Wins', hint: 'Big or small victories...'),
          _JournalField(controller: _mistakesCtrl, label: '⚠️ Mistakes', hint: 'Mistakes are lessons in disguise...'),
          _JournalField(controller: _gratitudeCtrl, label: '🙏 Gratitude', hint: 'What are you grateful for?'),
          _JournalField(controller: _tomorrowCtrl, label: '🎯 Improvements for Tomorrow', hint: 'How will you be better tomorrow?'),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await ref.read(journalRepositoryProvider).create(
      date: DateTime.now(), mood: _mood,
      wentWell: _wellCtrl.text.trim().isEmpty ? null : _wellCtrl.text.trim(),
      didNotGoWell: _notWellCtrl.text.trim().isEmpty ? null : _notWellCtrl.text.trim(),
      lessonsLearned: _lessonsCtrl.text.trim().isEmpty ? null : _lessonsCtrl.text.trim(),
      wins: _winsCtrl.text.trim().isEmpty ? null : _winsCtrl.text.trim(),
      mistakes: _mistakesCtrl.text.trim().isEmpty ? null : _mistakesCtrl.text.trim(),
      gratitude: _gratitudeCtrl.text.trim().isEmpty ? null : _gratitudeCtrl.text.trim(),
      improvementsForTomorrow: _tomorrowCtrl.text.trim().isEmpty ? null : _tomorrowCtrl.text.trim(),
    );
    ref.invalidate(allJournalProvider); ref.invalidate(todayJournalProvider);
    if (mounted) { context.showSuccess('Journal saved'); context.pop(); }
  }
}

class _JournalField extends StatelessWidget {
  final TextEditingController controller; final String label; final String hint;
  const _JournalField({required this.controller, required this.label, required this.hint});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextField(controller: controller, decoration: InputDecoration(hintText: hint), maxLines: 3),
    ]));
  }
}
