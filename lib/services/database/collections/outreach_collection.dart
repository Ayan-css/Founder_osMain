import 'package:isar/isar.dart';

part 'outreach_collection.g.dart';

@collection
class OutreachItem {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String name; // Prospect name
  String? company;

  /// Platform: LinkedIn, Email, Instagram, WhatsApp, Cold Call, Other
  late String platform;

  /// Status: Not Replied, Replied, Meeting Booked, Converted, Not Interested
  late String status;

  String? contactDetail;
  String? notes;
  DateTime? followUpDate;

  String? campaignId;
  String priority = 'Medium'; // High, Medium, Low

  // Sync fields
  late String syncStatus;
  late DateTime createdAt;
  late DateTime updatedAt;
  String? userId;
  String? workspaceId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'company': company,
    'platform': platform,
    'status': status,
    'contact_detail': contactDetail,
    'notes': notes,
    'follow_up_date': followUpDate?.toIso8601String(),
    'sync_status': syncStatus,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'user_id': userId,
    'workspace_id': workspaceId,
    'campaign_id': campaignId,
    'priority': priority,
  };
}
