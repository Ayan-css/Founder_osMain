import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/database/repositories/content_repository.dart';
import '../../../../services/database/collections/content_collection.dart';
import 'content_kanban_screen.dart';
import 'content_calendar_screen.dart';
import '../../../../core/widgets/premium_background.dart';

class ContentHubScreen extends ConsumerStatefulWidget {
  const ContentHubScreen({super.key});
  @override
  ConsumerState<ContentHubScreen> createState() => _ContentHubScreenState();
}

class _ContentHubScreenState extends ConsumerState<ContentHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _searchQuery = '';
  String? _filterStage;
  String? _filterFormat;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final content = ref.watch(allContentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Hub'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'List'),
            Tab(text: 'Kanban'),
            Tab(text: 'Calendar'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 22),
            onPressed: () {
              showSearch(context: context, delegate: _ContentSearchDelegate(ref));
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, size: 22),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: PremiumBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            // List View
            _ContentListView(filterStage: _filterStage, filterFormat: _filterFormat),
            // Kanban - redirect to kanban screen
            ContentKanbanScreen(),
            // Calendar - redirect to calendar screen
            ContentCalendarScreen(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/content/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Content'),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter by Stage', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filterStage == null,
                    onSelected: (_) { setState(() => _filterStage = null); Navigator.pop(context); },
                  ),
                  ...AppConstants.contentStages.map((stage) => FilterChip(
                    label: Text(stage),
                    selected: _filterStage == stage,
                    onSelected: (_) { setState(() => _filterStage = stage); Navigator.pop(context); },
                  )),
                ],
              ),
              const SizedBox(height: 24),
              Text('Filter by Format', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filterFormat == null,
                    onSelected: (_) { setState(() => _filterFormat = null); Navigator.pop(context); },
                  ),
                  ...AppConstants.contentFormats.map((format) => FilterChip(
                    label: Text(format),
                    selected: _filterFormat == format,
                    onSelected: (_) { setState(() => _filterFormat = format); Navigator.pop(context); },
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentListView extends ConsumerWidget {
  final String? filterStage;
  final String? filterFormat;
  const _ContentListView({this.filterStage, this.filterFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(allContentProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return content.when(
      data: (items) {
        var filtered = filterStage != null ? items.where((i) => i.stage == filterStage).toList() : items;
        filtered = filterFormat != null ? filtered.where((i) => i.format == filterFormat).toList() : filtered;
        if (filtered.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.article_outlined,
            title: 'No content yet',
            subtitle: 'Create your first content piece to get started',
            actionLabel: 'Create Content',
            onAction: () => context.go('/content/create'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = filtered[index];
            return _ContentCard(item: item);
          },
        );
      },
      loading: () => const ListLoadingSkeleton(),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final ContentItem item;
  const _ContentCard({required this.item});

  Color _stageColor(BuildContext context, String stage) {
    switch (stage) {
      case 'Raw Thought': return context.colors.onSurface.withValues(alpha: 0.4);
      case 'Idea': return context.statusColors.info;
      case 'Hook': return context.statusColors.warning;
      case 'Script': return context.statusColors.info;
      case 'Recording': return context.statusColors.error;
      case 'Editing': return context.statusColors.info;
      case 'Review': return context.statusColors.info;
      case 'Scheduled': return context.statusColors.warning;
      case 'Posted': return context.statusColors.success;
      case 'Repurposed': return context.statusColors.info;
      default: return context.colors.onSurface.withValues(alpha: 0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final stageColor = _stageColor(context, item.stage);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.go('/content/${item.id}'),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(color: stageColor, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _stageColor(context, item.stage).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(item.stage, style: TextStyle(color: _stageColor(context, item.stage), fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                        if (item.platform != null) ...[
                          const SizedBox(width: 8),
                          Text(item.platform!, style: theme.textTheme.labelSmall),
                        ],
                        if (item.format != null) ...[
                          const SizedBox(width: 8),
                          Text('• ${item.format!}', style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.6))),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (item.dueDate != null)
                Text('${item.dueDate!.day}/${item.dueDate!.month}', style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentSearchDelegate extends SearchDelegate {
  final WidgetRef ref;
  _ContentSearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override
  Widget buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  @override
  Widget buildResults(BuildContext context) => _buildSearch(context);
  @override
  Widget buildSuggestions(BuildContext context) => _buildSearch(context);

  Widget _buildSearch(BuildContext context) {
    final content = ref.watch(allContentProvider);
    return content.when(
      data: (items) {
        final filtered = items.where((i) => i.title.toLowerCase().contains(query.toLowerCase())).toList();
        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            return ListTile(
              title: Text(item.title),
              subtitle: Text(item.stage),
              onTap: () { close(context, null); context.go('/content/${item.id}'); },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
