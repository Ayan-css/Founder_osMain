import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../isar_service.dart';
import '../collections/transaction_collection.dart';
import '../../workspace_service.dart';
import '../../widget_service.dart';

class TransactionRepository {
  final Isar _isar = IsarService.instance;
  final _uuid = const Uuid();
  final String? _workspaceId;

  TransactionRepository(this._workspaceId);

  Future<List<TransactionItem>> getAll() async {
    return _isar.transactionItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .sortByDateDesc()
        .findAll();
  }

  Future<List<TransactionItem>> getByType(String type) async {
    return _isar.transactionItems
        .filter()
        .typeEqualTo(type)
        .not().syncStatusEqualTo('pendingDelete')
        .sortByDateDesc()
        .findAll();
  }

  Future<List<TransactionItem>> getByDateRange(DateTime start, DateTime end) async {
    return _isar.transactionItems
        .filter()
        .dateBetween(start, end)
        .not().syncStatusEqualTo('pendingDelete')
        .sortByDateDesc()
        .findAll();
  }

  Future<double> getTotalRevenue() async {
    final revenueItems = await getByType('revenue');
    final refundItems = await getByType('refund');
    final rev = revenueItems.fold<double>(0.0, (sum, t) => sum + t.amount);
    final ref = refundItems.fold<double>(0.0, (sum, t) => sum + t.amount);
    return rev - ref;
  }

  Future<double> getTotalExpenses() async {
    final items = await getByType('expense');
    return items.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  Future<double> getProfit() async {
    final revenue = await getTotalRevenue();
    final expenses = await getTotalExpenses();
    return revenue - expenses;
  }

  Future<double> getMonthlyRevenue(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final revenueItems = await _isar.transactionItems
        .filter()
        .typeEqualTo('revenue')
        .dateBetween(start, end)
        .not().syncStatusEqualTo('pendingDelete')
        .findAll();
    final refundItems = await _isar.transactionItems
        .filter()
        .typeEqualTo('refund')
        .dateBetween(start, end)
        .not().syncStatusEqualTo('pendingDelete')
        .findAll();
    final rev = revenueItems.fold<double>(0.0, (sum, t) => sum + t.amount);
    final ref = refundItems.fold<double>(0.0, (sum, t) => sum + t.amount);
    return rev - ref;
  }

  Future<double> getMonthlyExpenses(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final items = await _isar.transactionItems
        .filter()
        .typeEqualTo('expense')
        .dateBetween(start, end)
        .not().syncStatusEqualTo('pendingDelete')
        .findAll();
    return items.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  Future<Map<String, double>> getExpensesByCategory() async {
    final expenses = await getByType('expense');
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  Future<List<Map<String, double>>> getMonthlyTrend(int months) async {
    final now = DateTime.now();
    final results = <Map<String, double>>[];
    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final revenue = await getMonthlyRevenue(date.year, date.month);
      final expenses = await getMonthlyExpenses(date.year, date.month);
      results.add({
        'revenue': revenue,
        'expenses': expenses,
        'profit': revenue - expenses,
      });
    }
    return results;
  }

  Future<List<TransactionItem>> getByClientId(String clientId) async {
    return _isar.transactionItems
        .filter()
        .clientIdEqualTo(clientId)
        .not().syncStatusEqualTo('pendingDelete')
        .sortByDateDesc()
        .findAll();
  }

  Future<TransactionItem?> getById(String id) async {
    return _isar.transactionItems.filter().idEqualTo(id).findFirst();
  }

  Future<TransactionItem> create({
    required String type,
    required double amount,
    required String category,
    required DateTime date,
    String? clientId,
    String? clientName,
    String? description,
  }) async {
    final item = TransactionItem()
      ..id = _uuid.v4()
      ..type = type
      ..amount = amount
      ..category = category
      ..date = date
      ..clientId = clientId
      ..clientName = clientName
      ..description = description
      ..workspaceId = _workspaceId
      ..syncStatus = 'pendingCreate'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.transactionItems.put(item);
    });
    await WidgetService.syncWidgets();
    return item;
  }

  Future<void> update(TransactionItem item) async {
    item.updatedAt = DateTime.now();
    if (item.syncStatus == 'synced') item.syncStatus = 'pendingUpdate';
    await _isar.writeTxn(() async {
      await _isar.transactionItems.put(item);
    });
    await WidgetService.syncWidgets();
  }

  Future<void> delete(String id) async {
    final item = await _isar.transactionItems.filter().idEqualTo(id).findFirst();
    if (item != null) {
      item.syncStatus = 'pendingDelete';
      await _isar.writeTxn(() async {
        await _isar.transactionItems.put(item);
      });
    }
  }

  Stream<void> watchAll() => _isar.transactionItems.watchLazy();

  Stream<List<TransactionItem>> watchAllTransactions() {
    return _isar.transactionItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final wsId = ref.watch(currentWorkspaceIdProvider);
  return TransactionRepository(wsId);
});

final allTransactionsProvider = StreamProvider<List<TransactionItem>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAllTransactions();
});

final totalRevenueProvider = StreamProvider<double>((ref) async* {
  await for (final transactions in ref.watch(transactionRepositoryProvider).watchAllTransactions()) {
    final rev = transactions.where((t) => t.type == 'revenue').fold<double>(0.0, (s, t) => s + t.amount);
    final refItems = transactions.where((t) => t.type == 'refund').fold<double>(0.0, (s, t) => s + t.amount);
    yield rev - refItems;
  }
});

final totalExpensesProvider = StreamProvider<double>((ref) async* {
  await for (final transactions in ref.watch(transactionRepositoryProvider).watchAllTransactions()) {
    yield transactions.where((t) => t.type == 'expense').fold<double>(0.0, (s, t) => s + t.amount);
  }
});

final totalProfitProvider = StreamProvider<double>((ref) async* {
  await for (final transactions in ref.watch(transactionRepositoryProvider).watchAllTransactions()) {
    final rev = transactions.where((t) => t.type == 'revenue').fold<double>(0.0, (s, t) => s + t.amount);
    final refItems = transactions.where((t) => t.type == 'refund').fold<double>(0.0, (s, t) => s + t.amount);
    final exp = transactions.where((t) => t.type == 'expense').fold<double>(0.0, (s, t) => s + t.amount);
    yield (rev - refItems) - exp;
  }
});

final expensesByCategoryProvider = FutureProvider<Map<String, double>>((ref) async {
  return ref.watch(transactionRepositoryProvider).getExpensesByCategory();
});

final monthlyTrendProvider = FutureProvider<List<Map<String, double>>>((ref) async {
  return ref.watch(transactionRepositoryProvider).getMonthlyTrend(6);
});
