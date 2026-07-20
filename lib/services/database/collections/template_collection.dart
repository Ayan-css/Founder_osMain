import 'package:isar/isar.dart';

part 'template_collection.g.dart';

@collection
class TemplateItem {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String name;
  late String platform;
  String? subject;
  late String body;

  // Sync fields
  late String syncStatus;
  late DateTime createdAt;
  late DateTime updatedAt;
  String? userId;
  String? workspaceId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'platform': platform,
    'subject': subject,
    'body': body,
    'sync_status': syncStatus,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'user_id': userId,
    'workspace_id': workspaceId,
  };
}
