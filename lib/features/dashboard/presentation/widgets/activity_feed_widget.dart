import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/extensions/date_extensions.dart';

class ActivityFeedWidget extends StatelessWidget {
  const ActivityFeedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Show placeholder when there's no activity yet
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _ActivityItem(
              icon: Icons.rocket_launch_rounded,
              color: colors.primary,
              title: 'Welcome to Right Craft Media OS',
              subtitle: 'Start by adding your first content, lead, or client',
              time: DateTime.now().relative,
            ),
            const Divider(height: 24),
            _ActivityItem(
              icon: Icons.event,
              color: context.statusColors.warning,
              title: 'Tip: Pin your critical tasks',
              subtitle: 'Use the dashboard to track your top 3 daily priorities',
              time: 'Just now',
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        Text(time, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
