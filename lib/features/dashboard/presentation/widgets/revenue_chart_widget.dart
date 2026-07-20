import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/extensions/context_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../services/database/repositories/transaction_repository.dart';

class RevenueChartWidget extends ConsumerWidget {
  const RevenueChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(monthlyTrendProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return trend.when(
      data: (data) {
        if (data.isEmpty || data.every((m) => m['revenue'] == 0 && m['expenses'] == 0)) {
          return AppCard(
            title: 'Revenue vs Expenses',
            child: SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 40, color: colors.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    Text('Add transactions to see trends', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          );
        }

        final months = ['6mo', '5mo', '4mo', '3mo', '2mo', '1mo'];
        final maxVal = data.fold<double>(0, (max, m) {
          final r = m['revenue'] ?? 0;
          final e = m['expenses'] ?? 0;
          return r > max ? r : (e > max ? e : max);
        });

        return AppCard(
          title: 'Revenue vs Expenses',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LegendDot(color: context.statusColors.success, label: 'Revenue'),
              const SizedBox(width: 16),
              _LegendDot(color: context.statusColors.error, label: 'Expenses'),
            ],
          ),
          child: SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        AppFormatters.currency(rod.toY),
                        TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= months.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(months[idx], style: TextStyle(fontSize: 10, color: colors.onSurface.withValues(alpha: 0.5))),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(AppFormatters.compactNumber(value), style: TextStyle(fontSize: 10, color: colors.onSurface.withValues(alpha: 0.4)));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colors.outline.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(data.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[i]['revenue'] ?? 0,
                        color: context.statusColors.success,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                      ),
                      BarChartRodData(
                        toY: data[i]['expenses'] ?? 0,
                        color: context.statusColors.error,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Text('Error loading chart'),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }
}
