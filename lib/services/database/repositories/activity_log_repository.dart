import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../isar_service.dart';
import '../collections/activity_log_collection.dart';
import '../../workspace_service.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';

class ActivityLogRepository {
  final Isar _isar = IsarService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch latest logs from Supabase for the current workspace and cache them locally
  Future<void> syncDownLogs(String workspaceId) async {
    try {
      final response = await _supabase
          .from('activity_log')
          .select()
          .eq('workspace_id', workspaceId)
          .order('created_at', ascending: false)
          .limit(100);

      final List<ActivityLogItem> items = [];
      for (final json in response) {
        items.add(ActivityLogItem.fromJson(json));
      }

      await _isar.writeTxn(() async {
        // Clear old logs for this workspace to avoid unlimited growth
        await _isar.activityLogItems.filter().workspaceIdEqualTo(workspaceId).deleteAll();
        await _isar.activityLogItems.putAll(items);
      });
    } catch (e) {
      // Ignore network errors, local cache remains
    }
  }

  /// Watch local activity logs for the current workspace
  Stream<List<ActivityLogItem>> watchLogs(String workspaceId) {
    return _isar.activityLogItems
        .filter()
        .workspaceIdEqualTo(workspaceId)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }
}

final activityLogRepositoryProvider = Provider<ActivityLogRepository>((ref) {
  return ActivityLogRepository();
});

final workspaceActivityLogsProvider = StreamProvider<List<ActivityLogItem>>((ref) async* {
  final repo = ref.watch(activityLogRepositoryProvider);
  final workspaceId = ref.watch(currentWorkspaceIdProvider);
  final isAuth = ref.watch(isAuthenticatedProvider);

  if (workspaceId == null || !isAuth) {
    yield [];
    return;
  }

  // Trigger background sync
  repo.syncDownLogs(workspaceId);

  // Yield local stream
  yield* repo.watchLogs(workspaceId);
});
