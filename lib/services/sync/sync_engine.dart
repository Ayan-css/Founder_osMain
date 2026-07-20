import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:convert';
import '../database/isar_service.dart';
import '../workspace_service.dart';
import 'sync_mapper.dart';

import '../database/collections/task_collection.dart';
import '../database/collections/content_collection.dart';
import '../database/collections/lead_collection.dart';
import '../database/collections/client_collection.dart';
import '../database/collections/transaction_collection.dart';
import '../database/collections/knowledge_collection.dart';
import '../database/collections/meeting_collection.dart';
import '../database/collections/journal_collection.dart';
import '../database/collections/focus_session_collection.dart';
import '../database/collections/resource_collection.dart';
import '../database/collections/invoice_collection.dart';
import '../database/collections/sync_queue_collection.dart';
import '../database/collections/outreach_collection.dart';
import '../database/collections/outreach_activity_collection.dart';
import '../database/collections/template_collection.dart';
import '../database/collections/campaign_collection.dart';
class SyncEngine {
  final Isar _isar = IsarService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final WorkspaceService _workspaceService;

  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  SyncEngine(this._workspaceService);

  DateTime? get lastSyncTime => _lastSyncTime;

  void startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => syncAll(),
    );
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<SyncResult> syncAll() async {
    if (_isSyncing) return SyncResult(synced: 0, failed: 0, skipped: 0);
    if (_supabase.auth.currentUser == null) return SyncResult(synced: 0, failed: 0, skipped: 0);
    
    final workspaceId = _workspaceService.currentWorkspaceId;
    if (workspaceId == null) return SyncResult(synced: 0, failed: 0, skipped: 0);

    _isSyncing = true;
    int synced = 0;
    int failed = 0;

    try {
      // 1. Pull Sync first (to fetch changes from other team members)
      await _pullSync(workspaceId);

      // 2. Push Sync
      synced += await _pushCollection<TaskItem>(_isar.taskItems, 'tasks', (item) => item.syncStatus, (item, s) => item.syncStatus = s, (item) => item.toJson(), workspaceId);
      synced += await _pushCollection<ContentItem>(_isar.contentItems, 'content', (item) => item.syncStatus, (item, s) => item.syncStatus = s, (item) => item.toJson(), workspaceId);
      synced += await _pushCollection<LeadItem>(_isar.leadItems, 'leads', (item) => item.syncStatus, (item, s) => item.syncStatus = s, (item) => item.toJson(), workspaceId);
      synced += await _pushCollection<ClientItem>(_isar.clientItems, 'clients', (item) => item.syncStatus, (item, s) => item.syncStatus = s, (item) => item.toJson(), workspaceId);
      synced += await _pushCollection<TransactionItem>(_isar.transactionItems, 'transactions', (item) => item.syncStatus, (item, s) => item.syncStatus = s, (item) => item.toJson(), workspaceId);
      synced += await _pushCollection<KnowledgeItem>(_isar.knowledgeItems, 'knowledge', (item) => item.syncStatus, (item, s) => item.syncStatus = s, (item) => item.toJson(), workspaceId);
      synced += await _pushCollection<MeetingItem>(_isar.meetingItems, 'meetings', (item) => item.syncStatus, (item, s) => item.syncStatus = s, (item) => item.toJson(), workspaceId);
      synced += await _pushCollection<JournalEntry>(_isar.journalEntrys, 'journal_entries', (item) => item.syncStatus, (item, s) => item.syncStatus = s, (item) => item.toJson(), workspaceId);
      synced += await _pushCollection<FocusSession>(_isar.focusSessions, 'focus_sessions', (item) => item.syncStatus, (item, s) => item.syncStatus = s, (item) => item.toJson(), workspaceId);
      synced += await _pushCollection<ResourceItem>(_isar.resourceItems, 'resources', (item) => item.syncStatus, (item, s) => item.syncStatus = s, (item) => item.toJson(), workspaceId);
      synced += await _pushCollection<InvoiceItem>(_isar.invoiceItems, 'invoices', (item) => item.syncStatus, (item, s) => item.syncStatus = s, (item) => item.toJson(), workspaceId);
      synced += await _pushCollection<OutreachItem>(_isar.outreachItems, 'cold_outreach', (item) => item.syncStatus, (item, s) => item.syncStatus = s, (item) => item.toJson(), workspaceId);
      synced += await _pushCollection<OutreachActivity>(_isar.outreachActivitys, 'outreach_activities', (item) => item.syncStatus, (item, s) => item.syncStatus = s, (item) => item.toJson(), workspaceId);
      synced += await _pushCollection<TemplateItem>(_isar.templateItems, 'templates', (item) => item.syncStatus, (item, s) => item.syncStatus = s, (item) => item.toJson(), workspaceId);
      synced += await _pushCollection<CampaignItem>(_isar.campaignItems, 'campaigns', (item) => item.syncStatus, (item, s) => item.syncStatus = s, (item) => item.toJson(), workspaceId);

      if (synced > 0) _lastSyncTime = DateTime.now();
    } catch (e) {
      failed++;
    } finally {
      _isSyncing = false;
    }

    return SyncResult(synced: synced, failed: failed, skipped: 0);
  }

  Future<void> _pullSync(String workspaceId) async {
    // Pulls all data from Supabase for this workspace and overwrites local data that isn't pending.
    // In a production app, we would use an 'updated_at' cursor. For now we just fetch everything for the workspace.
    
    // Since Isar id filters require strong typing or dynamic workarounds, we use dynamic idEqualTo
    // but the generated query builder requires strong typing.
    // Instead of complex generics, we can just fetch all local items and map them by UUID.
    
    Future<void> pullCollectionSimple<T>(String table, IsarCollection<T> localCollection, T Function(Map<String, dynamic>) fromJson) async {
      try {
        final response = await _supabase.from(table).select().eq('workspace_id', workspaceId);
        final List<T> remoteItems = (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
        
        await _isar.writeTxn(() async {
          final allLocal = await localCollection.where().findAll();
          final localMap = {for (var e in allLocal) (e as dynamic).id: e};

          for (final item in remoteItems) {
            final String remoteId = (item as dynamic).id;
            final localItem = localMap[remoteId];

            if (localItem == null) {
              await localCollection.put(item);
            } else {
              final status = (localItem as dynamic).syncStatus;
              if (status != 'pendingCreate' && status != 'pendingUpdate' && status != 'pendingDelete') {
                (item as dynamic).isarId = (localItem as dynamic).isarId;
                await localCollection.put(item);
              }
            }
          }
        });
      } catch (e) {
        // Ignored
      }
    }

    await pullCollectionSimple('tasks', _isar.taskItems, SyncMapper.taskFromJson);
    await pullCollectionSimple('content', _isar.contentItems, SyncMapper.contentFromJson);
    await pullCollectionSimple('leads', _isar.leadItems, SyncMapper.leadFromJson);
    await pullCollectionSimple('clients', _isar.clientItems, SyncMapper.clientFromJson);
    await pullCollectionSimple('transactions', _isar.transactionItems, SyncMapper.transactionFromJson);
    await pullCollectionSimple('knowledge', _isar.knowledgeItems, SyncMapper.knowledgeFromJson);
    await pullCollectionSimple('meetings', _isar.meetingItems, SyncMapper.meetingFromJson);
    await pullCollectionSimple('journal_entries', _isar.journalEntrys, SyncMapper.journalFromJson);
    await pullCollectionSimple('focus_sessions', _isar.focusSessions, SyncMapper.focusSessionFromJson);
    await pullCollectionSimple('resources', _isar.resourceItems, SyncMapper.resourceFromJson);
    await pullCollectionSimple('invoices', _isar.invoiceItems, SyncMapper.invoiceFromJson);
    await pullCollectionSimple('cold_outreach', _isar.outreachItems, SyncMapper.outreachFromJson);
    await pullCollectionSimple('outreach_activities', _isar.outreachActivitys, SyncMapper.outreachActivityFromJson);
    await pullCollectionSimple('templates', _isar.templateItems, SyncMapper.templateFromJson);
    await pullCollectionSimple('campaigns', _isar.campaignItems, SyncMapper.campaignFromJson);
  }

  Future<int> _pushCollection<T>(
    IsarCollection<T> collection,
    String tableName,
    String Function(T) getSyncStatus,
    void Function(T, String) setSyncStatus,
    Map<String, dynamic> Function(T) toJson,
    String workspaceId,
  ) async {
    int synced = 0;
    try {
      final allItems = await collection.where().findAll();
      
      // Load current sync errors for this collection to apply backoff
      final queueErrors = await _isar.syncQueueItems.filter().collectionNameEqualTo(tableName).findAll();
      final errorMap = {for (var err in queueErrors) err.recordId: err};
      
      final pendingItems = allItems.where((item) {
        final status = getSyncStatus(item);
        if (status != 'pendingCreate' && status != 'pendingUpdate' && status != 'pendingDelete') return false;
        
        // Exponential backoff check
        final data = toJson(item);
        final err = errorMap[data['id']];
        if (err != null) {
          final now = DateTime.now();
          final backoffMinutes = 1 << (err.retryCount - 1).clamp(0, 8); // 1, 2, 4, 8, 16... max 256 mins
          if (now.difference(err.createdAt).inMinutes < backoffMinutes) {
            return false; // Skip this item for now
          }
        }
        return true;
      }).toList();

      final userId = _supabase.auth.currentUser?.id;

      for (final item in pendingItems) {
        String status = getSyncStatus(item);
        Map<String, dynamic> data = toJson(item);
        try {
          if (userId != null) data['user_id'] = userId;
          data['workspace_id'] = workspaceId; // Always force workspace_id

          if (status == 'pendingCreate') {
            await _supabase.from(tableName).insert(data);
          } else if (status == 'pendingUpdate') {
            await _supabase.from(tableName).update(data).eq('id', data['id']);
          } else if (status == 'pendingDelete') {
            await _supabase.from(tableName).delete().eq('id', data['id']);
          }

          if (status == 'pendingDelete') {
            await _isar.writeTxn(() async {
              // Delete by internal Isar ID to be safe
              await collection.delete((item as dynamic).isarId);
            });
          } else {
            setSyncStatus(item, 'synced');
            await _isar.writeTxn(() async {
              await collection.put(item);
              
              // Clear any queue errors for this record
              final oldErrors = await _isar.syncQueueItems.filter().recordIdEqualTo(data['id']).findAll();
              for (var err in oldErrors) {
                await _isar.syncQueueItems.delete(err.isarId);
              }
            });
          }
          synced++;
        } catch (e) {
          // Failure for single item - log to queue
          await _isar.writeTxn(() async {
            final existing = await _isar.syncQueueItems.filter().recordIdEqualTo(data['id']).findFirst();
            if (existing != null) {
              existing.retryCount += 1;
              existing.errorMessage = e.toString();
              existing.createdAt = DateTime.now(); // update time for exponential backoff
              await _isar.syncQueueItems.put(existing);
            } else {
              final queueItem = SyncQueueItem()
                ..collectionName = tableName
                ..recordId = data['id']
                ..operation = status
                ..payload = jsonEncode(data)
                ..createdAt = DateTime.now()
                ..errorMessage = e.toString()
                ..retryCount = 1;
              await _isar.syncQueueItems.put(queueItem);
            }
          });
        }
      }
    } catch (e) {
      // Failure for whole collection
    }
    return synced;
  }

  Future<int> getPendingSyncCount() async {
    int count = 0;
    count += await _isar.taskItems.filter().syncStatusStartsWith('pending').count();
    count += await _isar.contentItems.filter().syncStatusStartsWith('pending').count();
    count += await _isar.leadItems.filter().syncStatusStartsWith('pending').count();
    count += await _isar.clientItems.filter().syncStatusStartsWith('pending').count();
    count += await _isar.transactionItems.filter().syncStatusStartsWith('pending').count();
    count += await _isar.knowledgeItems.filter().syncStatusStartsWith('pending').count();
    count += await _isar.meetingItems.filter().syncStatusStartsWith('pending').count();
    count += await _isar.journalEntrys.filter().syncStatusStartsWith('pending').count();
    count += await _isar.focusSessions.filter().syncStatusStartsWith('pending').count();
    count += await _isar.resourceItems.filter().syncStatusStartsWith('pending').count();
    count += await _isar.invoiceItems.filter().syncStatusStartsWith('pending').count();
    count += await _isar.outreachItems.filter().syncStatusStartsWith('pending').count();
    count += await _isar.outreachActivitys.filter().syncStatusStartsWith('pending').count();
    count += await _isar.templateItems.filter().syncStatusStartsWith('pending').count();
    count += await _isar.campaignItems.filter().syncStatusStartsWith('pending').count();
    return count;
  }
}

class SyncResult {
  final int synced;
  final int failed;
  final int skipped;
  SyncResult({required this.synced, required this.failed, required this.skipped});
}

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final ws = ref.watch(workspaceServiceProvider);
  return SyncEngine(ws);
});

final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(syncEngineProvider).getPendingSyncCount();
});
