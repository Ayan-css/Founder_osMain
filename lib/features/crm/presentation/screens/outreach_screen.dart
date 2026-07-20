import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/premium_background.dart';
import '../../../../services/database/collections/outreach_collection.dart';
import '../../../../services/database/repositories/outreach_repository.dart';
import '../../../../services/database/repositories/campaign_repository.dart';
import '../../../../core/routing/route_names.dart';
import 'package:go_router/go_router.dart';
import '../widgets/outreach_edit_sheet.dart';
// ── Outreach constants ───────────────────────────────────────────────────────

const _platforms = outreachPlatforms;
const _statuses = outreachStatuses;

// ── Screen ───────────────────────────────────────────────────────────────────

class OutreachScreen extends ConsumerStatefulWidget {
  const OutreachScreen({super.key});

  @override
  ConsumerState<OutreachScreen> createState() => _OutreachScreenState();
}

class _OutreachScreenState extends ConsumerState<OutreachScreen> {
  String? _filterStatus;
  String? _filterPlatform;
  String? _filterCampaign;
  bool _isKanbanMode = false;

  Color _statusColor(BuildContext context, String status) {
    return switch (status) {
      'To Contact'      => context.colors.secondary,
      'Not Replied'     => context.statusColors.warning,
      'Replied'         => context.statusColors.info,
      'Meeting Booked'  => context.colors.primary,
      'Converted'       => context.statusColors.success,
      'Not Interested'  => context.statusColors.error,
      _                 => context.colors.onSurface.withValues(alpha: 0.4),
    };
  }

  IconData _platformIcon(String platform) {
    return switch (platform) {
      'LinkedIn'  => Icons.business_center_outlined,
      'Email'     => Icons.email_outlined,
      'Instagram' => Icons.camera_alt_outlined,
      'WhatsApp'  => Icons.chat_outlined,
      'Cold Call' => Icons.phone_outlined,
      'Door to Door' => Icons.directions_walk_outlined,
      _           => Icons.link_outlined,
    };
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    try {
      final items = await ref.read(outreachRepositoryProvider).getAll();
      if (items.isEmpty) {
        if (context.mounted) context.showSnackBar('No outreach data to export', isError: true);
        return;
      }

      final List<List<dynamic>> rows = [
        ['Date Logged', 'Name', 'Company', 'Platform', 'Contact Detail', 'Status', 'Notes', 'Follow-up Date']
      ];

      for (final item in items) {
        rows.add([
          item.createdAt.toIso8601String(),
          item.name,
          item.company ?? '',
          item.platform,
          item.contactDetail ?? '',
          item.status,
          item.notes ?? '',
          item.followUpDate?.toIso8601String() ?? '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/outreach_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);

      if (context.mounted) {
        await Share.shareXFiles([XFile(file.path)], text: 'FounderOS Outreach Export');
      }
    } catch (e) {
      if (context.mounted) context.showSnackBar('Failed to export CSV: $e', isError: true);
    }
  }

  List<OutreachItem> _applyFilters(List<OutreachItem> items) {
    return items.where((i) {
      if (_filterStatus != null && i.status != _filterStatus) return false;
      if (_filterPlatform != null && i.platform != _filterPlatform) return false;
      if (_filterCampaign != null && i.campaignId != _filterCampaign) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final allOutreach = ref.watch(allOutreachProvider);
    final monthlyCount = ref.watch(monthlyOutreachCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cold Outreach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, size: 22),
            tooltip: 'Analytics',
            onPressed: () => context.go(RouteNames.outreachAnalytics),
          ),
          IconButton(
            icon: Icon(_isKanbanMode ? Icons.view_list : Icons.view_kanban, size: 22),
            tooltip: _isKanbanMode ? 'List View' : 'Kanban View',
            onPressed: () => setState(() => _isKanbanMode = !_isKanbanMode),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, size: 22),
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(context, ref),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _filterStatus != null || _filterPlatform != null,
              child: const Icon(Icons.filter_list, size: 22),
            ),
            onPressed: () => _showFilterSheet(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: PremiumBackground(
        child: Column(
          children: [
            // ── Stats bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: allOutreach.when(
                data: (items) {
                  final thisMonth = monthlyCount.value ?? 0;
                  final replied = items.where((i) => i.status == 'Replied').length;
                  final meetings = items.where((i) => i.status == 'Meeting Booked').length;
                  final converted = items.where((i) => i.status == 'Converted').length;

                  return Row(
                    children: [
                      _StatPill(label: 'This Month', value: '$thisMonth', color: colors.primary),
                      const SizedBox(width: 8),
                      _StatPill(label: 'Replied', value: '$replied', color: context.statusColors.info),
                      const SizedBox(width: 8),
                      _StatPill(label: 'Meetings', value: '$meetings', color: context.statusColors.warning),
                      const SizedBox(width: 8),
                      _StatPill(label: 'Converted', value: '$converted', color: context.statusColors.success),
                    ],
                  );
                },
                loading: () => const SizedBox(height: 40),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // ── Active filters chips ───────────────────────────────────────
            if (_filterStatus != null || _filterPlatform != null || _filterCampaign != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    if (_filterStatus != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Chip(
                          label: Text(_filterStatus!, style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setState(() => _filterStatus = null),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    if (_filterPlatform != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Chip(
                          label: Text(_filterPlatform!, style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setState(() => _filterPlatform = null),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    if (_filterCampaign != null)
                      Chip(
                        label: const Text('Campaign Filtered', style: TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => setState(() => _filterCampaign = null),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // ── List ───────────────────────────────────────────────────────
            Expanded(
              child: allOutreach.when(
                data: (items) {
                  final filtered = _applyFilters(items);
                  if (filtered.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.send_outlined,
                      title: 'No outreach entries',
                      subtitle: 'Log your first cold outreach to start tracking',
                      actionLabel: 'Add Entry',
                      onAction: () => showOutreachAddEditSheet(context, ref, null),
                    );
                  }
                  if (_isKanbanMode) {
                    return _KanbanBoard(
                      items: filtered,
                      onStatusUpdate: (item, newStatus) async {
                        item.status = newStatus;
                        await ref.read(outreachRepositoryProvider).update(item);
                        ref.invalidate(allOutreachProvider);
                      },
                        cardBuilder: (item) => _OutreachCard(
                        item: item,
                        statusColor: _statusColor(context, item.status),
                        platformIcon: _platformIcon(item.platform),
                        onTap: () => context.push('${RouteNames.outreach}/${item.id}'),
                        onEdit: () => showOutreachAddEditSheet(context, ref, item),
                        onDelete: () => _confirmDelete(context, item),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final item = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _OutreachCard(
                          item: item,
                          statusColor: _statusColor(context, item.status),
                          platformIcon: _platformIcon(item.platform),
                          onTap: () => context.push('${RouteNames.outreach}/${item.id}'),
                          onEdit: () => showOutreachAddEditSheet(context, ref, item),
                          onDelete: () => _confirmDelete(context, item),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showOutreachAddEditSheet(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Log Outreach'),
      ),
    );
  }

  // ── Filter sheet ─────────────────────────────────────────────────────────
  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: () {
                        setState(() { _filterStatus = null; _filterPlatform = null; _filterCampaign = null; });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Status', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _statuses.map((s) => FilterChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    selected: _filterStatus == s,
                    onSelected: (v) => setSheetState(() => _filterStatus = v ? s : null),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
                const SizedBox(height: 16),
                Text('Platform', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _platforms.map((p) => FilterChip(
                    label: Text(p, style: const TextStyle(fontSize: 12)),
                    selected: _filterPlatform == p,
                    onSelected: (v) => setSheetState(() => _filterPlatform = v ? p : null),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
                const SizedBox(height: 16),
                Text('Campaign', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final campaignsAsync = ref.watch(allCampaignsProvider);
                    return campaignsAsync.when(
                      data: (campaigns) {
                        if (campaigns.isEmpty) return const Text('No campaigns', style: TextStyle(fontStyle: FontStyle.italic));
                        return Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: campaigns.map((c) => FilterChip(
                            label: Text(c.name, style: const TextStyle(fontSize: 12)),
                            selected: _filterCampaign == c.id,
                            onSelected: (v) => setSheetState(() => _filterCampaign = v ? c.id : null),
                            visualDensity: VisualDensity.compact,
                          )).toList(),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {}); // apply to parent
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  }

  // ── Delete confirm ────────────────────────────────────────────────────────
  void _confirmDelete(BuildContext context, OutreachItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text('Remove outreach to "${item.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          Consumer(
            builder: (context, ref, _) => FilledButton(
              style: FilledButton.styleFrom(backgroundColor: context.colors.error),
              onPressed: () async {
                await ref.read(outreachRepositoryProvider).delete(item.id);
                ref.invalidate(allOutreachProvider);
                ref.invalidate(monthlyOutreachCountProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.8)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _OutreachCard extends StatelessWidget {
  final OutreachItem item;
  final Color statusColor;
  final IconData platformIcon;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OutreachCard({
    required this.item,
    required this.statusColor,
    required this.platformIcon,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Slidable(
      key: ValueKey(item.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            icon: Icons.edit_outlined,
            label: 'Edit',
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outline.withValues(alpha: 0.15)),
          boxShadow: [BoxShadow(color: colors.shadow.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Platform icon badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(platformIcon, size: 20, color: statusColor),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(item.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(item.status, style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600), maxLines: 1),
                          ),
                        ],
                      ),
                      if (item.company != null) ...[
                        const SizedBox(height: 2),
                        Text(item.company!, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.55))),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.share_outlined, size: 12, color: colors.onSurface.withValues(alpha: 0.45)),
                          const SizedBox(width: 4),
                          Text(item.platform, style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.55))),
                          if (item.contactDetail != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.contact_mail_outlined, size: 12, color: colors.onSurface.withValues(alpha: 0.45)),
                            const SizedBox(width: 4),
                            Expanded(child: Text(item.contactDetail!, style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.55)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                          if (item.followUpDate != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.event_outlined, size: 12, color: colors.primary.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              '${item.followUpDate!.day}/${item.followUpDate!.month}',
                              style: theme.textTheme.labelSmall?.copyWith(color: colors.primary.withValues(alpha: 0.8)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Kanban Implementation ───────────────────────────────────────────────────

class _KanbanBoard extends StatelessWidget {
  final List<OutreachItem> items;
  final Function(OutreachItem, String) onStatusUpdate;
  final Widget Function(OutreachItem) cardBuilder;

  const _KanbanBoard({
    required this.items,
    required this.onStatusUpdate,
    required this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: _statuses.map((status) {
        final columnItems = items.where((i) => i.status == status).toList();
        return _KanbanColumn(
          status: status,
          items: columnItems,
          onStatusUpdate: onStatusUpdate,
          cardBuilder: cardBuilder,
        );
      }).toList(),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String status;
  final List<OutreachItem> items;
  final Function(OutreachItem, String) onStatusUpdate;
  final Widget Function(OutreachItem) cardBuilder;

  const _KanbanColumn({
    required this.status,
    required this.items,
    required this.onStatusUpdate,
    required this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return DragTarget<OutreachItem>(
      onAcceptWithDetails: (details) {
        if (details.data.status != status) {
          onStatusUpdate(details.data, status);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 300,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? colors.primary.withValues(alpha: 0.1)
                : colors.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? colors.primary.withValues(alpha: 0.5)
                  : colors.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(status, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${items.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.onSurface.withValues(alpha: 0.7))),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: items.length,
                  itemBuilder: (ctx, index) {
                    final item = items[index];
                    final card = cardBuilder(item);
                    return Draggable<OutreachItem>(
                      data: item,
                      feedback: SizedBox(
                        width: 276,
                        child: Material(
                          color: Colors.transparent,
                          child: Opacity(opacity: 0.85, child: card),
                        ),
                      ),
                      childWhenDragging: Opacity(opacity: 0.4, child: card),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: card,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
