import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'collections/task_collection.dart';
import 'collections/content_collection.dart';
import 'collections/knowledge_collection.dart';
import 'collections/lead_collection.dart';
import 'collections/client_collection.dart';
import 'collections/transaction_collection.dart';
import 'collections/resource_collection.dart';
import 'collections/meeting_collection.dart';
import 'collections/journal_collection.dart';
import 'collections/focus_session_collection.dart';
import 'collections/activity_log_collection.dart';
import 'collections/sync_queue_collection.dart';
import 'collections/invoice_collection.dart';
import 'collections/profile_collection.dart';
import 'collections/outreach_collection.dart';
import 'collections/outreach_activity_collection.dart';
import 'collections/template_collection.dart';
import 'collections/campaign_collection.dart';

class IsarService {
  static Isar? _isar;
  static String _currentDbName = '';

  static final _schemas = [
    TaskItemSchema,
    ContentItemSchema,
    KnowledgeItemSchema,
    LeadItemSchema,
    ClientItemSchema,
    TransactionItemSchema,
    ResourceItemSchema,
    MeetingItemSchema,
    JournalEntrySchema,
    FocusSessionSchema,
    ActivityLogItemSchema,
    SyncQueueItemSchema,
    InvoiceItemSchema,
    ProfileItemSchema,
    OutreachItemSchema,
    OutreachActivitySchema,
    TemplateItemSchema,
    CampaignItemSchema,
  ];

  /// Returns the current Isar instance. Throws if not initialized.
  static Isar get instance {
    if (_isar == null || !_isar!.isOpen) {
      throw StateError('IsarService not initialized. Call initialize() first.');
    }
    return _isar!;
  }

  /// The name of the currently open database.
  static String get currentDbName => _currentDbName;

  /// Whether a database is currently open.
  static bool get isOpen => _isar != null && _isar!.isOpen;

  /// Derive a database file name from a workspace ID.
  /// Returns 'guest' for null/empty workspace IDs.
  static String dbNameForWorkspace(String? workspaceId) {
    if (workspaceId == null || workspaceId.isEmpty) return 'guest';
    // Isar DB names can't have hyphens — use underscores
    return 'ws_${workspaceId.replaceAll('-', '_')}';
  }

  /// Initialize (or switch to) a specific database by name.
  static Future<void> initialize(String dbName) async {
    // If already open with the same name, skip
    if (_currentDbName == dbName && _isar != null && _isar!.isOpen) {
      debugPrint('[IsarService] Already open: $dbName');
      return;
    }

    // Close existing DB if open
    if (_isar != null && _isar!.isOpen) {
      debugPrint('[IsarService] Closing: $_currentDbName');
      await _isar!.close();
      _isar = null;
    }

    String dirPath = '';
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      dirPath = dir.path;
    }
    debugPrint('[IsarService] Opening: $dbName at $dirPath');

    _isar = await Isar.open(
      _schemas,
      directory: dirPath,
      name: dbName,
    );
    _currentDbName = dbName;
    debugPrint('[IsarService] Opened: $dbName');
  }

  /// Switch to a different workspace database.
  /// Closes the current DB and opens the new one.
  static Future<void> switchDatabase(String dbName) async {
    await initialize(dbName);
  }

  /// Clear all data in the current database.
  static Future<void> clearAll() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.writeTxn(() async {
        await _isar!.clear();
      });
      debugPrint('[IsarService] Cleared: $_currentDbName');
    }
  }

  /// Close the current database.
  static Future<void> close() async {
    if (_isar != null && _isar!.isOpen) {
      debugPrint('[IsarService] Closing: $_currentDbName');
      await _isar!.close();
      _isar = null;
      _currentDbName = '';
    }
  }
}
