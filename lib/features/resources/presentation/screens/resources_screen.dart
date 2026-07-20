import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../services/database/repositories/resource_repository.dart';
import '../../../../services/database/collections/resource_collection.dart';
import '../../../../core/widgets/premium_background.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});
  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() { super.initState(); _tabController = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resources'),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Current'), Tab(text: 'Wishlist')]),
      ),
      body: PremiumBackground(
        child: TabBarView(controller: _tabController, children: [_ResourceList(isPurchased: true), _ResourceList(isPurchased: false)]),
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.go('/resources/create'), icon: const Icon(Icons.add), label: const Text('Add Resource')),
    );
  }
}

class _ResourceList extends ConsumerWidget {
  final bool isPurchased;
  const _ResourceList({required this.isPurchased});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resources = isPurchased ? ref.watch(existingResourcesProvider) : ref.watch(wishlistResourcesProvider);

    return resources.when(
      data: (items) {
        if (items.isEmpty) {
          return EmptyStateWidget(
            icon: isPurchased ? Icons.inventory_2_outlined : Icons.shopping_cart_outlined,
            title: isPurchased ? 'No resources tracked' : 'Wishlist is empty',
            subtitle: isPurchased ? 'Track your software, equipment & tools' : 'Plan your future purchases',
            actionLabel: 'Add Resource',
            onAction: () => context.go('/resources/create'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final r = items[index];
            return Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(_typeIcon(r.type), size: 18, color: theme.colorScheme.onPrimaryContainer),
                ),
                title: Text(r.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(r.type, style: theme.textTheme.labelSmall),
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(AppFormatters.currency(isPurchased ? r.cost : r.estimatedCost), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                  if (r.renewalDate != null) Text('Renews ${r.renewalDate!.day}/${r.renewalDate!.month}', style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFFF59E0B))),
                ]),
                onLongPress: !isPurchased ? () => _showWishlistActions(context, ref, r) : null,
                onTap: !isPurchased ? () => _showWishlistActions(context, ref, r) : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showWishlistActions(BuildContext context, WidgetRef ref, ResourceItem resource) {
    final theme = Theme.of(context);
    final costCtrl = TextEditingController(text: resource.estimatedCost > 0 ? resource.estimatedCost.toString() : '');

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(resource.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text(resource.type, style: theme.textTheme.bodySmall),
            const SizedBox(height: 20),
            TextField(
              controller: costCtrl,
              decoration: const InputDecoration(labelText: 'Actual Cost (₹)', prefixText: '₹ '),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark as Purchased'),
                onPressed: () async {
                  resource.isPurchased = true;
                  resource.cost = double.tryParse(costCtrl.text) ?? resource.estimatedCost;
                  await ref.read(resourceRepositoryProvider).update(resource);
                  ref.invalidate(existingResourcesProvider);
                  ref.invalidate(wishlistResourcesProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    context.showSuccess('${resource.name} marked as purchased');
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                label: const Text('Remove from Wishlist', style: TextStyle(color: Color(0xFFEF4444))),
                onPressed: () async {
                  await ref.read(resourceRepositoryProvider).delete(resource.id);
                  ref.invalidate(wishlistResourcesProvider);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Software': return Icons.computer;
      case 'Equipment': return Icons.devices;
      case 'Templates': return Icons.description;
      case 'Courses': return Icons.school;
      case 'Assets': return Icons.image;
      case 'Tools': return Icons.build;
      default: return Icons.inventory_2;
    }
  }
}
