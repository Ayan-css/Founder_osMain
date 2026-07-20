import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../isar_service.dart';
import '../collections/outreach_collection.dart';
import '../../workspace_service.dart';
import '../../notification_service.dart';

class OutreachRepository {
  final Isar _isar = IsarService.instance;
  final _uuid = const Uuid();
  final String? _workspaceId;

  OutreachRepository(this._workspaceId);

  Future<List<OutreachItem>> getAll() async {
    return _isar.outreachItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<OutreachItem?> getById(String id) async {
    return _isar.outreachItems.filter().idEqualTo(id).findFirst();
  }

  Future<int> getThisMonthCount() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(microseconds: 1));
    return _isar.outreachItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .createdAtBetween(startOfMonth, endOfMonth)
        .count();
  }

  Future<OutreachItem> create({
    required String name,
    String? company,
    required String platform,
    String status = 'Not Replied',
    String? contactDetail,
    String? notes,
    DateTime? followUpDate,
    String? campaignId,
    String priority = 'Medium',
  }) async {
    final item = OutreachItem()
      ..id = _uuid.v4()
      ..name = name
      ..company = company
      ..platform = platform
      ..status = status
      ..contactDetail = contactDetail
      ..notes = notes
      ..followUpDate = followUpDate
      ..campaignId = campaignId
      ..priority = priority
      ..workspaceId = _workspaceId
      ..syncStatus = 'pendingCreate'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.outreachItems.put(item);
    });
    
    if (followUpDate != null) {
      NotificationService().scheduleFollowUpReminder(item);
    }
    
    return item;
  }

  Future<void> update(OutreachItem item) async {
    item.updatedAt = DateTime.now();
    if (item.syncStatus == 'synced') item.syncStatus = 'pendingUpdate';
    await _isar.writeTxn(() async {
      await _isar.outreachItems.put(item);
    });
    
    if (item.followUpDate != null) {
      NotificationService().scheduleFollowUpReminder(item);
    } else {
      NotificationService().cancelFollowUpReminder(item.id);
    }
  }

  Future<void> delete(String id) async {
    final item = await getById(id);
    if (item != null) {
      item.syncStatus = 'pendingDelete';
      await _isar.writeTxn(() async {
        await _isar.outreachItems.put(item);
      });
      NotificationService().cancelFollowUpReminder(id);
    }
  }

  Stream<List<OutreachItem>> watchAll() {
    return _isar.outreachItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  Stream<int> watchThisMonthCount() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(microseconds: 1));
    return _isar.outreachItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .createdAtBetween(startOfMonth, endOfMonth)
        .watch(fireImmediately: true)
        .map((items) => items.length);
  }
}

final outreachRepositoryProvider = Provider<OutreachRepository>((ref) {
  final wsId = ref.watch(currentWorkspaceIdProvider);
  return OutreachRepository(wsId);
});

final allOutreachProvider = StreamProvider<List<OutreachItem>>((ref) {
  return ref.watch(outreachRepositoryProvider).watchAll();
});

final monthlyOutreachCountProvider = StreamProvider<int>((ref) {
  return ref.watch(outreachRepositoryProvider).watchThisMonthCount();
});
