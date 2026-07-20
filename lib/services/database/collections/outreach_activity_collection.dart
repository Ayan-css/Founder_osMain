import 'package:isar/isar.dart';

part 'outreach_activity_collection.g.dart';

@collection
class OutreachActivity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  @Index()
  late String outreachItemId;

  late String type; // Email, Call, LinkedIn, Note, etc.
  String? description;
  late DateTime timestamp;

  // Sync fields
  late String syncStatus;
  late DateTime createdAt;
  late DateTime updatedAt;
  String? userId;
  String? workspaceId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'outreach_item_id': outreachItemId,
    'type': type,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'sync_status': syncStatus,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'user_id': userId,
    'workspace_id': workspaceId,
  };
}
