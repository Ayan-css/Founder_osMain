import 'package:isar/isar.dart';

part 'task_collection.g.dart';

@collection
class TaskItem {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String title;
  String? description;
  late String priority; // Critical, High, Medium, Low
  DateTime? dueDate;
  bool isCompleted = false;
  bool isPinned = false;
  int sortOrder = 0;

  // Sync fields
  late String syncStatus; // synced, pendingCreate, pendingUpdate, pendingDelete
  late DateTime createdAt;
  late DateTime updatedAt;
  String? userId;
  String? workspaceId;

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'description': description, 'priority': priority,
    'due_date': dueDate?.toIso8601String(), 'is_completed': isCompleted, 'is_pinned': isPinned,
    'sort_order': sortOrder, 'sync_status': syncStatus,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(), 'user_id': userId, 'workspace_id': workspaceId,
  };
}
