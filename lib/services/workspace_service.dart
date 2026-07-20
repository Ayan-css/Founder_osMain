import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'database/isar_service.dart';
import 'database/repositories/task_repository.dart';
import 'database/repositories/content_repository.dart';
import 'database/repositories/lead_repository.dart';
import 'database/repositories/client_repository.dart';
import 'database/repositories/transaction_repository.dart';
import 'database/repositories/knowledge_repository.dart';
import 'database/repositories/meeting_repository.dart';
import 'database/repositories/journal_repository.dart';
import 'database/repositories/focus_repository.dart';
import 'database/repositories/resource_repository.dart';
import 'database/repositories/invoice_repository.dart';
import 'sync/sync_engine.dart';

/// Global state for the active workspace ID.
/// All repositories and providers depend on this.
/// When this changes, Riverpod automatically rebuilds all dependents.
final currentWorkspaceIdProvider = StateProvider<String?>((ref) => null);

class WorkspaceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _currentWorkspaceId;
  String? _currentRole;
  String? _currentWorkspaceName;

  String? get currentWorkspaceId => _currentWorkspaceId;
  String? get currentRole => _currentRole;
  String? get currentWorkspaceName => _currentWorkspaceName;

  bool get isViewer => _currentRole == 'viewer';
  bool get isEditor => _currentRole == 'editor' || _currentRole == 'owner';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentWorkspaceId = prefs.getString('current_workspace_id');
    _currentRole = prefs.getString('current_role');
    _currentWorkspaceName = prefs.getString('current_workspace_name');

    // If we have a workspace ID, let's verify role
    if (_currentWorkspaceId != null) {
      await refreshCurrentRole();
    }
  }

  Future<void> refreshCurrentRole() async {
    if (_currentWorkspaceId == null) return;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final res = await _supabase
          .from('workspace_members')
          .select('role')
          .eq('workspace_id', _currentWorkspaceId!)
          .eq('user_id', user.id)
          .maybeSingle();

      if (res != null) {
        _currentRole = res['role'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_role', _currentRole!);
      } else {
        // User is no longer in this workspace
        await clearCurrentWorkspace();
      }
    } catch (e) {
      // Ignored: might be offline
    }
  }

  Future<void> setCurrentWorkspace(String workspaceId, String role, {String? name}) async {
    _currentWorkspaceId = workspaceId;
    _currentRole = role;
    if (name != null) _currentWorkspaceName = name;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_workspace_id', workspaceId);
    await prefs.setString('current_role', role);
    if (name != null) await prefs.setString('current_workspace_name', name);
  }

  Future<void> clearCurrentWorkspace() async {
    _currentWorkspaceId = null;
    _currentRole = null;
    _currentWorkspaceName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_workspace_id');
    await prefs.remove('current_role');
    await prefs.remove('current_workspace_name');
  }

  /// Full workspace switch: stops sync, switches Isar DB, invalidates all providers.
  Future<void> switchWorkspace(String workspaceId, String role, WidgetRef ref, {String? name}) async {
    debugPrint('[WorkspaceService] Switching to workspace: $workspaceId (role: $role)');

    // 1. Stop sync engine
    try {
      ref.read(syncEngineProvider).stopPeriodicSync();
    } catch (_) {}

    // 2. Persist the selection
    await setCurrentWorkspace(workspaceId, role, name: name);

    // 3. Switch Isar database file
    final dbName = IsarService.dbNameForWorkspace(workspaceId);
    await IsarService.switchDatabase(dbName);

    // 4. Update workspace state provider → triggers all provider rebuilds
    ref.read(currentWorkspaceIdProvider.notifier).state = workspaceId;

    // 5. Invalidate ALL data providers so they re-read from the new DB
    invalidateAllProvidersFromWidget(ref);

    // 6. Restart sync for the new workspace
    try {
      ref.read(syncEngineProvider).startPeriodicSync();
    } catch (_) {}

    debugPrint('[WorkspaceService] Switch complete → $workspaceId');
  }

  /// Invalidate every data provider so screens reload from the new Isar DB.
  static void _invalidateAllProviders(Ref ref) {
    // Tasks
    ref.invalidate(allTasksProvider);
    ref.invalidate(pinnedTasksProvider);
    ref.invalidate(openTaskCountProvider);
    // Content
    ref.invalidate(allContentProvider);
    // Leads
    ref.invalidate(allLeadsProvider);
    ref.invalidate(leadsByStageProvider);
    ref.invalidate(activeLeadCountProvider);
    ref.invalidate(pipelineValueProvider);
    // Clients
    ref.invalidate(allClientsProvider);
    ref.invalidate(activeClientCountProvider);
    ref.invalidate(pendingPaymentsProvider);
    // Transactions
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(totalRevenueProvider);
    ref.invalidate(totalExpensesProvider);
    ref.invalidate(totalProfitProvider);
    ref.invalidate(expensesByCategoryProvider);
    ref.invalidate(monthlyTrendProvider);
    // Knowledge
    ref.invalidate(allKnowledgeProvider);
    // Meetings
    ref.invalidate(allMeetingsProvider);
    ref.invalidate(todayMeetingsProvider);
    // Journal
    ref.invalidate(allJournalProvider);
    // Focus
    ref.invalidate(todayFocusMinutesProvider);
    ref.invalidate(weekFocusMinutesProvider);
    ref.invalidate(monthFocusMinutesProvider);
    // Resources
    ref.invalidate(allResourcesProvider);
    // Invoices
    ref.invalidate(allInvoicesProvider);
    // Sync
    ref.invalidate(pendingSyncCountProvider);
  }

  /// Also expose the invalidation for use from WidgetRef contexts
  static void invalidateAllProvidersFromWidget(WidgetRef ref) {
    ref.invalidate(allTasksProvider);
    ref.invalidate(pinnedTasksProvider);
    ref.invalidate(openTaskCountProvider);
    ref.invalidate(allContentProvider);
    ref.invalidate(allLeadsProvider);
    ref.invalidate(leadsByStageProvider);
    ref.invalidate(activeLeadCountProvider);
    ref.invalidate(pipelineValueProvider);
    ref.invalidate(allClientsProvider);
    ref.invalidate(activeClientCountProvider);
    ref.invalidate(pendingPaymentsProvider);
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(totalRevenueProvider);
    ref.invalidate(totalExpensesProvider);
    ref.invalidate(totalProfitProvider);
    ref.invalidate(expensesByCategoryProvider);
    ref.invalidate(monthlyTrendProvider);
    ref.invalidate(allKnowledgeProvider);
    ref.invalidate(allMeetingsProvider);
    ref.invalidate(todayMeetingsProvider);
    ref.invalidate(allJournalProvider);
    ref.invalidate(todayFocusMinutesProvider);
    ref.invalidate(weekFocusMinutesProvider);
    ref.invalidate(monthFocusMinutesProvider);
    ref.invalidate(allResourcesProvider);
    ref.invalidate(allInvoicesProvider);
    ref.invalidate(pendingSyncCountProvider);
  }

  /// Fetch all workspaces the current user is a member of.
  /// Uses an RPC function to bypass RLS on the workspaces table.
  Future<List<Map<String, dynamic>>> fetchMyWorkspaces() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      // Try RPC first (bypasses RLS)
      final response = await _supabase.rpc('get_my_workspaces');
      return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      // Fallback: direct query with null-safety for when RPC doesn't exist yet
      try {
        final response = await _supabase
            .from('workspace_members')
            .select('''
              role,
              workspaces (
                id,
                name,
                code
              )
            ''')
            .eq('user_id', user.id);

        return (response as List)
            .where((e) => e['workspaces'] != null)
            .map((e) {
          final ws = e['workspaces'] as Map<String, dynamic>;
          return {
            'id': ws['id'],
            'name': ws['name'],
            'code': ws['code'],
            'role': e['role'],
          };
        }).toList();
      } catch (e2) {
        return [];
      }
    }
  }

  /// Create a new workspace and become the owner
  Future<Map<String, dynamic>> createWorkspace(String name) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Generate a simple 6-character code
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final uniqueCode = timestamp.substring(timestamp.length - 6); 

    // Generate UUID manually so we don't have to select() after insert
    // (RLS prevents reading until we are added to workspace_members)
    final workspaceId = const Uuid().v4();

    // Insert workspace without selecting it back
    await _supabase
        .from('workspaces')
        .insert({
          'id': workspaceId,
          'name': name,
          'code': uniqueCode,
        });

    // Add current user as owner
    await _supabase.from('workspace_members').insert({
      'workspace_id': workspaceId,
      'user_id': user.id,
      'role': 'owner',
    });

    await setCurrentWorkspace(workspaceId, 'owner');

    return {
      'id': workspaceId,
      'name': name,
      'code': uniqueCode,
    };
  }

  /// Join an existing workspace using a code.
  /// Uses an RPC function to find workspace by code (bypasses RLS).
  Future<Map<String, dynamic>> joinWorkspace(String code) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    Map<String, dynamic>? wsResponse;

    // Try RPC first to find workspace by code (bypasses RLS)
    try {
      final rpcResult = await _supabase.rpc(
        'find_workspace_by_code',
        params: {'invite_code': code},
      );
      if (rpcResult != null && (rpcResult as List).isNotEmpty) {
        wsResponse = Map<String, dynamic>.from(rpcResult[0]);
      }
    } catch (_) {
      // RPC doesn't exist, try direct query
      wsResponse = await _supabase
          .from('workspaces')
          .select()
          .eq('code', code)
          .maybeSingle();
    }

    if (wsResponse == null) {
      throw Exception('Workspace not found with code: $code');
    }

    final workspaceId = wsResponse['id'];

    // Check if already a member
    final existingMember = await _supabase
        .from('workspace_members')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existingMember != null) {
      // Already a member, just switch to it
      await setCurrentWorkspace(workspaceId, existingMember['role']);
      return wsResponse;
    }

    // Join as viewer by default (owners can upgrade them later)
    await _supabase.from('workspace_members').insert({
      'workspace_id': workspaceId,
      'user_id': user.id,
      'role': 'viewer',
    });

    await setCurrentWorkspace(workspaceId, 'viewer');

    return wsResponse;
  }
}

final workspaceServiceProvider = Provider<WorkspaceService>((ref) {
  return WorkspaceService();
});
