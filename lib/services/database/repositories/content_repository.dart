import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../isar_service.dart';
import '../collections/content_collection.dart';
import '../../workspace_service.dart';

class ContentRepository {
  final Isar _isar = IsarService.instance;
  final _uuid = const Uuid();
  final String? _workspaceId;

  ContentRepository(this._workspaceId);

  Future<List<ContentItem>> getAll() async {
    return _isar.contentItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<ContentItem?> getById(String id) async {
    return _isar.contentItems.filter().idEqualTo(id).findFirst();
  }

  Future<List<ContentItem>> getByStage(String stage) async {
    return _isar.contentItems
        .filter()
        .stageEqualTo(stage)
        .not().syncStatusEqualTo('pendingDelete')
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<Map<String, List<ContentItem>>> getGroupedByStage() async {
    final all = await getAll();
    final map = <String, List<ContentItem>>{};
    for (final item in all) {
      map.putIfAbsent(item.stage, () => []).add(item);
    }
    return map;
  }

  Future<int> getCountByStage(String stage) async {
    return _isar.contentItems
        .filter()
        .stageEqualTo(stage)
        .not().syncStatusEqualTo('pendingDelete')
        .count();
  }

  Future<ContentItem> create({
    required String title,
    String? description,
    String stage = 'Raw Thought',
    List<String> tags = const [],
    String? category,
    String? format,
    String? platform,
    String priority = 'Medium',
    DateTime? dueDate,
    String? notes,
  }) async {
    final item = ContentItem()
      ..id = _uuid.v4()
      ..title = title
      ..description = description
      ..stage = stage
      ..tags = tags
      ..category = category
      ..format = format
      ..platform = platform
      ..priority = priority
      ..dueDate = dueDate
      ..notes = notes
      ..workspaceId = _workspaceId
      ..syncStatus = 'pendingCreate'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.contentItems.put(item);
    });
    return item;
  }

  Future<void> update(ContentItem item) async {
    item.updatedAt = DateTime.now();
    item.version += 1;
    if (item.syncStatus == 'synced') {
      item.syncStatus = 'pendingUpdate';
    }
    await _isar.writeTxn(() async {
      await _isar.contentItems.put(item);
    });
  }

  Future<void> moveToStage(String id, String newStage) async {
    final item = await getById(id);
    if (item != null) {
      item.stage = newStage;
      await update(item);
    }
  }

  Future<void> delete(String id) async {
    final item = await getById(id);
    if (item != null) {
      item.syncStatus = 'pendingDelete';
      item.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.contentItems.put(item);
      });
    }
  }

  Stream<void> watchAll() {
    return _isar.contentItems.watchLazy();
  }

  Stream<List<ContentItem>> watchAllContent() {
    return _isar.contentItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }
}

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final wsId = ref.watch(currentWorkspaceIdProvider);
  return ContentRepository(wsId);
});

final allContentProvider = StreamProvider<List<ContentItem>>((ref) {
  return ref.watch(contentRepositoryProvider).watchAllContent();
});

final contentByStageProvider = StreamProvider<Map<String, List<ContentItem>>>((ref) async* {
  await for (final content in ref.watch(contentRepositoryProvider).watchAllContent()) {
    final map = <String, List<ContentItem>>{};
    for (final item in content) {
      map.putIfAbsent(item.stage, () => []).add(item);
    }
    yield map;
  }
});
