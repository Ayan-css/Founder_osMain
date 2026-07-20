import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../services/database/repositories/meeting_repository.dart';
import '../../../../services/database/collections/meeting_collection.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import '../../../../core/widgets/premium_background.dart';

class MeetingsScreen extends ConsumerWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final meetings = ref.watch(allMeetingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meetings'), actions: [
        IconButton(icon: const Icon(Icons.search, size: 22), onPressed: () {}),
      ]),
      body: PremiumBackground(
        child: meetings.when(
          data: (items) {
            if (items.isEmpty) return EmptyStateWidget(icon: Icons.groups_outlined, title: 'No meetings yet', subtitle: 'Schedule your first meeting', actionLabel: 'Add Meeting', onAction: () => context.go('/meetings/create'));

          // Group by upcoming vs past
          final now = DateTime.now();
          final upcoming = items.where((m) => m.date.isAfter(now)).toList();
          final past = items.where((m) => !m.date.isAfter(now)).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcoming.isNotEmpty) ...[
                Text('Upcoming', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...upcoming.map((m) => _MeetingCard(meeting: m)),
                const SizedBox(height: 24),
              ],
              if (past.isNotEmpty) ...[
                Text('Past Meetings', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colors.onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 8),
                ...past.take(20).map((m) => _MeetingCard(meeting: m)),
              ],
            ],
          );
        },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.go('/meetings/create'), icon: const Icon(Icons.add), label: const Text('Schedule')),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final MeetingItem meeting;
  const _MeetingCard({required this.meeting});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isClient = meeting.type == 'client';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.go('/meetings/${meeting.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 4, height: 50,
              decoration: BoxDecoration(color: isClient ? const Color(0xFF8B5CF6) : colors.primary, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(meeting.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.access_time, size: 14, color: colors.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(meeting.date.formattedWithTime, style: theme.textTheme.labelSmall),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: (isClient ? const Color(0xFF8B5CF6) : colors.primary).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(meeting.type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isClient ? const Color(0xFF8B5CF6) : colors.primary)),
                ),
              ]),
              if (meeting.clientName != null && meeting.clientName!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Client: ${meeting.clientName}', style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.5))),
              ],
            ])),
            IconButton(
              icon: Icon(Icons.edit_calendar_rounded, size: 20, color: colors.primary),
              tooltip: 'Add to Calendar',
              onPressed: () {
                final event = Event(
                  title: meeting.title,
                  description: meeting.agenda ?? 'Meeting generated by FounderOS',
                  location: '',
                  startDate: meeting.date,
                  endDate: meeting.date.add(const Duration(minutes: 60)),
                  iosParams: const IOSParams(reminder: Duration(minutes: 15)),
                );
                Add2Calendar.addEvent2Cal(event);
              },
            ),
            if (meeting.participants.isNotEmpty)
              CircleAvatar(radius: 14, backgroundColor: colors.surfaceContainerHighest, child: Text('${meeting.participants.length}', style: theme.textTheme.labelSmall)),
          ]),
        ),
      ),
    );
  }
}
