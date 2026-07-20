import 'package:isar/isar.dart';

part 'knowledge_collection.g.dart';

@collection
class KnowledgeItem {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String title;
  late String content;
  late String category; // Hooks, Content Frameworks, Copywriting Formulas, SOPs, etc.
  String? collectionName;
  List<String> tags = [];
  bool isFavorite = false;

  // Sync fields
  late String syncStatus;
  late DateTime createdAt;
  late DateTime updatedAt;
  String? userId;
  String? workspaceId;

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'content': content, 'category': category,
    'collection_name': collectionName, 'tags': tags, 'is_favorite': isFavorite, 'sync_status': syncStatus,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(), 'user_id': userId, 'workspace_id': workspaceId,
  };
}
