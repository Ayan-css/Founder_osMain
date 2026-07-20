import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../services/settings_service.dart';
import '../../../../core/extensions/context_extensions.dart';

class AgencySettingsScreen extends ConsumerStatefulWidget {
  const AgencySettingsScreen({super.key});

  @override
  ConsumerState<AgencySettingsScreen> createState() => _AgencySettingsScreenState();
}

class _AgencySettingsScreenState extends ConsumerState<AgencySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _gstController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bankAccountNameController;
  late TextEditingController _bankAccountNumberController;
  late TextEditingController _bankIfscController;
  late TextEditingController _bankNameController;
  late TextEditingController _upiIdController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsServiceProvider);
    _nameController = TextEditingController(text: settings.agencyName);
    _addressController = TextEditingController(text: settings.agencyAddress);
    _gstController = TextEditingController(text: settings.agencyGstNumber);
    _emailController = TextEditingController(text: settings.agencyEmail);
    _phoneController = TextEditingController(text: settings.agencyPhone);
    _bankAccountNameController = TextEditingController(text: settings.bankAccountName);
    _bankAccountNumberController = TextEditingController(text: settings.bankAccountNumber);
    _bankIfscController = TextEditingController(text: settings.bankIfscCode);
    _bankNameController = TextEditingController(text: settings.bankName);
    _upiIdController = TextEditingController(text: settings.upiId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bankAccountNameController.dispose();
    _bankAccountNumberController.dispose();
    _bankIfscController.dispose();
    _bankNameController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final settings = ref.read(settingsServiceProvider);
      await settings.setAgencyName(_nameController.text.trim());
      await settings.setAgencyAddress(_addressController.text.trim());
      await settings.setAgencyGstNumber(_gstController.text.trim());
      await settings.setAgencyEmail(_emailController.text.trim());
      await settings.setAgencyPhone(_phoneController.text.trim());
      await settings.setBankAccountName(_bankAccountNameController.text.trim());
      await settings.setBankAccountNumber(_bankAccountNumberController.text.trim());
      await settings.setBankIfscCode(_bankIfscController.text.trim());
      await settings.setBankName(_bankNameController.text.trim());
      await settings.setUpiId(_upiIdController.text.trim());
      if (mounted) {
        context.showSuccess('Agency details saved');
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agency Details'),
        actions: [
          FilledButton(onPressed: _save, child: const Text('Save')),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('These details will appear on generated invoices.', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 24),

              // --- Agency Info ---
              Text('Agency Information', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Agency Name', hintText: 'Right Craft Media'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Agency Address', hintText: '123 Main St...'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gstController,
                decoration: const InputDecoration(labelText: 'GST Number', hintText: '22AAAAA0000A1Z5'),
              ),

              const SizedBox(height: 32),

              // --- Contact Details ---
              Text('Contact Details', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Shown in the invoice header', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', hintText: 'hello@agency.com', prefixIcon: Icon(Icons.email_outlined, size: 20)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', hintText: '+91-9876543210', prefixIcon: Icon(Icons.phone_outlined, size: 20)),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 32),

              // --- Payment / Bank Details ---
              Text('Payment Details', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Shown in the invoice payment section', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankAccountNameController,
                decoration: const InputDecoration(labelText: 'Bank Account Name', hintText: 'John Doe', prefixIcon: Icon(Icons.person_outline, size: 20)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankAccountNumberController,
                decoration: const InputDecoration(labelText: 'Account Number', hintText: '1234567890', prefixIcon: Icon(Icons.account_balance_outlined, size: 20)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankIfscController,
                decoration: const InputDecoration(labelText: 'IFSC Code', hintText: 'SBIN0001234', prefixIcon: Icon(Icons.code, size: 20)),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(labelText: 'Bank Name', hintText: 'State Bank of India', prefixIcon: Icon(Icons.account_balance, size: 20)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _upiIdController,
                decoration: const InputDecoration(labelText: 'UPI ID', hintText: 'name@upi', prefixIcon: Icon(Icons.qr_code, size: 20)),
              ),

              const SizedBox(height: 32),

              // QR Code
              Text('Payment QR Code', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, _) {
                  final settings = ref.watch(settingsServiceProvider);
                  return Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                      image: settings.paymentQrCodePath.isNotEmpty
                          ? DecorationImage(
                              image: FileImage(File(settings.paymentQrCodePath)),
                              fit: BoxFit.contain,
                            )
                          : null,
                    ),
                    child: settings.paymentQrCodePath.isNotEmpty
                        ? Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await settings.setPaymentQrCodePath('');
                              },
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.qr_code_2, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                                    if (pickedFile != null) {
                                      await settings.setPaymentQrCodePath(pickedFile.path);
                                      context.showSuccess('QR code uploaded');
                                    }
                                  },
                                  icon: const Icon(Icons.upload),
                                  label: const Text('Upload QR Image'),
                                ),
                              ],
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
