import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/database/repositories/task_repository.dart';
import '../../../../services/database/repositories/meeting_repository.dart';
import '../../../../services/database/repositories/outreach_repository.dart';
import '../../../../services/database/repositories/client_repository.dart';

class AIInsightsWidget extends ConsumerWidget {
  const AIInsightsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final tasksAsync = ref.watch(allTasksProvider);
    final meetingsAsync = ref.watch(allMeetingsProvider);
    final outreachAsync = ref.watch(allOutreachProvider);
    final mrrAsync = ref.watch(totalMrrProvider);

    // Default loading/fallback
    if (tasksAsync.isLoading || meetingsAsync.isLoading || outreachAsync.isLoading) {
      return const _InsightCard(insight: 'Analyzing your agency data...', icon: Icons.auto_awesome_rounded);
    }

    final tasks = tasksAsync.valueOrNull ?? [];
    final meetings = meetingsAsync.valueOrNull ?? [];
    final outreach = outreachAsync.valueOrNull ?? [];
    final mrr = mrrAsync.valueOrNull ?? 0.0;

    String insight = _generateInsight(tasks, meetings, outreach, mrr);

    return _InsightCard(insight: insight, icon: Icons.auto_awesome_rounded);
  }

  String _generateInsight(List tasks, List meetings, List outreach, double mrr) {
    final now = DateTime.now();
    
    // Check Tasks
    final criticalTasks = tasks.where((t) => t.priority == 'high' && t.status != 'done').toList();
    final overdueTasks = tasks.where((t) => t.dueDate != null && t.dueDate!.isBefore(now) && t.status != 'done').toList();
    
    // Check Meetings
    final upcomingMeetings = meetings.where((m) => m.date.isAfter(now) && m.date.difference(now).inDays <= 7).toList();
    
    // Check Outreach
    final convertedOutreach = outreach.where((o) => o.status == 'Converted').toList();
    
    final List<String> possibleInsights = [];
    
    if (overdueTasks.isNotEmpty) {
      possibleInsights.add("You have ${overdueTasks.length} overdue task(s). Consider knocking those out first.");
    }
    
    if (criticalTasks.isNotEmpty) {
      possibleInsights.add("${criticalTasks.length} critical task(s) need your attention today.");
    } else if (tasks.isNotEmpty) {
      possibleInsights.add("You're on top of your critical tasks. Great job staying organized!");
    }

    if (upcomingMeetings.isNotEmpty) {
      possibleInsights.add("You have ${upcomingMeetings.length} meeting(s) coming up this week. Make sure you're prepared!");
    }

    if (convertedOutreach.isNotEmpty) {
      possibleInsights.add("You've successfully converted ${convertedOutreach.length} outreach leads. Keep that momentum going!");
    } else if (outreach.isNotEmpty) {
      possibleInsights.add("You have active outreach campaigns. Following up can increase your conversion rate by 40%.");
    }

    if (mrr > 0) {
      possibleInsights.add("Your MRR is growing! You're currently tracking \$${mrr.toStringAsFixed(0)} in recurring revenue.");
    }

    if (possibleInsights.isEmpty) {
      return "Welcome to FounderOS! Start adding tasks and leads to get smart insights.";
    }

    // Pick a random insight to keep it fresh
    return possibleInsights[Random().nextInt(possibleInsights.length)];
  }
}

class _InsightCard extends StatelessWidget {
  final String insight;
  final IconData icon;

  const _InsightCard({required this.insight, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Insight',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
