import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../services/database/repositories/journal_repository.dart';
import '../../../../services/database/collections/journal_collection.dart';
import '../../../../core/widgets/premium_background.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final entries = ref.watch(allJournalProvider);
    final todayEntry = ref.watch(todayJournalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Journal'), actions: [
        IconButton(icon: const Icon(Icons.search, size: 22), onPressed: () {}),
        IconButton(icon: const Icon(Icons.bar_chart, size: 22), onPressed: () => _showStats(context, ref)),
      ]),
      body: PremiumBackground(
        child: entries.when(
          data: (items) {
            return CustomScrollView(
              slivers: [
              // Today's entry card
              SliverToBoxAdapter(
                child: todayEntry.when(
                  data: (today) {
                    if (today == null) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [colors.primary.withValues(alpha: 0.1), colors.secondary.withValues(alpha: 0.05)]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Icon(Icons.edit_note, color: colors.primary),
                              const SizedBox(width: 8),
                              Text("Today's Reflection", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            ]),
                            const SizedBox(height: 8),
                            Text('Take a moment to reflect on your day', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 12),
                            FilledButton(onPressed: () => context.go('/journal/create'), child: const Text('Write Entry')),
                          ]),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                        child: Row(children: [
                          const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text("Today's reflection completed!", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                          _MoodEmoji(mood: today.mood),
                        ]),
                      ),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ),
              // Entry list
              if (items.isEmpty)
                SliverFillRemaining(child: EmptyStateWidget(icon: Icons.menu_book_outlined, title: 'No journal entries', subtitle: 'Start your daily reflection practice', actionLabel: 'Write First Entry', onAction: () => context.go('/journal/create')))
              else
                SliverList(delegate: SliverChildBuilderDelegate((context, index) {
                  final entry = items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: _MoodEmoji(mood: entry.mood),
                      title: Text(entry.date.formattedDay, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text(entry.date.formatted, style: theme.textTheme.labelSmall),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () {},
                    ),
                  );
                }, childCount: items.length)),
            ],
          );
        },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.go('/journal/create'), icon: const Icon(Icons.edit), label: const Text('Write')),
    );
  }

  void _showStats(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final repo = ref.read(journalRepositoryProvider);
    final allEntries = await repo.getAll();
    final totalEntries = allEntries.length;
    final avgMood = totalEntries > 0
        ? allEntries.fold(0.0, (sum, e) => sum + e.mood) / totalEntries
        : 0.0;

    // Mood distribution
    final moodDist = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final e in allEntries) {
      moodDist[e.mood] = (moodDist[e.mood] ?? 0) + 1;
    }

    // Current streak
    int streak = 0;
    if (allEntries.isNotEmpty) {
      final sorted = List<JournalEntry>.from(allEntries)
        ..sort((a, b) => b.date.compareTo(a.date));
      DateTime checkDate = DateTime.now();
      // If no entry today, start from yesterday
      final todayStart = DateTime(checkDate.year, checkDate.month, checkDate.day);
      final hasToday = sorted.any((e) {
        final eDate = DateTime(e.date.year, e.date.month, e.date.day);
        return eDate == todayStart;
      });
      if (!hasToday) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      for (int i = 0; i < 365; i++) {
        final targetDate = DateTime(checkDate.year, checkDate.month, checkDate.day).subtract(Duration(days: i));
        final hasEntry = sorted.any((e) {
          final eDate = DateTime(e.date.year, e.date.month, e.date.day);
          return eDate == targetDate;
        });
        if (hasEntry) {
          streak++;
        } else {
          break;
        }
      }
    }

    // Entries this month
    final now = DateTime.now();
    final thisMonth = allEntries.where((e) =>
        e.date.year == now.year && e.date.month == now.month).length;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: colors.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
            Text('Journal Stats', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            // Stats grid
            Row(children: [
              Expanded(child: _StatTile(label: 'Total Entries', value: '$totalEntries', icon: Icons.menu_book, color: const Color(0xFF3B82F6))),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(label: 'Avg Mood', value: avgMood.toStringAsFixed(1), icon: Icons.mood, color: const Color(0xFFF59E0B))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _StatTile(label: 'Current Streak', value: '$streak day${streak == 1 ? '' : 's'}', icon: Icons.local_fire_department, color: const Color(0xFFEF4444))),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(label: 'This Month', value: '$thisMonth', icon: Icons.calendar_month, color: const Color(0xFF22C55E))),
            ]),
            const SizedBox(height: 24),

            // Mood distribution
            Text('Mood Distribution', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (totalEntries > 0)
              SizedBox(
                height: 160,
                child: BarChart(BarChartData(
                  barGroups: moodDist.entries.map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [BarChartRodData(
                      toY: e.value.toDouble(),
                      color: _moodColor(e.key),
                      width: 32,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    )],
                  )).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                      const emojis = {1: '😔', 2: '😕', 3: '😐', 4: '🙂', 5: '😊'};
                      return Text(emojis[v.toInt()] ?? '', style: const TextStyle(fontSize: 18));
                    })),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: TextStyle(fontSize: 10, color: colors.onSurface.withValues(alpha: 0.4))))),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (v) => FlLine(color: colors.outline.withValues(alpha: 0.08), strokeWidth: 1)),
                )),
              )
            else
              Center(child: Text('No entries yet', style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.4)))),
          ]),
        ),
      ),
    );
  }

  Color _moodColor(int mood) {
    switch (mood) {
      case 1: return const Color(0xFFEF4444);
      case 2: return const Color(0xFFF59E0B);
      case 3: return const Color(0xFF94A3B8);
      case 4: return const Color(0xFF22C55E);
      case 5: return const Color(0xFF3B82F6);
      default: return const Color(0xFF94A3B8);
    }
  }
}

class _StatTile extends StatelessWidget {
  final String label; final String value; final IconData icon; final Color color;
  const _StatTile({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 8),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
        Text(label, style: theme.textTheme.labelSmall),
      ]),
    );
  }
}

class _MoodEmoji extends StatelessWidget {
  final int mood;
  const _MoodEmoji({required this.mood});

  String get emoji {
    switch (mood) { case 1: return '😔'; case 2: return '😕'; case 3: return '😐'; case 4: return '🙂'; case 5: return '😊'; default: return '😐'; }
  }

  @override
  Widget build(BuildContext context) => Text(emoji, style: const TextStyle(fontSize: 24));
}
