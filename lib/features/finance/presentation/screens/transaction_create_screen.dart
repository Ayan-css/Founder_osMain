import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../services/database/repositories/transaction_repository.dart';
import '../../../../services/database/repositories/client_repository.dart';
import '../../../../services/database/repositories/resource_repository.dart';
import '../../../../services/database/collections/transaction_collection.dart';

class TransactionCreateScreen extends ConsumerStatefulWidget {
  final TransactionItem? editingTransaction;
  const TransactionCreateScreen({super.key, this.editingTransaction});
  @override
  ConsumerState<TransactionCreateScreen> createState() => _TransactionCreateScreenState();
}

class _TransactionCreateScreenState extends ConsumerState<TransactionCreateScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _resourceNameCtrl = TextEditingController();
  String _type = 'revenue';
  String _category = 'Client Payment';
  DateTime _date = DateTime.now();
  String? _clientId;
  String? _clientName;
  String? _resourceType;
  bool _linkToResource = false;
  bool _isSaving = false;

  bool get _isEditing => widget.editingTransaction != null;

  final _revenueCategories = ['Client Payment', 'Retainer', 'Consulting', 'Project', 'Other'];
  final _expenseCategories = AppConstants.expenseCategories;
  final _refundCategories = ['Project Refund', 'Retainer Refund', 'Overpayment', 'Other'];

  List<String> get _categories => _type == 'revenue' ? _revenueCategories : (_type == 'refund' ? _refundCategories : _expenseCategories);

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.editingTransaction!;
      _amountCtrl.text = t.amount.toString();
      _descCtrl.text = t.description ?? '';
      _type = t.type;
      _category = t.category;
      _date = t.date;
      _clientId = t.clientId;
      _clientName = t.clientName;
      if (t.resourceName != null) {
        _linkToResource = true;
        _resourceNameCtrl.text = t.resourceName!;
        _resourceType = t.resourceType;
      }
    } else {
      _category = _revenueCategories.first;
    }
  }

  @override
  void dispose() { _amountCtrl.dispose(); _descCtrl.dispose(); _resourceNameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clients = ref.watch(allClientsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'), actions: [
        FilledButton(onPressed: _isSaving ? null : _save, child: const Text('Save')),
        const SizedBox(width: 12),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Type toggle
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'revenue', label: Text('Revenue'), icon: Icon(Icons.trending_up, size: 18)),
              ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.trending_down, size: 18)),
              ButtonSegment(value: 'refund', label: Text('Refund'), icon: Icon(Icons.assignment_return, size: 18)),
            ],
            selected: {_type},
            onSelectionChanged: (v) => setState(() { _type = v.first; _category = _categories.first; }),
          ),
          const SizedBox(height: 20),
          TextField(controller: _amountCtrl, decoration: const InputDecoration(labelText: 'Amount *', prefixText: '₹ '), keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _categories.contains(_category) ? _category : _categories.first,
            decoration: const InputDecoration(labelText: 'Category'),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 16),
          if (_type == 'revenue' || _type == 'refund')
            clients.when(
              data: (clientList) => DropdownButtonFormField<String>(
                initialValue: _clientId,
                decoration: const InputDecoration(labelText: 'Client (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...clientList.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) {
                  final client = clientList.where((c) => c.id == v).firstOrNull;
                  setState(() { _clientId = v; _clientName = client?.name; });
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox(),
            ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Date: ${_date.day}/${_date.month}/${_date.year}'),
            trailing: const Icon(Icons.calendar_today, size: 20),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) setState(() => _date = d);
            },
          ),
          const SizedBox(height: 16),
          TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),

          // Resource linking for expenses
          if (_type == 'expense') ...[
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Link to Resource', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: const Text('Associate this expense with a resource'),
              value: _linkToResource,
              onChanged: (v) => setState(() => _linkToResource = v),
            ),
            if (_linkToResource) ...[
              const SizedBox(height: 8),
              TextField(controller: _resourceNameCtrl, decoration: const InputDecoration(labelText: 'Resource Name *')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _resourceType,
                decoration: const InputDecoration(labelText: 'Resource Type'),
                items: AppConstants.resourceTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _resourceType = v),
              ),
            ],
          ],
        ]),
      ),
    );
  }

  Future<void> _save() async {
    if (_amountCtrl.text.isEmpty) { context.showSnackBar('Amount required', isError: true); return; }
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) { context.showSnackBar('Invalid amount', isError: true); return; }
    setState(() => _isSaving = true);

    if (_isEditing) {
      final t = widget.editingTransaction!;
      
      // Remove old amount from old client
      if (t.clientId != null) {
        if (t.type == 'revenue') {
          await ref.read(clientRepositoryProvider).addPayment(t.clientId!, -t.amount);
        } else if (t.type == 'refund') {
          await ref.read(clientRepositoryProvider).addPayment(t.clientId!, t.amount); // Revert the refund deduction
        }
      }

      t.type = _type;
      t.amount = amount;
      t.category = _category;
      t.date = _date;
      t.clientId = _clientId;
      t.clientName = _clientName;
      t.description = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
      t.resourceName = _linkToResource ? _resourceNameCtrl.text.trim() : null;
      t.resourceType = _linkToResource ? _resourceType : null;
      await ref.read(transactionRepositoryProvider).update(t);

      // Add new amount to new client
      if (_clientId != null) {
        if (_type == 'revenue') {
          await ref.read(clientRepositoryProvider).addPayment(_clientId!, amount);
        } else if (_type == 'refund') {
          await ref.read(clientRepositoryProvider).addPayment(_clientId!, -amount); // Deduct for refund
        }
      }

    } else {
      final item = await ref.read(transactionRepositoryProvider).create(
        type: _type, amount: amount, category: _category, date: _date,
        clientId: _clientId, clientName: _clientName,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      if (_linkToResource && _resourceNameCtrl.text.trim().isNotEmpty) {
        item.resourceName = _resourceNameCtrl.text.trim();
        item.resourceType = _resourceType;
        await ref.read(transactionRepositoryProvider).update(item);
      }

      // Add payment or deduct refund
      if (_clientId != null) {
        if (_type == 'revenue') {
          await ref.read(clientRepositoryProvider).addPayment(_clientId!, amount);
        } else if (_type == 'refund') {
          await ref.read(clientRepositoryProvider).addPayment(_clientId!, -amount);
        }
      }
    }

    // Auto-create resource record when expense is linked to a resource
    if (_linkToResource && _resourceNameCtrl.text.trim().isNotEmpty) {
      final resourceRepo = ref.read(resourceRepositoryProvider);
      final existingResources = await resourceRepo.getAll();
      final alreadyExists = existingResources.any(
        (r) => r.name.toLowerCase() == _resourceNameCtrl.text.trim().toLowerCase(),
      );
      if (!alreadyExists) {
        await resourceRepo.create(
          name: _resourceNameCtrl.text.trim(),
          type: _resourceType ?? 'Software',
          cost: amount,
          isPurchased: true,
          description: _descCtrl.text.trim().isEmpty ? 'Auto-created from expense' : _descCtrl.text.trim(),
        );
        ref.invalidate(existingResourcesProvider);
        ref.invalidate(allResourcesProvider);
      }
    }

    ref.invalidate(allTransactionsProvider); ref.invalidate(totalRevenueProvider); ref.invalidate(totalExpensesProvider);
    ref.invalidate(totalProfitProvider); ref.invalidate(expensesByCategoryProvider); ref.invalidate(monthlyTrendProvider);
    ref.invalidate(allClientsProvider); ref.invalidate(pendingPaymentsProvider); ref.invalidate(activeClientCountProvider);
    if (mounted) { context.showSuccess(_isEditing ? 'Transaction updated' : 'Transaction added'); context.pop(); }
  }
}
