import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../isar_service.dart';
import '../collections/lead_collection.dart';
import '../../workspace_service.dart';

class LeadRepository {
  final Isar _isar = IsarService.instance;
  final _uuid = const Uuid();
  final String? _workspaceId;

  LeadRepository(this._workspaceId);

  Future<List<LeadItem>> getAll() async {
    return _isar.leadItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<LeadItem?> getById(String id) async {
    return _isar.leadItems.filter().idEqualTo(id).findFirst();
  }

  Future<List<LeadItem>> getByStage(String stage) async {
    return _isar.leadItems
        .filter()
        .stageEqualTo(stage)
        .not().syncStatusEqualTo('pendingDelete')
        .findAll();
  }

  Future<Map<String, List<LeadItem>>> getGroupedByStage() async {
    final all = await getAll();
    final map = <String, List<LeadItem>>{};
    for (final item in all) {
      map.putIfAbsent(item.stage, () => []).add(item);
    }
    return map;
  }

  Future<int> getActiveLeadCount() async {
    return _isar.leadItems
        .filter()
        .not().stageEqualTo('Won')
        .not().stageEqualTo('Lost')
        .not().syncStatusEqualTo('pendingDelete')
        .count();
  }

  Future<double> getTotalPipelineValue() async {
    final leads = await _isar.leadItems
        .filter()
        .not().stageEqualTo('Lost')
        .not().syncStatusEqualTo('pendingDelete')
        .findAll();
    return leads.fold<double>(0.0, (sum, lead) => sum + lead.dealValue);
  }

  Future<double> getWinRate() async {
    final won = await _isar.leadItems.filter().stageEqualTo('Won').count();
    final lost = await _isar.leadItems.filter().stageEqualTo('Lost').count();
    final total = won + lost;
    if (total == 0) return 0;
    return (won / total) * 100;
  }

  Future<LeadItem> create({
    required String name,
    String? company,
    String? email,
    String? phone,
    String? leadSource,
    String? industry,
    double dealValue = 0,
    String stage = 'New Lead',
    String? notes,
    DateTime? followUpDate,
  }) async {
    final item = LeadItem()
      ..id = _uuid.v4()
      ..name = name
      ..company = company
      ..email = email
      ..phone = phone
      ..leadSource = leadSource
      ..industry = industry
      ..dealValue = dealValue
      ..stage = stage
      ..notes = notes
      ..followUpDate = followUpDate
      ..workspaceId = _workspaceId
      ..syncStatus = 'pendingCreate'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.leadItems.put(item);
    });
    return item;
  }

  Future<void> update(LeadItem item) async {
    item.updatedAt = DateTime.now();
    if (item.syncStatus == 'synced') {
      item.syncStatus = 'pendingUpdate';
    }
    await _isar.writeTxn(() async {
      await _isar.leadItems.put(item);
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
      await _isar.writeTxn(() async {
        await _isar.leadItems.put(item);
      });
    }
  }

  Stream<void> watchAll() => _isar.leadItems.watchLazy();

  Stream<List<LeadItem>> watchAllLeads() {
    return _isar.leadItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  Stream<int> watchActiveLeadCount() {
    return _isar.leadItems
        .filter()
        .not().stageEqualTo('Won')
        .not().stageEqualTo('Lost')
        .not().syncStatusEqualTo('pendingDelete')
        .watch(fireImmediately: true)
        .map((leads) => leads.length);
  }
}

final leadRepositoryProvider = Provider<LeadRepository>((ref) {
  final wsId = ref.watch(currentWorkspaceIdProvider);
  return LeadRepository(wsId);
});

final allLeadsProvider = StreamProvider<List<LeadItem>>((ref) {
  return ref.watch(leadRepositoryProvider).watchAllLeads();
});

final leadsByStageProvider = StreamProvider<Map<String, List<LeadItem>>>((ref) async* {
  await for (final leads in ref.watch(leadRepositoryProvider).watchAllLeads()) {
    final map = <String, List<LeadItem>>{};
    for (final item in leads) {
      map.putIfAbsent(item.stage, () => []).add(item);
    }
    yield map;
  }
});

final activeLeadCountProvider = StreamProvider<int>((ref) {
  return ref.watch(leadRepositoryProvider).watchActiveLeadCount();
});

final pipelineValueProvider = StreamProvider<double>((ref) async* {
  await for (final leads in ref.watch(leadRepositoryProvider).watchAllLeads()) {
    yield leads.where((l) => l.stage != 'Lost').fold<double>(0.0, (sum, lead) => sum + lead.dealValue);
  }
});
