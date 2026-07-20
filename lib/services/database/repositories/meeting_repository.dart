import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../isar_service.dart';
import '../collections/meeting_collection.dart';
import '../../workspace_service.dart';

class MeetingRepository {
  final Isar _isar = IsarService.instance;
  final _uuid = const Uuid();
  final String? _workspaceId;

  MeetingRepository(this._workspaceId);

  Future<List<MeetingItem>> getAll() async {
    return _isar.meetingItems.filter().not().syncStatusEqualTo('pendingDelete').sortByDateDesc().findAll();
  }

  Future<MeetingItem?> getById(String id) async {
    return _isar.meetingItems.filter().idEqualTo(id).findFirst();
  }

  Future<List<MeetingItem>> getUpcoming() async {
    return _isar.meetingItems.filter().dateGreaterThan(DateTime.now()).not().syncStatusEqualTo('pendingDelete').sortByDate().findAll();
  }

  Future<List<MeetingItem>> getToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _isar.meetingItems.filter().dateBetween(start, end).not().syncStatusEqualTo('pendingDelete').sortByDate().findAll();
  }

  Future<MeetingItem> create({
    required String type,
    required String title,
    required DateTime date,
    String? agenda,
    List<String> participants = const [],
    String? clientId,
    String? clientName,
  }) async {
    final item = MeetingItem()
      ..id = _uuid.v4()
      ..type = type
      ..title = title
      ..date = date
      ..agenda = agenda
      ..participants = participants
      ..clientId = clientId
      ..clientName = clientName
      ..workspaceId = _workspaceId
      ..syncStatus = 'pendingCreate'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async { await _isar.meetingItems.put(item); });
    return item;
  }

  Future<void> update(MeetingItem item) async {
    item.updatedAt = DateTime.now();
    if (item.syncStatus == 'synced') item.syncStatus = 'pendingUpdate';
    await _isar.writeTxn(() async { await _isar.meetingItems.put(item); });
  }

  Future<void> delete(String id) async {
    final item = await getById(id);
    if (item != null) { item.syncStatus = 'pendingDelete'; await _isar.writeTxn(() async { await _isar.meetingItems.put(item); }); }
  }

  Stream<void> watchAll() => _isar.meetingItems.watchLazy();

  Stream<List<MeetingItem>> watchAllMeetings() {
    return _isar.meetingItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  Stream<List<MeetingItem>> watchTodayMeetings() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _isar.meetingItems
        .filter()
        .dateBetween(start, end)
        .not().syncStatusEqualTo('pendingDelete')
        .sortByDate()
        .watch(fireImmediately: true);
  }
}

final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  final wsId = ref.watch(currentWorkspaceIdProvider);
  return MeetingRepository(wsId);
});
final allMeetingsProvider = StreamProvider<List<MeetingItem>>((ref) => ref.watch(meetingRepositoryProvider).watchAllMeetings());
final upcomingMeetingsProvider = FutureProvider<List<MeetingItem>>((ref) async => ref.watch(meetingRepositoryProvider).getUpcoming());
final todayMeetingsProvider = StreamProvider<List<MeetingItem>>((ref) => ref.watch(meetingRepositoryProvider).watchTodayMeetings());
