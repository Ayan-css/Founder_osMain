import 'package:isar/isar.dart';

part 'activity_log_collection.g.dart';

@collection
class ActivityLogItem {
  ActivityLogItem();

  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String action; // created, updated, deleted
  late String entityType; // tasks, clients, etc.
  String? entityId;
  late DateTime createdAt;

  String? userId;
  String? workspaceId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'workspace_id': workspaceId,
    };
  }

  factory ActivityLogItem.fromJson(Map<String, dynamic> json) {
    return ActivityLogItem()
      ..id = json['id']
      ..action = json['action']
      ..entityType = json['entity_type']
      ..entityId = json['entity_id']
      ..createdAt = DateTime.parse(json['created_at'])
      ..userId = json['user_id']
      ..workspaceId = json['workspace_id'];
  }
}
