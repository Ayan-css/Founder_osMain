import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../isar_service.dart';
import '../collections/invoice_collection.dart';
import '../../workspace_service.dart';

class InvoiceRepository {
  final Isar _isar = IsarService.instance;
  final _uuid = const Uuid();
  final String? _workspaceId;

  InvoiceRepository(this._workspaceId);

  Future<List<InvoiceItem>> getAll() async {
    return _isar.invoiceItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<List<InvoiceItem>> getByClient(String clientId) async {
    return _isar.invoiceItems
        .filter()
        .clientIdEqualTo(clientId)
        .not().syncStatusEqualTo('pendingDelete')
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<InvoiceItem?> getById(String id) async {
    return _isar.invoiceItems.filter().idEqualTo(id).findFirst();
  }

  Future<InvoiceItem> create({
    required String clientId,
    required String clientName,
    String? clientContactNumber,
    required String serviceName,
    required String duration,
    required double baseAmount,
    String? agencyGstInfo,
    String? clientGstInfo,
    required double gstRate,
    required double taxAmount,
    required double totalAmount,
    required String paymentType,
    required double amountPaidPreviously,
    required DateTime issueDate,
    required DateTime dueDate,
    String status = 'Draft',
    String? pdfFilePath,
    String? qrCodeImagePath,
  }) async {
    final item = InvoiceItem()
      ..id = _uuid.v4()
      ..clientId = clientId
      ..clientName = clientName
      ..clientContactNumber = clientContactNumber
      ..serviceName = serviceName
      ..duration = duration
      ..baseAmount = baseAmount
      ..agencyGstInfo = agencyGstInfo
      ..clientGstInfo = clientGstInfo
      ..gstRate = gstRate
      ..taxAmount = taxAmount
      ..totalAmount = totalAmount
      ..paymentType = paymentType
      ..amountPaidPreviously = amountPaidPreviously
      ..issueDate = issueDate
      ..dueDate = dueDate
      ..status = status
      ..pdfFilePath = pdfFilePath
      ..qrCodeImagePath = qrCodeImagePath
      ..workspaceId = _workspaceId
      ..syncStatus = 'pendingCreate'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.invoiceItems.put(item);
    });
    return item;
  }

  Future<void> update(InvoiceItem item) async {
    item.updatedAt = DateTime.now();
    if (item.syncStatus == 'synced') {
      item.syncStatus = 'pendingUpdate';
    }
    await _isar.writeTxn(() async {
      await _isar.invoiceItems.put(item);
    });
  }

  Future<void> delete(String id) async {
    final item = await getById(id);
    if (item != null) {
      item.syncStatus = 'pendingDelete';
      item.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.invoiceItems.put(item);
      });
    }
  }

  Stream<void> watchAll() {
    return _isar.invoiceItems.watchLazy();
  }
}

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final wsId = ref.watch(currentWorkspaceIdProvider);
  return InvoiceRepository(wsId);
});

final allInvoicesProvider = FutureProvider<List<InvoiceItem>>((ref) async {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getAll();
});
