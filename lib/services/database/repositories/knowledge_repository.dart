import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../isar_service.dart';
import '../collections/knowledge_collection.dart';
import '../../workspace_service.dart';

class KnowledgeRepository {
  final Isar _isar = IsarService.instance;
  final _uuid = const Uuid();
  final String? _workspaceId;

  KnowledgeRepository(this._workspaceId);

  Future<List<KnowledgeItem>> getAll() async {
    return _isar.knowledgeItems.filter().not().syncStatusEqualTo('pendingDelete').sortByUpdatedAtDesc().findAll();
  }

  Future<KnowledgeItem?> getById(String id) async {
    return _isar.knowledgeItems.filter().idEqualTo(id).findFirst();
  }

  Future<List<KnowledgeItem>> getByCategory(String category) async {
    return _isar.knowledgeItems.filter().categoryEqualTo(category).not().syncStatusEqualTo('pendingDelete').findAll();
  }

  Future<List<KnowledgeItem>> getFavorites() async {
    return _isar.knowledgeItems.filter().isFavoriteEqualTo(true).not().syncStatusEqualTo('pendingDelete').findAll();
  }

  Future<List<KnowledgeItem>> search(String query) async {
    return _isar.knowledgeItems.filter()
        .group((q) => q.titleContains(query, caseSensitive: false).or().contentContains(query, caseSensitive: false))
        .not().syncStatusEqualTo('pendingDelete')
        .findAll();
  }

  Future<KnowledgeItem> create({
    required String title,
    required String content,
    required String category,
    String? collectionName,
    List<String> tags = const [],
  }) async {
    final item = KnowledgeItem()
      ..id = _uuid.v4()
      ..title = title
      ..content = content
      ..category = category
      ..collectionName = collectionName
      ..tags = tags
      ..workspaceId = _workspaceId
      ..syncStatus = 'pendingCreate'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async { await _isar.knowledgeItems.put(item); });
    return item;
  }

  Future<void> update(KnowledgeItem item) async {
    item.updatedAt = DateTime.now();
    if (item.syncStatus == 'synced') item.syncStatus = 'pendingUpdate';
    await _isar.writeTxn(() async { await _isar.knowledgeItems.put(item); });
  }

  Future<void> toggleFavorite(String id) async {
    final item = await getById(id);
    if (item != null) { item.isFavorite = !item.isFavorite; await update(item); }
  }

  Future<void> delete(String id) async {
    final item = await getById(id);
    if (item != null) { item.syncStatus = 'pendingDelete'; await _isar.writeTxn(() async { await _isar.knowledgeItems.put(item); }); }
  }

  Stream<void> watchAll() => _isar.knowledgeItems.watchLazy();
}

final knowledgeRepositoryProvider = Provider<KnowledgeRepository>((ref) {
  final wsId = ref.watch(currentWorkspaceIdProvider);
  return KnowledgeRepository(wsId);
});
final allKnowledgeProvider = FutureProvider<List<KnowledgeItem>>((ref) async => ref.watch(knowledgeRepositoryProvider).getAll());
final favoriteKnowledgeProvider = FutureProvider<List<KnowledgeItem>>((ref) async => ref.watch(knowledgeRepositoryProvider).getFavorites());
