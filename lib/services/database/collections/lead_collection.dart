import 'package:isar/isar.dart';

part 'lead_collection.g.dart';

@collection
class LeadItem {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String name;
  String? company;
  String? email;
  String? phone;
  String? leadSource;
  String? industry;
  double dealValue = 0;
  late String stage; // New Lead, Contacted, Discovery Call, Proposal Sent, Negotiation, Won, Lost
  String? notes;
  DateTime? followUpDate;
  List<String> meetingHistory = [];

  // Sync fields
  late String syncStatus;
  late DateTime createdAt;
  late DateTime updatedAt;
  String? userId;
  String? workspaceId;

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'company': company, 'email': email, 'phone': phone,
    'lead_source': leadSource, 'industry': industry, 'deal_value': dealValue, 'stage': stage,
    'notes': notes, 'follow_up_date': followUpDate?.toIso8601String(), 'meeting_history': meetingHistory,
    'sync_status': syncStatus, 'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(), 'user_id': userId, 'workspace_id': workspaceId,
  };
}
