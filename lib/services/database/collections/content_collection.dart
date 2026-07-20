import 'package:isar/isar.dart';

part 'content_collection.g.dart';

@collection
class ContentItem {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String title;
  String? description;
  late String stage; // Raw Thought, Idea, Hook, Script, Recording, Editing, Review, Scheduled, Posted, Repurposed

  List<String> tags = [];
  String? category;
  String? format; // Carousel, Reel, Long Form, Static Post
  String? platform;
  late String priority;
  DateTime? dueDate;
  String? notes;
  List<String> attachmentUrls = [];
  List<String> relatedContentIds = [];

  // Version history
  int version = 1;

  // Sync fields
  late String syncStatus;
  late DateTime createdAt;
  late DateTime updatedAt;
  String? userId;
  String? workspaceId;

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'description': description, 'stage': stage,
    'tags': tags, 'category': category, 'format': format, 'platform': platform, 'priority': priority,
    'due_date': dueDate?.toIso8601String(), 'notes': notes, 'attachment_urls': attachmentUrls,
    'related_content_ids': relatedContentIds, 'version': version, 'sync_status': syncStatus,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(), 'user_id': userId, 'workspace_id': workspaceId,
  };
}
