import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../services/database/repositories/client_repository.dart';
import '../../../../services/workspace_service.dart';
import '../../../../core/widgets/premium_background.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final clients = ref.watch(allClientsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clients'), actions: [IconButton(icon: const Icon(Icons.search, size: 22), onPressed: () {})]),
      body: PremiumBackground(
        child: clients.when(
          data: (items) {
            final isViewer = ref.watch(workspaceServiceProvider).isViewer;
          if (items.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.business_center_outlined, 
              title: 'No clients yet', 
              subtitle: isViewer ? 'Ask an editor to add clients' : 'Add your first client', 
              actionLabel: isViewer ? '' : 'Add Client', 
              onAction: isViewer ? () {} : () => context.go('/clients/create'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final client = items[index];
              final pending = client.projectValue - client.amountReceived;
              return Card(margin: EdgeInsets.zero, child: InkWell(
                onTap: () => context.go('/clients/${client.id}'), borderRadius: BorderRadius.circular(16),
                child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                  CircleAvatar(backgroundColor: colors.primaryContainer, child: Text(client.name.isNotEmpty ? client.name[0].toUpperCase() : '?', style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(client.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (client.businessName != null) Text(client.businessName!, style: theme.textTheme.labelSmall),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(AppFormatters.currency(client.projectValue), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                    if (pending > 0) Text('${AppFormatters.currency(pending)} pending', style: theme.textTheme.labelSmall?.copyWith(color: context.statusColors.error)),
                  ]),
                ])),
              ));
            },
          );
        },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: ref.watch(workspaceServiceProvider).isViewer 
          ? null 
          : FloatingActionButton.extended(onPressed: () => context.go('/clients/create'), icon: const Icon(Icons.person_add), label: const Text('Add Client')),
    );
  }
}
