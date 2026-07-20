import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/context_extensions.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../services/database/repositories/client_repository.dart';
import '../../../../services/database/collections/client_collection.dart';
import '../../../../services/database/repositories/invoice_repository.dart';
import '../../../../services/database/repositories/transaction_repository.dart';

class InvoiceGenerateScreen extends ConsumerStatefulWidget {
  final String? initialClientId;
  const InvoiceGenerateScreen({super.key, this.initialClientId});

  @override
  ConsumerState<InvoiceGenerateScreen> createState() => _InvoiceGenerateScreenState();
}

class _InvoiceGenerateScreenState extends ConsumerState<InvoiceGenerateScreen> {
  final _formKey = GlobalKey<FormState>();

  ClientItem? _selectedClient;
  String _paymentType = 'Remaining Payment';

  final _serviceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _previouslyPaidCtrl = TextEditingController();
  final _gstRateCtrl = TextEditingController(text: '18');
  final _agencyGstCtrl = TextEditingController();
  final _clientGstCtrl = TextEditingController();
  final _clientContactCtrl = TextEditingController();
  String? _qrCodeImagePath;

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;
  bool _isCalculating = false;

  final List<String> _paymentTypes = [
    'Advance Payment',
    'Retainer Payment',
    'Sign Up Payment',
    'Remaining Payment',
    'Full Payment',
  ];

  @override
  void dispose() {
    _serviceCtrl.dispose();
    _durationCtrl.dispose();
    _amountCtrl.dispose();
    _previouslyPaidCtrl.dispose();
    _gstRateCtrl.dispose();
    _agencyGstCtrl.dispose();
    _clientGstCtrl.dispose();
    _clientContactCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickQrCode() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() => _qrCodeImagePath = file.path);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to pick image. Please check permissions.', isError: true);
      }
    }
  }

  void _generate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      context.showSnackBar('Please select a client', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final baseAmount = double.parse(_amountCtrl.text);
      final prevPaid = double.tryParse(_previouslyPaidCtrl.text) ?? 0.0;
      final gstRate = double.tryParse(_gstRateCtrl.text) ?? 0.0;

      final taxAmount = (baseAmount * gstRate) / 100;
      final totalAmount = baseAmount + taxAmount;

      final invoice = await ref.read(invoiceRepositoryProvider).create(
        clientId: _selectedClient!.id,
        clientName: _selectedClient!.businessName ?? _selectedClient!.name,
        clientContactNumber: _clientContactCtrl.text.trim().isEmpty ? null : _clientContactCtrl.text.trim(),
        serviceName: _serviceCtrl.text.trim(),
        duration: _durationCtrl.text.trim(),
        baseAmount: baseAmount,
        agencyGstInfo: _agencyGstCtrl.text.trim().isEmpty ? null : _agencyGstCtrl.text.trim(),
        clientGstInfo: _clientGstCtrl.text.trim().isEmpty ? null : _clientGstCtrl.text.trim(),
        gstRate: gstRate,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        paymentType: _paymentType,
        amountPaidPreviously: prevPaid,
        qrCodeImagePath: _qrCodeImagePath,
        issueDate: DateTime.now(),
        dueDate: _dueDate,
      );

      if (mounted) {
        context.showSuccess('Invoice created successfully');
        context.pushReplacement('/finance/invoices/${invoice.id}/preview', extra: _selectedClient);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate invoice: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePreviouslyPaidAmount() async {
    if (_selectedClient == null) return;
    
    setState(() => _isCalculating = true);
    try {
      double totalPaid = 0.0;
      
      if (_paymentType == 'Advance Payment' || 
          _paymentType == 'Sign Up Payment' || 
          _paymentType == 'Full Payment') {
        // First-time payments: default to 0
        totalPaid = 0.0;
      } else if (_paymentType == 'Retainer Payment') {
        // Retainer: use cycle-based calculation, capped at base amount
        final transactions = await ref.read(transactionRepositoryProvider).getByClientId(_selectedClient!.id);
        final now = DateTime.now();
        final signupDate = _selectedClient!.createdAt;
        
        DateTime cycleStart;
        if (now.day >= signupDate.day) {
          cycleStart = DateTime(now.year, now.month, signupDate.day);
        } else {
          int prevMonth = now.month == 1 ? 12 : now.month - 1;
          int prevYear = now.month == 1 ? now.year - 1 : now.year;
          int day = signupDate.day;
          int daysInPrevMonth = DateTime(prevYear, prevMonth + 1, 0).day;
          if (day > daysInPrevMonth) day = daysInPrevMonth;
          cycleStart = DateTime(prevYear, prevMonth, day);
        }
        
        for (final t in transactions) {
          if (t.type == 'revenue' && t.date.isAfter(cycleStart.subtract(const Duration(seconds: 1)))) {
            totalPaid += t.amount;
          }
        }
      } else {
        // Remaining Payment: use client.amountReceived (what's been paid towards the project)
        totalPaid = _selectedClient!.amountReceived;
      }
      
      // Cap at base amount so remaining balance never goes negative
      final baseAmount = double.tryParse(_amountCtrl.text) ?? 0.0;
      if (baseAmount > 0 && totalPaid > baseAmount) {
        totalPaid = baseAmount;
      }
      
      if (mounted) {
        setState(() {
          _previouslyPaidCtrl.text = totalPaid.toStringAsFixed(0);
        });
      }
    } catch (e) {
      debugPrint('Error calculating previously paid amount: \$e');
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }


  void _onClientOrPaymentTypeChanged() {
    _updatePreviouslyPaidAmount();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(allClientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Invoice'),
      ),
      body: clientsAsync.when(
        data: (clients) {
          if (_selectedClient == null && widget.initialClientId != null) {
            try {
              _selectedClient = clients.firstWhere((c) => c.id == widget.initialClientId);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onClientOrPaymentTypeChanged();
              });
            } catch (_) {}
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<ClientItem>(
                    initialValue: _selectedClient,
                    decoration: const InputDecoration(labelText: 'Select Client'),
                    items: clients.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c.businessName ?? c.name),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() => _selectedClient = v);
                      _onClientOrPaymentTypeChanged();
                    },
                    validator: (v) => v == null ? 'Please select a client' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _clientContactCtrl,
                    decoration: const InputDecoration(labelText: 'Client Contact Number (Optional)'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentType,
                    decoration: const InputDecoration(labelText: 'Payment Type'),
                    items: _paymentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) {
                      setState(() => _paymentType = v!);
                      _onClientOrPaymentTypeChanged();
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _serviceCtrl,
                    decoration: const InputDecoration(labelText: 'Service Name / Description', hintText: 'e.g. Social Media Management'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durationCtrl,
                    decoration: const InputDecoration(labelText: 'Duration', hintText: 'e.g. May 2026'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountCtrl,
                          decoration: const InputDecoration(labelText: 'Base Amount (₹)'),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _gstRateCtrl,
                          decoration: const InputDecoration(labelText: 'GST Rate (%)', hintText: '18'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _agencyGstCtrl,
                          decoration: const InputDecoration(labelText: 'Agency GST (Optional)'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _clientGstCtrl,
                          decoration: const InputDecoration(labelText: 'Client GST (Optional)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _previouslyPaidCtrl,
                    decoration: InputDecoration(
                      labelText: 'Previously Paid Amount (₹)', 
                      hintText: '0',
                      suffixIcon: _isCalculating ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Due Date: ${DateFormat('dd MMM yyyy').format(_dueDate)}'),
                    trailing: const Icon(Icons.calendar_today, size: 20),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => _dueDate = d);
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_qrCodeImagePath != null ? 'QR Code Selected' : 'Upload Payment QR Code'),
                    trailing: Icon(_qrCodeImagePath != null ? Icons.check_circle : Icons.upload_file, color: _qrCodeImagePath != null ? Colors.green : null),
                    onTap: _pickQrCode,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _generate,
                      child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Generate & Preview Invoice'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading clients: $e')),
      ),
    );
  }
}
