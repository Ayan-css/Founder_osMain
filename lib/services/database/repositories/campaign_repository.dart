import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../isar_service.dart';
import '../collections/campaign_collection.dart';
import '../../workspace_service.dart';

class CampaignRepository {
  final Isar _isar = IsarService.instance;
  final _uuid = const Uuid();
  final String? _workspaceId;

  CampaignRepository(this._workspaceId);

  Future<CampaignItem> create({
    required String name,
    String? description,
    String status = 'Active',
  }) async {
    final campaign = CampaignItem()
      ..id = _uuid.v4()
      ..name = name
      ..description = description
      ..status = status
      ..workspaceId = _workspaceId
      ..syncStatus = 'pendingCreate'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.campaignItems.put(campaign);
    });
    return campaign;
  }

  Stream<List<CampaignItem>> watchAll() {
    return _isar.campaignItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .sortByName()
        .watch(fireImmediately: true);
  }
}

final campaignRepositoryProvider = Provider<CampaignRepository>((ref) {
  final wsId = ref.watch(currentWorkspaceIdProvider);
  return CampaignRepository(wsId);
});

final allCampaignsProvider = StreamProvider<List<CampaignItem>>((ref) {
  return ref.watch(campaignRepositoryProvider).watchAll();
});
