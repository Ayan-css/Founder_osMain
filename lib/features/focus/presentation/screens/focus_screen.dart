import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/database/repositories/focus_repository.dart';
import '../../../../core/widgets/premium_background.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});
  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  bool _isRunning = false;
  String _mode = 'Pomodoro';
  int _selectedDuration = 25;
  String? _currentSessionId;

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _startTimer() async {
    if (_isRunning) return;
    _totalSeconds = _selectedDuration * 60;
    _remainingSeconds = _totalSeconds;

    final session = await ref.read(focusRepositoryProvider).create(type: _mode, durationMinutes: _selectedDuration);
    _currentSessionId = session.id;

    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _completeSession();
      }
    });
  }

  void _pauseTimer() { _timer?.cancel(); setState(() => _isRunning = false); }

  void _resetTimer() {
    _timer?.cancel();
    setState(() { _isRunning = false; _remainingSeconds = 0; _totalSeconds = 0; });
  }

  void _completeSession() async {
    _timer?.cancel();
    if (_currentSessionId != null) {
      await ref.read(focusRepositoryProvider).completeSession(_currentSessionId!);
      ref.invalidate(allFocusSessionsProvider); ref.invalidate(todayFocusMinutesProvider);
      ref.invalidate(weekFocusMinutesProvider); ref.invalidate(monthFocusMinutesProvider);
    }
    setState(() { _isRunning = false; _remainingSeconds = 0; _totalSeconds = 0; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Session completed! Great focus!')));
    }
  }

  double get _progress => _totalSeconds > 0 ? (_totalSeconds - _remainingSeconds) / _totalSeconds : 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final todayMins = ref.watch(todayFocusMinutesProvider);
    final weekMins = ref.watch(weekFocusMinutesProvider);
    final streak = ref.watch(focusStreakProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Focus')),
      body: PremiumBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Stats
          Row(children: [
            Expanded(child: StatCard(title: 'Today', icon: Icons.today, iconColor: context.statusColors.info,
              value: todayMins.when(data: (v) => AppFormatters.duration(v), loading: () => '...', error: (_, __) => '—'))),
            const SizedBox(width: 10),
            Expanded(child: StatCard(title: 'Week', icon: Icons.date_range, iconColor: context.statusColors.info,
              value: weekMins.when(data: (v) => AppFormatters.duration(v), loading: () => '...', error: (_, __) => '—'))),
            const SizedBox(width: 10),
            Expanded(child: StatCard(title: 'Streak', icon: Icons.local_fire_department, iconColor: context.statusColors.warning,
              value: streak.when(data: (v) => '${v}d', loading: () => '...', error: (_, __) => '—'))),
          ]),
          const SizedBox(height: 32),

          // Timer display
          SizedBox(
            width: 240, height: 240,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 240, height: 240, child: CircularProgressIndicator(
                value: _progress, strokeWidth: 8, backgroundColor: colors.surfaceContainerHighest,
                color: _mode == 'Pomodoro' ? context.statusColors.error : _mode == 'Deep Work' ? context.statusColors.info : colors.primary,
              )),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(AppFormatters.durationFromSeconds(_remainingSeconds), style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                const SizedBox(height: 4),
                Text(_mode, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.5))),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          // Controls
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_isRunning || _remainingSeconds > 0) ...[
              IconButton.filled(icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow), iconSize: 32, onPressed: _isRunning ? _pauseTimer : _startTimer),
              const SizedBox(width: 16),
              IconButton.outlined(icon: const Icon(Icons.stop), iconSize: 32, onPressed: _resetTimer),
            ] else
              FilledButton.icon(icon: const Icon(Icons.play_arrow), label: const Text('Start Focus'), onPressed: _startTimer,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16))),
          ]),
          const SizedBox(height: 32),

          // Mode selector
          if (!_isRunning && _remainingSeconds == 0) ...[
            Text('Select Mode', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SegmentedButton<String>(segments: const [
              ButtonSegment(value: 'Pomodoro', label: Text('Pomodoro')),
              ButtonSegment(value: 'Deep Work', label: Text('Deep Work')),
              ButtonSegment(value: 'Custom', label: Text('Custom')),
            ], selected: {_mode}, onSelectionChanged: (v) {
              setState(() { _mode = v.first;
                if (_mode == 'Pomodoro') {
                  _selectedDuration = 25;
                } else if (_mode == 'Deep Work') _selectedDuration = 90;
              });
            }),
            const SizedBox(height: 16),

            // Duration options
            if (_mode == 'Pomodoro')
              Wrap(spacing: 8, children: [
                ChoiceChip(label: const Text('25 / 5'), selected: _selectedDuration == 25, onSelected: (_) => setState(() => _selectedDuration = 25)),
                ChoiceChip(label: const Text('50 / 10'), selected: _selectedDuration == 50, onSelected: (_) => setState(() => _selectedDuration = 50)),
              ]),
            if (_mode == 'Deep Work')
              Wrap(spacing: 8, children: AppConstants.deepWorkDurations.map((d) =>
                ChoiceChip(label: Text('${d}m'), selected: _selectedDuration == d, onSelected: (_) => setState(() => _selectedDuration = d)),
              ).toList()),
            if (_mode == 'Custom') ...[
              Slider(value: _selectedDuration.toDouble(), min: 5, max: 180, divisions: 35,
                label: '${_selectedDuration}m', onChanged: (v) => setState(() => _selectedDuration = v.round())),
              Text('$_selectedDuration minutes', style: theme.textTheme.bodySmall),
            ],
          ],
          const SizedBox(height: 24),

          // Session history
          Text('Recent Sessions', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _SessionHistory(),
        ]),
      )),
    );
  }
}

class _SessionHistory extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sessions = ref.watch(allFocusSessionsProvider);

    return sessions.when(
      data: (items) {
        if (items.isEmpty) return Padding(padding: const EdgeInsets.all(16), child: Text('No sessions yet', style: theme.textTheme.bodySmall));
        return Column(children: items.take(10).map((s) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(s.completed ? Icons.check_circle : Icons.cancel, size: 20, color: s.completed ? context.statusColors.success : context.statusColors.error),
            title: Text('${s.type} - ${s.durationMinutes}m', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text('${s.startTime.day}/${s.startTime.month} at ${s.startTime.hour}:${s.startTime.minute.toString().padLeft(2, '0')}', style: theme.textTheme.labelSmall),
          ),
        )).toList());
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }
}
