import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/premium_background.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../services/database/repositories/task_repository.dart';
import '../../../../services/database/repositories/transaction_repository.dart';
import '../../../../services/database/repositories/client_repository.dart';
import '../../../../services/database/repositories/lead_repository.dart';
import '../../../../services/database/repositories/content_repository.dart';
import '../../../../services/database/repositories/focus_repository.dart';
import '../../../../services/database/repositories/meeting_repository.dart';
import '../../../../services/database/repositories/outreach_repository.dart';
import '../../../../services/settings_service.dart';
import '../widgets/critical_tasks_widget.dart';
import '../widgets/activity_feed_widget.dart';
import '../widgets/revenue_chart_widget.dart';
import '../widgets/ai_insights_widget.dart';
import '../widgets/follow_up_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isTablet = context.isTablet;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              DateTime.now().formattedDay,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: PremiumBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(totalRevenueProvider);
            ref.invalidate(totalExpensesProvider);
            ref.invalidate(activeClientCountProvider);
            ref.invalidate(activeLeadCountProvider);
            ref.invalidate(openTaskCountProvider);
            ref.invalidate(pendingPaymentsProvider);
            ref.invalidate(totalMrrProvider);
            ref.invalidate(monthlyNewClientCountProvider);
            ref.invalidate(monthlyOutreachCountProvider);
          },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── MRR Hero Card ──
              const _MrrHeroCard(),
              const SizedBox(height: 20),

              // ── Monthly Goals ──
              _SectionHeader(
                title: 'Monthly Goals',
                action: TextButton(
                  onPressed: () => context.go(RouteNames.settings),
                  child: const Text('Set Targets'),
                ),
              ),
              const SizedBox(height: 12),
              const _MonthlyGoalsSection(),
              const SizedBox(height: 24),

              // ── Agency Overview Stats ──
              _SectionHeader(title: 'Agency Overview'),
              const SizedBox(height: 12),
              _AgencyOverviewGrid(isTablet: isTablet),
              const SizedBox(height: 24),

              // ── Smart AI Insights ──
              const AIInsightsWidget(),
              const SizedBox(height: 24),

              // ── Top 3 Critical Tasks ──
              _SectionHeader(
                title: 'Top 3 Critical Tasks',
                action: TextButton(
                  onPressed: () => context.go('/tasks'),
                  child: const Text('Manage'),
                ),
              ),
              const SizedBox(height: 12),
              const CriticalTasksWidget(),
              const SizedBox(height: 24),

              // ── Revenue Chart ──
              _SectionHeader(title: 'Revenue Trend'),
              const SizedBox(height: 12),
              const RevenueChartWidget(),
              const SizedBox(height: 24),

              // ── Content Overview ──
              _SectionHeader(
                title: 'Content Overview',
                action: TextButton(
                  onPressed: () => context.go(RouteNames.contentHub),
                  child: const Text('View All'),
                ),
              ),
              const SizedBox(height: 12),
              _ContentOverviewRow(),
              const SizedBox(height: 24),

              // ── Today's Schedule ──
              _SectionHeader(
                title: "Today's Schedule",
                action: TextButton(
                  onPressed: () => context.go(RouteNames.meetings),
                  child: const Text('All Meetings'),
                ),
              ),
              const SizedBox(height: 12),
              _TodayMeetings(),
              const SizedBox(height: 24),

              // ── Pending Follow-ups ──
              _SectionHeader(
                title: "Pending Follow-ups",
                action: TextButton(
                  onPressed: () => context.go(RouteNames.outreach),
                  child: const Text('All Outreach'),
                ),
              ),
              const SizedBox(height: 12),
              const FollowUpWidget(),
              const SizedBox(height: 24),

              // ── Productivity Overview ──
              _SectionHeader(title: 'Productivity'),
              const SizedBox(height: 12),
              _ProductivityRow(),
              const SizedBox(height: 24),

              // ── Activity Feed ──
              _SectionHeader(
                title: 'Recent Activity',
                action: TextButton(
                  onPressed: () => context.go('/dashboard/activity'),
                  child: const Text('View All'),
                ),
              ),
              const SizedBox(height: 12),
              const ActivityFeedWidget(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showQuickAddSheet(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showQuickAddSheet(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Add',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickAddChip(icon: Icons.task_alt, label: 'Task', onTap: () { Navigator.pop(context); _showQuickTaskDialog(context); }),
                  _QuickAddChip(icon: Icons.article, label: 'Content', onTap: () { Navigator.pop(context); context.go('/content/create'); }),
                  _QuickAddChip(icon: Icons.person_add, label: 'Lead', onTap: () { Navigator.pop(context); context.go('/crm/create'); }),
                  _QuickAddChip(icon: Icons.business_center, label: 'Client', onTap: () { Navigator.pop(context); context.go('/clients/create'); }),
                  _QuickAddChip(icon: Icons.attach_money, label: 'Transaction', onTap: () { Navigator.pop(context); context.go('/finance/create'); }),
                  _QuickAddChip(icon: Icons.groups, label: 'Meeting', onTap: () { Navigator.pop(context); context.go('/meetings/create'); }),
                  _QuickAddChip(icon: Icons.menu_book, label: 'Journal', onTap: () { Navigator.pop(context); context.go('/journal/create'); }),
                  _QuickAddChip(icon: Icons.send_outlined, label: 'Outreach', onTap: () { Navigator.pop(context); context.go(RouteNames.outreach); }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickTaskDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    String priority = 'Medium';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Quick Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Task Title *'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                  DropdownMenuItem(value: 'High', child: Text('High')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                ],
                onChanged: (v) => setDialogState(() => priority = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            Consumer(
              builder: (context, ref, _) => FilledButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  await ref.read(taskRepositoryProvider).create(
                    title: titleCtrl.text.trim(),
                    priority: priority,
                  );
                  ref.invalidate(allTasksProvider);
                  ref.invalidate(openTaskCountProvider);
                  ref.invalidate(pinnedTasksProvider);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Add Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAddChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(icon, size: 18, color: colors.primary),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _AgencyOverviewGrid extends ConsumerWidget {
  final bool isTablet;
  const _AgencyOverviewGrid({required this.isTablet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenue = ref.watch(totalRevenueProvider);
    final expenses = ref.watch(totalExpensesProvider);
    final profit = ref.watch(totalProfitProvider);
    final clients = ref.watch(activeClientCountProvider);
    final pending = ref.watch(pendingPaymentsProvider);
    final leads = ref.watch(activeLeadCountProvider);
    final tasks = ref.watch(openTaskCountProvider);
    final focus = ref.watch(todayFocusMinutesProvider);

    return GridView.count(
      crossAxisCount: isTablet ? 4 : 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: isTablet ? 1.4 : 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(
          title: 'Revenue',
          value: revenue.when(
            data: (v) => AppFormatters.currency(v),
            loading: () => '...',
            error: (_, __) => '—',
          ),
          icon: Icons.trending_up_rounded,
          iconColor: context.statusColors.success,
        ),
        StatCard(
          title: 'Expenses',
          value: expenses.when(data: (v) => AppFormatters.currency(v), loading: () => '...', error: (_, __) => '—'),
          icon: Icons.trending_down_rounded,
          iconColor: context.statusColors.error,
        ),
        StatCard(
          title: 'Profit',
          value: profit.when(data: (v) => AppFormatters.currency(v), loading: () => '...', error: (_, __) => '—'),
          icon: Icons.account_balance_rounded,
          iconColor: context.statusColors.info,
        ),
        StatCard(
          title: 'Active Clients',
          value: clients.when(data: (v) => v.toString(), loading: () => '...', error: (_, __) => '—'),
          icon: Icons.business_center_rounded,
          iconColor: context.statusColors.info,
        ),
        StatCard(
          title: 'Pending',
          value: pending.when(data: (v) => AppFormatters.currency(v), loading: () => '...', error: (_, __) => '—'),
          icon: Icons.payment_rounded,
          iconColor: context.statusColors.warning,
        ),
        StatCard(
          title: 'Active Leads',
          value: leads.when(data: (v) => v.toString(), loading: () => '...', error: (_, __) => '—'),
          icon: Icons.people_outline_rounded,
          iconColor: context.statusColors.info,
        ),
        StatCard(
          title: 'Open Tasks',
          value: tasks.when(data: (v) => v.toString(), loading: () => '...', error: (_, __) => '—'),
          icon: Icons.task_alt_rounded,
          iconColor: context.statusColors.info,
        ),
        StatCard(
          title: 'Focus Today',
          value: focus.when(data: (v) => AppFormatters.duration(v), loading: () => '...', error: (_, __) => '—'),
          icon: Icons.timer_rounded,
          iconColor: context.statusColors.warning,
        ),
      ],
    );
  }
}

class _ContentOverviewRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(allContentProvider);
    return content.when(
      data: (items) {
        final inProduction = items.where((i) => !['Posted', 'Repurposed'].contains(i.stage)).length;
        final scheduled = items.where((i) => i.stage == 'Scheduled').length;
        final published = items.where((i) => i.stage == 'Posted').length;

        return Row(
          children: [
            Expanded(child: _MiniStat(label: 'In Production', value: '$inProduction', color: context.statusColors.info)),
            const SizedBox(width: 10),
            Expanded(child: _MiniStat(label: 'Scheduled', value: '$scheduled', color: context.statusColors.warning)),
            const SizedBox(width: 10),
            Expanded(child: _MiniStat(label: 'Published', value: '$published', color: context.statusColors.success)),
          ],
        );
      },
      loading: () => const LoadingSkeleton(height: 72),
      error: (_, __) => const Text('Error loading content'),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius as BorderRadius? ?? BorderRadius.circular(14),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _TodayMeetings extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetings = ref.watch(todayMeetingsProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return meetings.when(
      data: (items) {
        if (items.isEmpty) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(Icons.event_available, color: colors.primary.withValues(alpha: 0.5), size: 20),
                  const SizedBox(width: 12),
                  Text('No meetings scheduled for today', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface.withValues(alpha: 0.5))),
                ],
              ),
            ),
          );
        }
        return Column(
          children: items.take(3).map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: m.type == 'client' ? context.statusColors.info : colors.primary,
                      borderRadius: (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius as BorderRadius? ?? BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text(m.date.formattedTime, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(m.type, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          )).toList(),
        );
      },
      loading: () => const LoadingSkeleton(height: 60),
      error: (_, __) => const Text('Error loading meetings'),
    );
  }
}

class _ProductivityRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayMins = ref.watch(todayFocusMinutesProvider);
    final weekMins = ref.watch(weekFocusMinutesProvider);
    final monthMins = ref.watch(monthFocusMinutesProvider);

    return Row(
      children: [
        Expanded(child: _MiniStat(
          label: 'Today',
          value: todayMins.when(data: (v) => AppFormatters.duration(v), loading: () => '...', error: (_, __) => '—'),
          color: context.statusColors.info,
        )),
        const SizedBox(width: 10),
        Expanded(child: _MiniStat(
          label: 'This Week',
          value: weekMins.when(data: (v) => AppFormatters.duration(v), loading: () => '...', error: (_, __) => '—'),
          color: context.statusColors.info,
        )),
        const SizedBox(width: 10),
        Expanded(child: _MiniStat(
          label: 'This Month',
          value: monthMins.when(data: (v) => AppFormatters.duration(v), loading: () => '...', error: (_, __) => '—'),
          color: context.statusColors.success,
        )),
      ],
    );
  }
}

// ── MRR Hero Card (SaaS Flat Design) ──────────────────────────────────────────

class _MrrHeroCard extends ConsumerWidget {
  const _MrrHeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mrr = ref.watch(totalMrrProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : const Color(0xFFF9FAFB),
        border: Border.all(color: colors.outline.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.repeat_rounded, color: colors.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                'Monthly Recurring Revenue',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          mrr.when(
            data: (value) => Text(
              AppFormatters.currency(value),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
              ),
            ),
            loading: () => const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => Text('—', style: theme.textTheme.displaySmall),
          ),
          const SizedBox(height: 8),
          Text(
            'From all active retainer clients',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Monthly Goals Section ────────────────────────────────────────────────────

class _MonthlyGoalsSection extends ConsumerWidget {
  const _MonthlyGoalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    final newClients = ref.watch(monthlyNewClientCountProvider);
    final outreachCount = ref.watch(monthlyOutreachCountProvider);
    final mrr = ref.watch(totalMrrProvider);

    final clientTarget = settings.monthlyClientTarget;
    final outreachTarget = settings.monthlyOutreachTarget;
    final mrrTarget = settings.monthlyMrrTarget;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _GoalProgressCard(
                title: 'Client Onboarding',
                icon: Icons.business_center_rounded,
                current: newClients.when(data: (v) => v, loading: () => 0, error: (_, __) => 0),
                target: clientTarget,
                color: context.statusColors.success,
                isLoading: newClients.isLoading,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GoalProgressCard(
                title: 'Cold Outreach',
                icon: Icons.send_rounded,
                current: outreachCount.when(data: (v) => v, loading: () => 0, error: (_, __) => 0),
                target: outreachTarget,
                color: context.statusColors.info,
                isLoading: outreachCount.isLoading,
                onTap: () => context.go(RouteNames.outreach),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MrrGoalProgressCard(
          title: 'MRR Target',
          icon: Icons.currency_rupee_rounded,
          current: mrr.when(data: (v) => v, loading: () => 0.0, error: (_, __) => 0.0),
          target: mrrTarget.toDouble(),
          color: const Color(0xFF4F46E5),
          isLoading: mrr.isLoading,
        ),
      ],
    );
  }
}

class _MrrGoalProgressCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double current;
  final double target;
  final Color color;
  final bool isLoading;

  const _MrrGoalProgressCard({
    required this.title,
    required this.icon,
    required this.current,
    required this.target,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isDone = current >= target && target > 0;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const LoadingSkeleton(height: 24)
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  AppFormatters.compactCurrency(current),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ ${AppFormatters.compactCurrency(target)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colors.outline.withValues(alpha: 0.1),
                color: isDone ? context.statusColors.success : color,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDone ? 'Target Reached! 🎉' : '${(progress * 100).toInt()}% of goal',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDone ? context.statusColors.success : colors.onSurface.withValues(alpha: 0.6),
                fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int current;
  final int target;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  const _GoalProgressCard({
    required this.title,
    required this.icon,
    required this.current,
    required this.target,
    required this.color,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isDone = current >= target && target > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone ? color.withValues(alpha: 0.4) : colors.outline.withValues(alpha: 0.15),
            width: isDone ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(color: colors.shadow.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(title, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: colors.onSurface.withValues(alpha: 0.7)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (isDone) Icon(Icons.check_circle_rounded, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const SizedBox(height: 36, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            else ...[
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$current',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: color),
                    ),
                    TextSpan(
                      text: ' / $target',
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.45)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% complete',
                style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.45)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

