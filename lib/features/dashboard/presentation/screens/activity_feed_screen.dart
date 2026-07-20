import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../services/database/repositories/activity_log_repository.dart';
import '../../../../services/database/collections/activity_log_collection.dart';

class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(workspaceActivityLogsProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workspace Activity'),
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('No activity found for this workspace.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildActivityLogItem(context, log, colors);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildActivityLogItem(BuildContext context, ActivityLogItem log, ColorScheme colors) {
    IconData icon;
    Color iconColor;

    switch (log.entityType) {
      case 'tasks':
        icon = Icons.check_circle_outline;
        iconColor = Colors.blue;
        break;
      case 'clients':
        icon = Icons.business;
        iconColor = Colors.green;
        break;
      case 'invoices':
        icon = Icons.receipt;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.update;
        iconColor = colors.primary;
    }

    String actionText;
    switch (log.action) {
      case 'created':
        actionText = 'created a new';
        break;
      case 'updated':
        actionText = 'updated a';
        break;
      case 'deleted':
        actionText = 'deleted a';
        break;
      default:
        actionText = 'modified a';
    }

    final entityName = log.entityType.replaceAll('_', ' ');
    final timeString = timeago.format(log.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              const TextSpan(text: 'Someone ', style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: '$actionText $entityName '),
            ],
          ),
        ),
        subtitle: Text(timeString, style: TextStyle(color: colors.onSurface.withValues(alpha: 0.6))),
      ),
    );
  }
}
