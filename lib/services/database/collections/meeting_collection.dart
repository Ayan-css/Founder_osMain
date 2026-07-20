import 'package:isar/isar.dart';

part 'meeting_collection.g.dart';

@collection
class MeetingItem {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String type; // internal, client
  late String title;
  String? agenda;
  List<String> participants = [];
  String? notes;
  List<String> actionItems = [];
  late DateTime date;

  // Client-specific fields
  String? clientId;
  String? clientName;
  String? requirements;
  String? decisions;
  List<String> followUps = [];

  // Attachments
  List<String> attachmentUrls = [];

  // Sync fields
  late String syncStatus;
  late DateTime createdAt;
  late DateTime updatedAt;
  String? userId;
  String? workspaceId;

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type, 'title': title, 'agenda': agenda, 'participants': participants,
    'notes': notes, 'action_items': actionItems, 'date': date.toIso8601String(),
    'client_id': clientId, 'client_name': clientName, 'requirements': requirements,
    'decisions': decisions, 'follow_ups': followUps, 'attachment_urls': attachmentUrls,
    'sync_status': syncStatus, 'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(), 'user_id': userId, 'workspace_id': workspaceId,
  };
}
