import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../isar_service.dart';
import '../collections/focus_session_collection.dart';
import '../../workspace_service.dart';

class FocusRepository {
  final Isar _isar = IsarService.instance;
  final _uuid = const Uuid();
  final String? _workspaceId;

  FocusRepository(this._workspaceId);

  Future<List<FocusSession>> getAll() async {
    return _isar.focusSessions.filter().not().syncStatusEqualTo('pendingDelete').sortByStartTimeDesc().findAll();
  }

  Future<List<FocusSession>> getToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _isar.focusSessions.filter().startTimeBetween(start, end).not().syncStatusEqualTo('pendingDelete').findAll();
  }

  Future<int> getTodayFocusMinutes() async {
    final sessions = await getToday();
    return sessions.where((s) => s.completed).fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  Future<int> getWeekFocusMinutes() async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(start.year, start.month, start.day);
    final sessions = await _isar.focusSessions.filter()
        .startTimeGreaterThan(startOfWeek)
        .completedEqualTo(true)
        .not().syncStatusEqualTo('pendingDelete')
        .findAll();
    return sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  Future<int> getMonthFocusMinutes() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final sessions = await _isar.focusSessions.filter()
        .startTimeGreaterThan(startOfMonth)
        .completedEqualTo(true)
        .not().syncStatusEqualTo('pendingDelete')
        .findAll();
    return sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  Future<int> getCurrentStreak() async {
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final count = await _isar.focusSessions.filter()
          .startTimeBetween(start, end)
          .completedEqualTo(true)
          .not().syncStatusEqualTo('pendingDelete')
          .count();
      if (count > 0) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  Future<FocusSession> create({
    required String type,
    required int durationMinutes,
    String? label,
  }) async {
    final item = FocusSession()
      ..id = _uuid.v4()
      ..type = type
      ..durationMinutes = durationMinutes
      ..startTime = DateTime.now()
      ..completed = false
      ..label = label
      ..workspaceId = _workspaceId
      ..syncStatus = 'pendingCreate'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async { await _isar.focusSessions.put(item); });
    return item;
  }

  Future<void> completeSession(String id) async {
    final item = await _isar.focusSessions.filter().idEqualTo(id).findFirst();
    if (item != null) {
      item.completed = true;
      item.endTime = DateTime.now();
      item.updatedAt = DateTime.now();
      if (item.syncStatus == 'synced') item.syncStatus = 'pendingUpdate';
      await _isar.writeTxn(() async { await _isar.focusSessions.put(item); });
    }
  }

  Stream<void> watchAll() => _isar.focusSessions.watchLazy();

  Stream<List<FocusSession>> watchAllFocusSessions() {
    return _isar.focusSessions
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .sortByStartTimeDesc()
        .watch(fireImmediately: true);
  }

  Stream<int> watchTodayFocusMinutes() {
    return watchAllFocusSessions().map((sessions) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      return sessions
          .where((s) => s.completed && s.startTime.isAfter(start) && s.startTime.isBefore(end))
          .fold<int>(0, (sum, s) => sum + s.durationMinutes);
    });
  }

  Stream<int> watchWeekFocusMinutes() {
    return watchAllFocusSessions().map((sessions) {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(start.year, start.month, start.day);
      return sessions
          .where((s) => s.completed && s.startTime.isAfter(startOfWeek))
          .fold<int>(0, (sum, s) => sum + s.durationMinutes);
    });
  }

  Stream<int> watchMonthFocusMinutes() {
    return watchAllFocusSessions().map((sessions) {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      return sessions
          .where((s) => s.completed && s.startTime.isAfter(startOfMonth))
          .fold<int>(0, (sum, s) => sum + s.durationMinutes);
    });
  }
}

final focusRepositoryProvider = Provider<FocusRepository>((ref) {
  final wsId = ref.watch(currentWorkspaceIdProvider);
  return FocusRepository(wsId);
});

final allFocusSessionsProvider = StreamProvider<List<FocusSession>>((ref) {
  return ref.watch(focusRepositoryProvider).watchAllFocusSessions();
});

final todayFocusMinutesProvider = StreamProvider<int>((ref) {
  return ref.watch(focusRepositoryProvider).watchTodayFocusMinutes();
});

final weekFocusMinutesProvider = StreamProvider<int>((ref) {
  return ref.watch(focusRepositoryProvider).watchWeekFocusMinutes();
});

final monthFocusMinutesProvider = StreamProvider<int>((ref) {
  return ref.watch(focusRepositoryProvider).watchMonthFocusMinutes();
});

final focusStreakProvider = FutureProvider<int>((ref) async => ref.watch(focusRepositoryProvider).getCurrentStreak());
