import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../services/sync/sync_engine.dart';
import '../../../../services/settings_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final themeState = ref.watch(themeNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final pendingSync = ref.watch(pendingSyncCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile / Auth
          Card(child: ListTile(
            leading: CircleAvatar(
              backgroundColor: authState.isAuthenticated ? const Color(0xFF22C55E).withValues(alpha: 0.1) : colors.primaryContainer,
              child: Icon(
                authState.isAuthenticated ? Icons.check_circle : Icons.person,
                color: authState.isAuthenticated ? const Color(0xFF22C55E) : colors.onPrimaryContainer,
              ),
            ),
            title: Text(
              authState.isAuthenticated ? (authState.user?.email ?? 'Signed In') : 'Not Signed In',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(authState.isAuthenticated ? 'Tap to edit profile' : 'Guest Mode - Tap to log in or create account'),
            onTap: authState.isAuthenticated ? () => context.go('/settings/profile') : null,
            trailing: authState.isAuthenticated
                ? OutlinedButton(
                    onPressed: () async {
                      await ref.read(authNotifierProvider.notifier).signOut();
                      if (context.mounted) context.go(RouteNames.login);
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                    child: const Text('Sign Out'),
                  )
                : FilledButton(
                    onPressed: () => context.go(RouteNames.login),
                    child: const Text('Log In / Sign Up'),
                  ),
          )),
          const SizedBox(height: 8),

          // Appearance section
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Agency & Appearance', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
          Card(child: Column(children: [
            ListTile(
              leading: const Icon(Icons.business_outlined, size: 22),
              title: Text('Agency Details', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: const Text('Update invoice info & QR code'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => context.go('/settings/agency'),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.group_work_outlined, size: 22),
              title: Text('Team Workspaces', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: const Text('Manage team codes and roles'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                if (!authState.isAuthenticated) {
                  _showLoginDialog(context);
                } else {
                  context.push('/settings/workspaces');
                }
              },
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.palette_outlined, size: 22),
              title: Text('Theme', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(themeState.themeId.displayName),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => context.go('/settings/theme'),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.brightness_6_outlined, size: 22),
              title: Text('Mode', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(themeState.themeMode == ThemeMode.dark ? 'Dark' : themeState.themeMode == ThemeMode.light ? 'Light' : 'System'),
              trailing: Switch(
                value: themeState.themeMode == ThemeMode.dark,
                onChanged: (_) => ref.read(themeNotifierProvider.notifier).toggleThemeMode(),
              ),
            ),
          ])),
          const SizedBox(height: 8),

          // Monthly Targets
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Monthly Targets', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
          _MonthlyTargetsCard(),
          const SizedBox(height: 8),

          // Data section
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Data & Sync', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
          Card(child: Column(children: [
            ListTile(
              leading: Icon(Icons.sync, size: 22, color: authState.isAuthenticated ? const Color(0xFF22C55E) : null),
              title: Text('Sync Status', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(authState.isAuthenticated
                  ? pendingSync.when(
                      data: (count) => count > 0 ? '$count items pending sync' : 'All data synced',
                      loading: () => 'Checking...',
                      error: (_, __) => 'Error checking sync',
                    )
                  : 'Sign in to enable sync'),
              trailing: authState.isAuthenticated
                  ? pendingSync.when(
                      data: (count) => Chip(
                        label: Text(count > 0 ? '$count pending' : 'Synced', style: TextStyle(fontSize: 11, color: count > 0 ? const Color(0xFFF59E0B) : const Color(0xFF22C55E))),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: count > 0 ? const Color(0xFFF59E0B).withValues(alpha: 0.1) : const Color(0xFF22C55E).withValues(alpha: 0.1),
                      ),
                      loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (_, __) => const Icon(Icons.error_outline, size: 18, color: Color(0xFFEF4444)),
                    )
                  : Chip(label: Text('Offline', style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.6))), visualDensity: VisualDensity.compact),
              onTap: authState.isAuthenticated ? () async {
                final engine = ref.read(syncEngineProvider);
                final result = await engine.syncAll();
                ref.invalidate(pendingSyncCountProvider);
                if (context.mounted) {
                  context.showSuccess('Synced ${result.synced} items${result.failed > 0 ? ', ${result.failed} failed' : ''}');
                }
              } : null,
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.download_outlined, size: 22),
              title: Text('Export Data', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: const Text('Export all data as backup'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => context.showSnackBar('Use Reports module for data export'),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.upload_outlined, size: 22),
              title: Text('Import Data', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: const Text('Restore from backup'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => context.showSnackBar('Import coming soon'),
            ),
          ])),
          const SizedBox(height: 8),

          // Notifications
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Notifications', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
          Card(child: Column(children: [
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined, size: 22),
              title: Text('Push Notifications', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              value: true,
              onChanged: (_) {},
            ),
            const Divider(height: 1, indent: 56),
            SwitchListTile(
              secondary: const Icon(Icons.access_time, size: 22),
              title: Text('Meeting Reminders', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              value: true,
              onChanged: (_) {},
            ),
          ])),
          const SizedBox(height: 8),

          // About
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('About', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
          Card(child: Column(children: [
            ListTile(
              leading: const Icon(Icons.info_outline, size: 22),
              title: Text('Version', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              trailing: Text('1.1.0', style: theme.textTheme.bodySmall),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: Icon(Icons.delete_outline, size: 22, color: colors.error),
              title: Text('Clear All Data', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: colors.error)),
              onTap: () {
                showDialog(context: context, builder: (context) => AlertDialog(
                  title: const Text('Clear All Data?'),
                  content: const Text('This will permanently delete all local data. This action cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context), style: FilledButton.styleFrom(backgroundColor: colors.error), child: const Text('Delete')),
                  ],
                ));
              },
            ),
          ])),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: const Text('You must be logged in to access team features. Would you like to log in or create an account now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(RouteNames.login);
            },
            child: const Text('Log In / Sign Up'),
          ),
        ],
      ),
    );
  }
}

// ── Monthly Targets Card ──────────────────────────────────────────────────────

class _MonthlyTargetsCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MonthlyTargetsCard> createState() => _MonthlyTargetsCardState();
}

class _MonthlyTargetsCardState extends ConsumerState<_MonthlyTargetsCard> {
  late TextEditingController _clientCtrl;
  late TextEditingController _outreachCtrl;
  late TextEditingController _mrrCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsServiceProvider);
    _clientCtrl = TextEditingController(text: '${settings.monthlyClientTarget}');
    _outreachCtrl = TextEditingController(text: '${settings.monthlyOutreachTarget}');
    _mrrCtrl = TextEditingController(text: '${settings.monthlyMrrTarget}');
  }

  @override
  void dispose() {
    _clientCtrl.dispose();
    _outreachCtrl.dispose();
    _mrrCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final clientVal = int.tryParse(_clientCtrl.text.trim());
    final outreachVal = int.tryParse(_outreachCtrl.text.trim());
    final mrrVal = int.tryParse(_mrrCtrl.text.trim());
    if (clientVal == null || outreachVal == null || mrrVal == null || clientVal < 1 || outreachVal < 1 || mrrVal < 1) {
      context.showSnackBar('Please enter valid positive numbers.', isError: true);
      return;
    }
    setState(() => _saving = true);
    final settings = ref.read(settingsServiceProvider);
    await settings.setMonthlyClientTarget(clientVal);
    await settings.setMonthlyOutreachTarget(outreachVal);
    await settings.setMonthlyMrrTarget(mrrVal);
    setState(() => _saving = false);
    if (mounted) context.showSuccess('Monthly targets saved!');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes_rounded, size: 20, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Set your monthly goals for client onboarding and cold outreach. These are shown as progress bars on the dashboard.',
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.65)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _clientCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Client Target',
                      prefixIcon: const Icon(Icons.business_center_outlined, size: 20),
                      suffixText: '/ mo',
                      helperText: 'New clients',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _outreachCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Outreach Target',
                      prefixIcon: const Icon(Icons.send_outlined, size: 20),
                      suffixText: '/ mo',
                      helperText: 'Outreach entries',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mrrCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'MRR Target (₹)',
                prefixIcon: const Icon(Icons.currency_rupee, size: 20),
                suffixText: '/ mo',
                helperText: 'Total Monthly Recurring Revenue goal',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_saving ? 'Saving…' : 'Save Targets'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

