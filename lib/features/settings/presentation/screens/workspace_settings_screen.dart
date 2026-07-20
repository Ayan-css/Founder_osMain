import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/workspace_service.dart';
import '../../../../core/extensions/context_extensions.dart';

class WorkspaceSettingsScreen extends ConsumerStatefulWidget {
  const WorkspaceSettingsScreen({super.key});

  @override
  ConsumerState<WorkspaceSettingsScreen> createState() => _WorkspaceSettingsScreenState();
}

class _WorkspaceSettingsScreenState extends ConsumerState<WorkspaceSettingsScreen> {
  final _joinCodeCtrl = TextEditingController();
  final _createNameCtrl = TextEditingController();
  
  List<Map<String, dynamic>> _workspaces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkspaces();
  }

  @override
  void dispose() {
    _joinCodeCtrl.dispose();
    _createNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWorkspaces() async {
    setState(() => _isLoading = true);
    try {
      final wsService = ref.read(workspaceServiceProvider);
      await wsService.refreshCurrentRole();
      _workspaces = await wsService.fetchMyWorkspaces();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load workspaces')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createWorkspace() async {
    if (_createNameCtrl.text.trim().isEmpty) return;
    try {
      await ref.read(workspaceServiceProvider).createWorkspace(_createNameCtrl.text.trim());
      if (mounted) {
        context.showSuccess('Workspace created');
      }
      _createNameCtrl.clear();
      _loadWorkspaces();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create workspace')));
      }
    }
  }

  Future<void> _joinWorkspace() async {
    if (_joinCodeCtrl.text.trim().isEmpty) return;
    try {
      await ref.read(workspaceServiceProvider).joinWorkspace(_joinCodeCtrl.text.trim());
      if (mounted) {
        context.showSuccess('Joined workspace');
      }
      _joinCodeCtrl.clear();
      _loadWorkspaces();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to join workspace or invalid code')));
      }
    }
  }

  Future<void> _switchWorkspace(String workspaceId, String role, String name) async {
    try {
      await ref.read(workspaceServiceProvider).switchWorkspace(workspaceId, role, ref, name: name);
      if (mounted) context.showSuccess('Switched to workspace. You are now a $role.');
      setState(() {}); // refresh UI to show active
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to switch workspace')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wsService = ref.watch(workspaceServiceProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Team Workspaces')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Join a Workspace', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _joinCodeCtrl,
                        decoration: const InputDecoration(labelText: '6-digit Team Code'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(onPressed: _joinWorkspace, child: const Text('Join')),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                Text('Create a Workspace', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _createNameCtrl,
                        decoration: const InputDecoration(labelText: 'Workspace Name'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.tonal(onPressed: _createWorkspace, child: const Text('Create')),
                  ],
                ),

                const SizedBox(height: 48),

                Text('My Workspaces', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                if (_workspaces.isEmpty)
                  const Text('You are not a member of any workspaces.')
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _workspaces.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ws = _workspaces[index];
                      final isActive = ws['id'] == wsService.currentWorkspaceId;
                      final role = ws['role'] as String;
                      
                      return Card(
                        elevation: isActive ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isActive ? colors.primary : colors.outlineVariant,
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          title: Text(ws['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: SelectableText('Code: ${ws['code']} • Role: $role'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                tooltip: 'Copy Team Code',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: ws['code']));
                                  context.showSnackBar('Copied Team Code: ${ws['code']}');
                                },
                              ),
                              if (!isActive)
                                TextButton(
                                  onPressed: () => _switchWorkspace(ws['id'], role, ws['name']),
                                  child: const Text('Switch'),
                                )
                              else
                                Chip(
                                  label: const Text('Active', style: TextStyle(fontSize: 10)),
                                  backgroundColor: colors.primaryContainer,
                                  side: BorderSide.none,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
              ],
            ),
          ),
    );
  }
}
