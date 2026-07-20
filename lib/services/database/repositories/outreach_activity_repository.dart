import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../isar_service.dart';
import '../collections/outreach_activity_collection.dart';
import '../../workspace_service.dart';

class OutreachActivityRepository {
  final Isar _isar = IsarService.instance;
  final _uuid = const Uuid();
  final String? _workspaceId;

  OutreachActivityRepository(this._workspaceId);

  Future<OutreachActivity> create({
    required String outreachItemId,
    required String type,
    String? description,
  }) async {
    final activity = OutreachActivity()
      ..id = _uuid.v4()
      ..outreachItemId = outreachItemId
      ..type = type
      ..description = description
      ..timestamp = DateTime.now()
      ..workspaceId = _workspaceId
      ..syncStatus = 'pendingCreate'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.outreachActivitys.put(activity);
    });
    return activity;
  }

  Stream<List<OutreachActivity>> watchForOutreachItem(String outreachItemId) {
    return _isar.outreachActivitys
        .filter()
        .outreachItemIdEqualTo(outreachItemId)
        .not().syncStatusEqualTo('pendingDelete')
        .sortByTimestampDesc()
        .watch(fireImmediately: true);
  }
}

final outreachActivityRepositoryProvider = Provider<OutreachActivityRepository>((ref) {
  final wsId = ref.watch(currentWorkspaceIdProvider);
  return OutreachActivityRepository(wsId);
});
