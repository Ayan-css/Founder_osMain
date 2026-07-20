import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../services/database/repositories/knowledge_repository.dart';
import '../../../../core/widgets/premium_background.dart';

class KnowledgeScreen extends ConsumerStatefulWidget {
  const KnowledgeScreen({super.key});
  @override
  ConsumerState<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen> {
  String? _selectedCategory;
  bool _showFavorites = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final knowledge = _showFavorites ? ref.watch(favoriteKnowledgeProvider) : ref.watch(allKnowledgeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Vault'),
        actions: [
          IconButton(
            icon: Icon(_showFavorites ? Icons.favorite : Icons.favorite_border, size: 22, color: _showFavorites ? context.statusColors.error : null),
            onPressed: () => setState(() => _showFavorites = !_showFavorites),
          ),
          IconButton(icon: const Icon(Icons.search, size: 22), onPressed: () {}),
        ],
      ),
      body: PremiumBackground(
        child: Column(
          children: [
          // Category chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(label: const Text('All'), selected: _selectedCategory == null, onSelected: (_) => setState(() => _selectedCategory = null)),
                ),
                ...AppConstants.knowledgeCategories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(label: Text(cat), selected: _selectedCategory == cat, onSelected: (_) => setState(() => _selectedCategory = _selectedCategory == cat ? null : cat)),
                )),
              ],
            ),
          ),
          Expanded(
            child: knowledge.when(
              data: (items) {
                final filtered = _selectedCategory != null ? items.where((i) => i.category == _selectedCategory).toList() : items;
                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.auto_stories_outlined,
                    title: 'No knowledge items',
                    subtitle: 'Start building your knowledge vault',
                    actionLabel: 'Add Knowledge',
                    onAction: () => context.go('/knowledge/create'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        title: Text(item.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Text(item.category, style: theme.textTheme.labelSmall),
                        trailing: IconButton(
                          icon: Icon(item.isFavorite ? Icons.favorite : Icons.favorite_border, size: 20, color: item.isFavorite ? context.statusColors.error : null),
                          onPressed: () { ref.read(knowledgeRepositoryProvider).toggleFavorite(item.id); ref.invalidate(allKnowledgeProvider); ref.invalidate(favoriteKnowledgeProvider); },
                        ),
                        onTap: () {},
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
      )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/knowledge/create'),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}
