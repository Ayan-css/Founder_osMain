import 'package:isar/isar.dart';

part 'journal_collection.g.dart';

@collection
class JournalEntry {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  @Index()
  late DateTime date;

  String? wentWell;
  String? didNotGoWell;
  String? lessonsLearned;
  String? wins;
  String? mistakes;
  String? gratitude;
  String? improvementsForTomorrow;

  // Mood tracking (1-5 scale)
  int mood = 3;

  // Sync fields
  late String syncStatus;
  late DateTime createdAt;
  late DateTime updatedAt;
  String? userId;
  String? workspaceId;

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String(), 'went_well': wentWell, 'did_not_go_well': didNotGoWell,
    'lessons_learned': lessonsLearned, 'wins': wins, 'mistakes': mistakes, 'gratitude': gratitude,
    'improvements_for_tomorrow': improvementsForTomorrow, 'mood': mood, 'sync_status': syncStatus,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(), 'user_id': userId, 'workspace_id': workspaceId,
  };
}
