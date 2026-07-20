import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'workspace_service.dart';

class SettingsService {
  final SharedPreferences _prefs;
  final String? _workspaceId;

  SettingsService(this._prefs, this._workspaceId);

  /// Prefix keys with workspace ID so settings are isolated per workspace.
  /// Falls back to plain key for guest mode.
  String _key(String base) =>
      _workspaceId != null ? 'ws_${_workspaceId}_$base' : base;

  static const String _kAgencyName = 'agency_name';
  static const String _kAgencyAddress = 'agency_address';
  static const String _kAgencyGstNumber = 'agency_gst_number';
  static const String _kPaymentQrCodePath = 'payment_qr_code_path';
  static const String _kAgencyEmail = 'agency_email';
  static const String _kAgencyPhone = 'agency_phone';
  static const String _kBankAccountName = 'bank_account_name';
  static const String _kBankAccountNumber = 'bank_account_number';
  static const String _kBankIfscCode = 'bank_ifsc_code';
  static const String _kBankName = 'bank_name';
  static const String _kUpiId = 'upi_id';
  static const String _kMonthlyClientTarget = 'monthly_client_target';
  static const String _kMonthlyMrrTarget = 'monthly_mrr_target';
  static const String _kMonthlyOutreachTarget = 'monthly_outreach_target';

  String get agencyName => _prefs.getString(_key(_kAgencyName)) ?? '';
  String get agencyAddress => _prefs.getString(_key(_kAgencyAddress)) ?? '';
  String get agencyGstNumber => _prefs.getString(_key(_kAgencyGstNumber)) ?? '';
  String get paymentQrCodePath => _prefs.getString(_key(_kPaymentQrCodePath)) ?? '';
  String get agencyEmail => _prefs.getString(_key(_kAgencyEmail)) ?? '';
  String get agencyPhone => _prefs.getString(_key(_kAgencyPhone)) ?? '';
  String get bankAccountName => _prefs.getString(_key(_kBankAccountName)) ?? '';
  String get bankAccountNumber => _prefs.getString(_key(_kBankAccountNumber)) ?? '';
  String get bankIfscCode => _prefs.getString(_key(_kBankIfscCode)) ?? '';
  String get bankName => _prefs.getString(_key(_kBankName)) ?? '';
  String get upiId => _prefs.getString(_key(_kUpiId)) ?? '';
  int get monthlyClientTarget => _prefs.getInt(_key(_kMonthlyClientTarget)) ?? 5;
  int get monthlyMrrTarget => _prefs.getInt(_key(_kMonthlyMrrTarget)) ?? 100000;
  int get monthlyOutreachTarget => _prefs.getInt(_key(_kMonthlyOutreachTarget)) ?? 30;

  Future<void> setAgencyName(String value) async {
    await _prefs.setString(_key(_kAgencyName), value);
  }

  Future<void> setAgencyAddress(String value) async {
    await _prefs.setString(_key(_kAgencyAddress), value);
  }

  Future<void> setAgencyGstNumber(String value) async {
    await _prefs.setString(_key(_kAgencyGstNumber), value);
  }

  Future<void> setAgencyEmail(String value) async {
    await _prefs.setString(_key(_kAgencyEmail), value);
  }

  Future<void> setAgencyPhone(String value) async {
    await _prefs.setString(_key(_kAgencyPhone), value);
  }

  Future<void> setBankAccountName(String value) async {
    await _prefs.setString(_key(_kBankAccountName), value);
  }

  Future<void> setBankAccountNumber(String value) async {
    await _prefs.setString(_key(_kBankAccountNumber), value);
  }

  Future<void> setBankIfscCode(String value) async {
    await _prefs.setString(_key(_kBankIfscCode), value);
  }

  Future<void> setBankName(String value) async {
    await _prefs.setString(_key(_kBankName), value);
  }

  Future<void> setUpiId(String value) async {
    await _prefs.setString(_key(_kUpiId), value);
  }

  Future<void> setMonthlyClientTarget(int value) async {
    await _prefs.setInt(_key(_kMonthlyClientTarget), value);
  }

  Future<void> setMonthlyMrrTarget(int value) async {
    await _prefs.setInt(_key(_kMonthlyMrrTarget), value);
  }

  Future<void> setMonthlyOutreachTarget(int value) async {
    await _prefs.setInt(_key(_kMonthlyOutreachTarget), value);
  }

  Future<void> setPaymentQrCodePath(String value) async {
    await _prefs.setString(_key(_kPaymentQrCodePath), value);

    // Upload to Supabase if authenticated and a file was selected
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && value.isNotEmpty) {
        final file = File(value);
        if (await file.exists()) {
          final userId = session.user.id;
          final fileName = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
          final path = '$userId/$fileName';

          await Supabase.instance.client.storage
              .from('agency_assets')
              .upload(path, file, fileOptions: const FileOptions(upsert: true));
        }
      }
    } catch (e) {
      // Ignore errors — local saving is primary
      debugPrint('Failed to upload QR code to Supabase: $e');
    }
  }
}

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final wsId = ref.watch(currentWorkspaceIdProvider);
  return SettingsService(prefs, wsId);
});
