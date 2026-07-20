import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../isar_service.dart';
import '../collections/journal_collection.dart';
import '../../workspace_service.dart';

class JournalRepository {
  final Isar _isar = IsarService.instance;
  final _uuid = const Uuid();
  final String? _workspaceId;

  JournalRepository(this._workspaceId);

  Future<List<JournalEntry>> getAll() async {
    return _isar.journalEntrys.filter().not().syncStatusEqualTo('pendingDelete').sortByDateDesc().findAll();
  }

  Future<JournalEntry?> getById(String id) async {
    return _isar.journalEntrys.filter().idEqualTo(id).findFirst();
  }

  Future<JournalEntry?> getToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _isar.journalEntrys.filter().dateBetween(start, end).not().syncStatusEqualTo('pendingDelete').findFirst();
  }

  Future<List<JournalEntry>> getByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return _isar.journalEntrys.filter().dateBetween(start, end).not().syncStatusEqualTo('pendingDelete').sortByDateDesc().findAll();
  }

  Future<int> getTotalEntries() async {
    return _isar.journalEntrys.filter().not().syncStatusEqualTo('pendingDelete').count();
  }

  Future<double> getAverageMood() async {
    final entries = await getAll();
    if (entries.isEmpty) return 0;
    return entries.fold(0.0, (sum, e) => sum + e.mood) / entries.length;
  }

  Future<JournalEntry> create({
    required DateTime date,
    String? wentWell,
    String? didNotGoWell,
    String? lessonsLearned,
    String? wins,
    String? mistakes,
    String? gratitude,
    String? improvementsForTomorrow,
    int mood = 3,
  }) async {
    final item = JournalEntry()
      ..id = _uuid.v4()
      ..date = date
      ..wentWell = wentWell
      ..didNotGoWell = didNotGoWell
      ..lessonsLearned = lessonsLearned
      ..wins = wins
      ..mistakes = mistakes
      ..gratitude = gratitude
      ..improvementsForTomorrow = improvementsForTomorrow
      ..mood = mood
      ..workspaceId = _workspaceId
      ..syncStatus = 'pendingCreate'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async { await _isar.journalEntrys.put(item); });
    return item;
  }

  Future<void> update(JournalEntry item) async {
    item.updatedAt = DateTime.now();
    if (item.syncStatus == 'synced') item.syncStatus = 'pendingUpdate';
    await _isar.writeTxn(() async { await _isar.journalEntrys.put(item); });
  }

  Future<void> delete(String id) async {
    final item = await getById(id);
    if (item != null) { item.syncStatus = 'pendingDelete'; await _isar.writeTxn(() async { await _isar.journalEntrys.put(item); }); }
  }

  Stream<void> watchAll() => _isar.journalEntrys.watchLazy();
}

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final wsId = ref.watch(currentWorkspaceIdProvider);
  return JournalRepository(wsId);
});
final allJournalProvider = FutureProvider<List<JournalEntry>>((ref) async => ref.watch(journalRepositoryProvider).getAll());
final todayJournalProvider = FutureProvider<JournalEntry?>((ref) async => ref.watch(journalRepositoryProvider).getToday());
