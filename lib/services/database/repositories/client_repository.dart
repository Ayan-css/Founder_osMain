import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../isar_service.dart';
import '../collections/client_collection.dart';
import '../../workspace_service.dart';
import '../../widget_service.dart';

class ClientRepository {
  final Isar _isar = IsarService.instance;
  final _uuid = const Uuid();
  final String? _workspaceId;

  ClientRepository(this._workspaceId);

  Future<List<ClientItem>> getAll() async {
    return _isar.clientItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .sortByName()
        .findAll();
  }

  Future<ClientItem?> getById(String id) async {
    return _isar.clientItems.filter().idEqualTo(id).findFirst();
  }

  Future<int> getActiveCount() async {
    return _isar.clientItems
        .filter()
        .statusEqualTo('Active')
        .not().syncStatusEqualTo('pendingDelete')
        .count();
  }

  Future<double> getTotalPending() async {
    final clients = await getAll();
    return clients.fold<double>(0.0, (sum, c) => sum + (c.projectValue - c.amountReceived));
  }

  Future<ClientItem> create({
    required String name,
    String? businessName,
    String? email,
    String? phone,
    String? website,
    String? address,
    String? gstNumber,
    double projectValue = 0,
    bool isRetainer = false,
    double retainerAmount = 0,
    String status = 'Active',
    List<String> socialLinks = const [],
    List<String> deliverables = const [],
    DateTime? deadline,
    String? logoUrl,
    List<String> brandColors = const [],
    String? brandGuidelines,
    List<String> driveLinks = const [],
    String? socialMediaAccess,
    String? meetingNotes,
    String? internalNotes,
  }) async {
    final item = ClientItem()
      ..id = _uuid.v4()
      ..name = name
      ..businessName = businessName
      ..email = email
      ..phone = phone
      ..website = website
      ..address = address
      ..gstNumber = gstNumber
      ..projectValue = projectValue
      ..isRetainer = isRetainer
      ..retainerAmount = retainerAmount
      ..status = status
      ..socialLinks = socialLinks
      ..deliverables = deliverables
      ..deadline = deadline
      ..logoUrl = logoUrl
      ..brandColors = brandColors
      ..brandGuidelines = brandGuidelines
      ..driveLinks = driveLinks
      ..socialMediaAccess = socialMediaAccess
      ..meetingNotes = meetingNotes
      ..internalNotes = internalNotes
      ..workspaceId = _workspaceId
      ..syncStatus = 'pendingCreate'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.clientItems.put(item);
    });
    await WidgetService.syncWidgets();
    return item;
  }

  Future<void> update(ClientItem item) async {
    item.updatedAt = DateTime.now();
    if (item.syncStatus == 'synced') item.syncStatus = 'pendingUpdate';
    await _isar.writeTxn(() async {
      await _isar.clientItems.put(item);
    });
    await WidgetService.syncWidgets();
  }

  Future<void> addPayment(String id, double amount) async {
    final item = await getById(id);
    if (item != null) {
      item.amountReceived += amount;
      await update(item);
    }
  }

  Future<void> delete(String id) async {
    final item = await getById(id);
    if (item != null) {
      item.syncStatus = 'pendingDelete';
      await _isar.writeTxn(() async {
        await _isar.clientItems.put(item);
      });
      await WidgetService.syncWidgets();
    }
  }

  Stream<void> watchAll() => _isar.clientItems.watchLazy();

  Stream<List<ClientItem>> watchAllClients() {
    return _isar.clientItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .sortByName()
        .watch(fireImmediately: true);
  }

  Stream<int> watchActiveCount() {
    return _isar.clientItems
        .filter()
        .statusEqualTo('Active')
        .not().syncStatusEqualTo('pendingDelete')
        .watch(fireImmediately: true)
        .map((clients) => clients.length);
  }

  Stream<double> watchTotalPending() {
    return watchAllClients().map((clients) {
      return clients.fold<double>(0.0, (sum, c) => sum + (c.projectValue - c.amountReceived));
    });
  }

  /// Sum of retainerAmount for all active retainer clients
  Stream<double> watchTotalMrr() {
    return watchAllClients().map((clients) {
      return clients
          .where((c) => c.isRetainer && c.status == 'Active')
          .fold<double>(0.0, (sum, c) => sum + c.retainerAmount);
    });
  }

  /// Count of clients created in the current calendar month
  Stream<int> watchMonthlyNewClients() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _isar.clientItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .createdAtGreaterThan(startOfMonth)
        .watch(fireImmediately: true)
        .map((clients) => clients.length);
  }
}

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final wsId = ref.watch(currentWorkspaceIdProvider);
  return ClientRepository(wsId);
});

final allClientsProvider = StreamProvider<List<ClientItem>>((ref) {
  return ref.watch(clientRepositoryProvider).watchAllClients();
});

final activeClientCountProvider = StreamProvider<int>((ref) {
  return ref.watch(clientRepositoryProvider).watchActiveCount();
});

final pendingPaymentsProvider = StreamProvider<double>((ref) {
  return ref.watch(clientRepositoryProvider).watchTotalPending();
});

final totalMrrProvider = StreamProvider<double>((ref) {
  return ref.watch(clientRepositoryProvider).watchTotalMrr();
});

final monthlyNewClientCountProvider = StreamProvider<int>((ref) {
  return ref.watch(clientRepositoryProvider).watchMonthlyNewClients();
});
