import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../isar_service.dart';
import '../collections/template_collection.dart';
import '../../workspace_service.dart';

class TemplateRepository {
  final Isar _isar = IsarService.instance;
  final _uuid = const Uuid();
  final String? _workspaceId;

  TemplateRepository(this._workspaceId);

  Future<TemplateItem> create({
    required String name,
    required String platform,
    String? subject,
    required String body,
  }) async {
    final template = TemplateItem()
      ..id = _uuid.v4()
      ..name = name
      ..platform = platform
      ..subject = subject
      ..body = body
      ..workspaceId = _workspaceId
      ..syncStatus = 'pendingCreate'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.templateItems.put(template);
    });
    return template;
  }

  Future<void> update(TemplateItem template) async {
    template.updatedAt = DateTime.now();
    if (template.syncStatus == 'synced') template.syncStatus = 'pendingUpdate';
    await _isar.writeTxn(() async {
      await _isar.templateItems.put(template);
    });
  }

  Future<void> delete(String id) async {
    final item = await _isar.templateItems.filter().idEqualTo(id).findFirst();
    if (item != null) {
      item.syncStatus = 'pendingDelete';
      await _isar.writeTxn(() async {
        await _isar.templateItems.put(item);
      });
    }
  }

  Stream<List<TemplateItem>> watchAll() {
    return _isar.templateItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .sortByName()
        .watch(fireImmediately: true);
  }
}

final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  final wsId = ref.watch(currentWorkspaceIdProvider);
  return TemplateRepository(wsId);
});

final allTemplatesProvider = StreamProvider<List<TemplateItem>>((ref) {
  return ref.watch(templateRepositoryProvider).watchAll();
});
