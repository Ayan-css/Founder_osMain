import 'package:isar/isar.dart';

part 'profile_collection.g.dart';

@collection
class ProfileItem {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  String? fullName;
  String? businessName;
  String? email;
  String? avatarUrl;
  
  String? themeId;
  String? themeMode;

  late DateTime createdAt;
  late DateTime updatedAt;

  // Sync tracking
  late String syncStatus; // synced, pendingUpdate

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'business_name': businessName,
      'email': email,
      'avatar_url': avatarUrl,
      'theme_id': themeId,
      'theme_mode': themeMode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
