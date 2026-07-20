import 'package:isar/isar.dart';

part 'focus_session_collection.g.dart';

@collection
class FocusSession {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String type; // pomodoro, deepWork, custom
  late int durationMinutes;
  late DateTime startTime;
  DateTime? endTime;
  bool completed = false;
  String? label;

  // Sync fields
  late String syncStatus;
  late DateTime createdAt;
  late DateTime updatedAt;
  String? userId;
  String? workspaceId;

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type, 'duration_minutes': durationMinutes,
    'start_time': startTime.toIso8601String(), 'end_time': endTime?.toIso8601String(),
    'completed': completed, 'label': label, 'sync_status': syncStatus,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(), 'user_id': userId, 'workspace_id': workspaceId,
  };
}
