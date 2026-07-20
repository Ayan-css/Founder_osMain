import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../isar_service.dart';
import '../collections/resource_collection.dart';
import '../../workspace_service.dart';

class ResourceRepository {
  final Isar _isar = IsarService.instance;
  final _uuid = const Uuid();
  final String? _workspaceId;

  ResourceRepository(this._workspaceId);

  Future<List<ResourceItem>> getAll() async {
    return _isar.resourceItems.filter().not().syncStatusEqualTo('pendingDelete').sortByName().findAll();
  }

  Future<List<ResourceItem>> getExisting() async {
    return _isar.resourceItems.filter().isPurchasedEqualTo(true).not().syncStatusEqualTo('pendingDelete').findAll();
  }

  Future<List<ResourceItem>> getWishlist() async {
    return _isar.resourceItems.filter().isPurchasedEqualTo(false).not().syncStatusEqualTo('pendingDelete').findAll();
  }

  Future<double> getTotalCost() async {
    final items = await getExisting();
    return items.fold<double>(0.0, (sum, r) => sum + r.cost);
  }

  Future<double> getPlannedBudget() async {
    final items = await getWishlist();
    return items.fold<double>(0.0, (sum, r) => sum + r.estimatedCost);
  }

  Future<List<ResourceItem>> getUpcomingRenewals() async {
    final now = DateTime.now();
    final thirtyDays = now.add(const Duration(days: 30));
    return _isar.resourceItems.filter()
        .isPurchasedEqualTo(true)
        .renewalDateIsNotNull()
        .renewalDateBetween(now, thirtyDays)
        .not().syncStatusEqualTo('pendingDelete')
        .sortByRenewalDate()
        .findAll();
  }

  Future<ResourceItem> create({
    required String name,
    required String type,
    double cost = 0,
    String? description,
    bool isPurchased = true,
    DateTime? renewalDate,
    double estimatedCost = 0,
    String priority = 'Medium',
    String? purchaseReason,
    DateTime? targetPurchaseDate,
  }) async {
    final item = ResourceItem()
      ..id = _uuid.v4()
      ..name = name
      ..type = type
      ..cost = cost
      ..description = description
      ..isPurchased = isPurchased
      ..renewalDate = renewalDate
      ..estimatedCost = estimatedCost
      ..priority = priority
      ..purchaseReason = purchaseReason
      ..targetPurchaseDate = targetPurchaseDate
      ..workspaceId = _workspaceId
      ..syncStatus = 'pendingCreate'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async { await _isar.resourceItems.put(item); });
    return item;
  }

  Future<void> update(ResourceItem item) async {
    item.updatedAt = DateTime.now();
    if (item.syncStatus == 'synced') item.syncStatus = 'pendingUpdate';
    await _isar.writeTxn(() async { await _isar.resourceItems.put(item); });
  }

  Future<void> delete(String id) async {
    final item = await _isar.resourceItems.filter().idEqualTo(id).findFirst();
    if (item != null) { item.syncStatus = 'pendingDelete'; await _isar.writeTxn(() async { await _isar.resourceItems.put(item); }); }
  }

  Stream<void> watchAll() => _isar.resourceItems.watchLazy();
}

final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  final wsId = ref.watch(currentWorkspaceIdProvider);
  return ResourceRepository(wsId);
});
final allResourcesProvider = FutureProvider<List<ResourceItem>>((ref) async => ref.watch(resourceRepositoryProvider).getAll());
final existingResourcesProvider = FutureProvider<List<ResourceItem>>((ref) async => ref.watch(resourceRepositoryProvider).getExisting());
final wishlistResourcesProvider = FutureProvider<List<ResourceItem>>((ref) async => ref.watch(resourceRepositoryProvider).getWishlist());
