import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../services/database/repositories/content_repository.dart';
import '../../../../services/database/collections/content_collection.dart';

class ContentCalendarScreen extends ConsumerStatefulWidget {
  const ContentCalendarScreen({super.key});
  @override
  ConsumerState<ContentCalendarScreen> createState() => _ContentCalendarScreenState();
}

class _ContentCalendarScreenState extends ConsumerState<ContentCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(allContentProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return content.when(
      data: (items) {
        final events = <DateTime, List<ContentItem>>{};
        for (final item in items) {
          if (item.dueDate != null) {
            final key = DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day);
            events.putIfAbsent(key, () => []).add(item);
          }
        }

        final selectedItems = _selectedDay != null
            ? events[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? []
            : <ContentItem>[];

        return Column(
          children: [
            TableCalendar<ContentItem>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              eventLoader: (day) {
                return events[DateTime(day.year, day.month, day.day)] ?? [];
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: colors.secondary,
                  shape: BoxShape.circle,
                ),
                markerSize: 6,
                markersMaxCount: 3,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: selectedItems.isEmpty
                  ? Center(
                      child: Text(
                        _selectedDay != null ? 'No content due this day' : 'Select a day to see content',
                        style: theme.textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: selectedItems.length,
                      itemBuilder: (context, index) {
                        final item = selectedItems[index];
                        return Card(
                          child: ListTile(
                            title: Text(item.title),
                            subtitle: Text(item.format != null ? '${item.stage} • ${item.format}' : item.stage),
                            trailing: item.platform != null ? Chip(label: Text(item.platform!, style: const TextStyle(fontSize: 11))) : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
