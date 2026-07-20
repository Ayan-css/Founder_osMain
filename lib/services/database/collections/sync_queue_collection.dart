import 'package:isar/isar.dart';

part 'sync_queue_collection.g.dart';

@collection
class SyncQueueItem {
  Id isarId = Isar.autoIncrement;

  late String collectionName;
  late String recordId;
  late String operation; // create, update, delete
  late String payload; // JSON serialized data
  late DateTime createdAt;
  bool synced = false;
  int retryCount = 0;
  String? errorMessage;
}
