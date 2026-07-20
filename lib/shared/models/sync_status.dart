/// Sync status for offline-first entities
enum SyncStatus {
  synced,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
  conflict,
  error,
}

/// Base class for all syncable models
abstract class SyncableModel {
  String get id;
  DateTime get createdAt;
  DateTime get updatedAt;
  SyncStatus get syncStatus;
}
