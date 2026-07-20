import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/widgets/premium_background.dart';
import '../../../../services/database/repositories/outreach_repository.dart';
import '../../../../services/database/collections/outreach_collection.dart';
import '../../../../core/extensions/context_extensions.dart';

class OutreachAnalyticsScreen extends ConsumerWidget {
  const OutreachAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final outreachStream = ref.watch(allOutreachProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outreach Analytics'),
      ),
      body: PremiumBackground(
        child: outreachStream.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('No outreach data available.'));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Conversion Funnel', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _FunnelChart(items: items),
                  const SizedBox(height: 32),
                  Text('By Platform', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _PlatformPieChart(items: items),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _FunnelChart extends StatelessWidget {
  final List<OutreachItem> items;
  const _FunnelChart({required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    // Simple mock funnel: To Contact -> Contacted (all others) -> Replied -> Meeting -> Converted
    final toContact = items.where((i) => i.status == 'To Contact').length;
    final contacted = items.where((i) => i.status != 'To Contact').length;
    final replied = items.where((i) => i.status == 'Replied' || i.status == 'Meeting Booked' || i.status == 'Converted').length;
    final meeting = items.where((i) => i.status == 'Meeting Booked' || i.status == 'Converted').length;
    final converted = items.where((i) => i.status == 'Converted').length;

    final maxVal = (toContact + contacted).toDouble();
    if (maxVal == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(fontSize: 10, fontWeight: FontWeight.bold);
                  String text;
                  switch (value.toInt()) {
                    case 0: text = 'Found'; break;
                    case 1: text = 'Contacted'; break;
                    case 2: text = 'Replied'; break;
                    case 3: text = 'Meeting'; break;
                    case 4: text = 'Converted'; break;
                    default: text = ''; break;
                  }
                  return SideTitleWidget(meta: meta, child: Text(text, style: style));
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            _makeGroup(0, (toContact + contacted).toDouble(), colors.secondary),
            _makeGroup(1, contacted.toDouble(), context.colors.primary),
            _makeGroup(2, replied.toDouble(), context.statusColors.info),
            _makeGroup(3, meeting.toDouble(), context.statusColors.warning),
            _makeGroup(4, converted.toDouble(), context.statusColors.success),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 32,
          borderRadius: BorderRadius.circular(4),
        )
      ],
      showingTooltipIndicators: [0],
    );
  }
}

class _PlatformPieChart extends StatelessWidget {
  final List<OutreachItem> items;
  const _PlatformPieChart({required this.items});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> counts = {};
    for (var item in items) {
      counts[item.platform] = (counts[item.platform] ?? 0) + 1;
    }

    if (counts.isEmpty) return const SizedBox.shrink();

    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal
    ];

    List<PieChartSectionData> sections = [];
    int i = 0;
    counts.forEach((platform, count) {
      sections.add(PieChartSectionData(
        value: count.toDouble(),
        title: '$platform\n($count)',
        radius: 100,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        color: colors[i % colors.length],
      ));
      i++;
    });

    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: sections,
        ),
      ),
    );
  }
}
