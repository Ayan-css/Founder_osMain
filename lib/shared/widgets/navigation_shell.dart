import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routing/route_names.dart';
import '../../core/extensions/context_extensions.dart';
import '../../services/workspace_service.dart';

/// Main navigation shell with Bottom Navigation + Drawer
class NavigationShell extends StatelessWidget {
  final Widget child;

  const NavigationShell({super.key, required this.child});

  static const _bottomNavItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', path: RouteNames.dashboard),
    _NavItem(icon: Icons.article_rounded, label: 'Content', path: RouteNames.contentHub),
    _NavItem(icon: Icons.people_rounded, label: 'CRM', path: RouteNames.crm),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Finance', path: RouteNames.finance),
    _NavItem(icon: Icons.more_horiz_rounded, label: 'More', path: ''),
  ];

  static const _drawerItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', path: RouteNames.dashboard),
    _NavItem(icon: Icons.task_alt_rounded, label: 'Tasks', path: RouteNames.tasks),
    _NavItem(icon: Icons.article_rounded, label: 'Content Hub', path: RouteNames.contentHub),
    _NavItem(icon: Icons.auto_stories_rounded, label: 'Knowledge', path: RouteNames.knowledge),
    _NavItem(icon: Icons.people_rounded, label: 'CRM', path: RouteNames.crm),
    _NavItem(icon: Icons.record_voice_over_rounded, label: 'Outreach', path: RouteNames.outreach),
    _NavItem(icon: Icons.article_rounded, label: 'Templates', path: RouteNames.templates),
    _NavItem(icon: Icons.business_center_rounded, label: 'Clients', path: RouteNames.clients),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Finance', path: RouteNames.finance),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Resources', path: RouteNames.resources),
    _NavItem(icon: Icons.groups_rounded, label: 'Meetings', path: RouteNames.meetings),
    _NavItem(icon: Icons.menu_book_rounded, label: 'Journal', path: RouteNames.journal),
    _NavItem(icon: Icons.timer_rounded, label: 'Focus', path: RouteNames.focus),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Reports', path: RouteNames.reports),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings', path: RouteNames.settings),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location == '/') return 0;
    if (location.startsWith('/content')) return 1;
    if (location.startsWith('/crm')) return 2;
    if (location.startsWith('/finance')) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final currentIndex = _currentIndex(context);
    final location = GoRouterState.of(context).uri.toString();

    if (isTablet) {
      return _TabletLayout(
        currentPath: location,
        drawerItems: _drawerItems,
        child: child,
      );
    }

    return Scaffold(
      body: child,
      drawer: _AppDrawer(
        currentPath: location,
        items: _drawerItems,
      ),
      bottomNavigationBar: Builder(
        builder: (innerContext) => _BottomNav(
          currentIndex: currentIndex,
          items: _bottomNavItems,
          onTap: (index) {
            if (index == 4) {
              Scaffold.of(innerContext).openDrawer();
              return;
            }
            context.go(_bottomNavItems[index].path);
          },
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.label, required this.path});
}

/// Bottom Navigation Bar
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: colors.outline.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = index == currentIndex;
                return GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 56,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 24,
                          color: isSelected ? colors.primary : colors.onSurface.withValues(alpha: 0.5),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// App Drawer for all navigation items
class _AppDrawer extends ConsumerWidget {
  final String currentPath;
  final List<_NavItem> items;

  const _AppDrawer({
    required this.currentPath,
    required this.items,
  });

  bool _isSelected(String path) {
    if (path == '/' && currentPath == '/') return true;
    if (path != '/' && currentPath.startsWith(path)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final wsService = ref.watch(workspaceServiceProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                border: Border(bottom: BorderSide(color: colors.outline.withValues(alpha: 0.1))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Icon(
                          Icons.business_rounded,
                          color: colors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wsService.currentWorkspaceName ?? 'Personal Workspace',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (wsService.currentRole ?? 'Member').toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: items.map((item) {
                  final selected = _isSelected(item.path);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: ListTile(
                      leading: Icon(
                        item.icon,
                        size: 22,
                        color: selected ? colors.primary : colors.onSurface.withValues(alpha: 0.7),
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? colors.primary : colors.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      selected: selected,
                      selectedTileColor: colors.primaryContainer.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      dense: true,
                      visualDensity: const VisualDensity(vertical: -1),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(item.path);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tablet layout with persistent side navigation
class _TabletLayout extends StatelessWidget {
  final String currentPath;
  final List<_NavItem> drawerItems;
  final Widget child;

  const _TabletLayout({
    required this.currentPath,
    required this.drawerItems,
    required this.child,
  });

  bool _isSelected(String path) {
    if (path == '/' && currentPath == '/') return true;
    if (path != '/' && currentPath.startsWith(path)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Side nav
          _SideNav(
            currentIndex: drawerItems.indexWhere((item) => _isSelected(item.path)).clamp(0, drawerItems.length - 1),
            items: drawerItems,
            onTap: (index) {
              context.go(drawerItems[index].path);
            },
          ),
          // Content
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Floating Side Navigation for Tablet Layout
class _SideNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _SideNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 80,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: colors.outline.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Logo/Header
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 24),
                // Scrollable nav items
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        final isSelected = index == currentIndex;
                        return GestureDetector(
                          onTap: () => onTap(index),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 64,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 24,
                                  color: isSelected ? colors.primary : colors.onSurface.withValues(alpha: 0.5),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                ] else ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colors.onSurface.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w400,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ]
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
