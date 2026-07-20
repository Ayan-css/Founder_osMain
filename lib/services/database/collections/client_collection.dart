import 'package:isar/isar.dart';

part 'client_collection.g.dart';

@collection
class ClientItem {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  // Basic Information
  late String name;
  String? businessName;
  String? email;
  String? phone;
  String? website;
  String? address;
  String? gstNumber;
  List<String> socialLinks = [];

  // Financial Information
  bool isRetainer = false;
  double retainerAmount = 0; // Monthly Recurring Revenue
  double projectValue = 0; // Lifetime Value or Fixed Project Value
  double amountReceived = 0;

  // Project Information
  List<String> deliverables = [];
  DateTime? deadline;
  String status = 'Active'; // Active, Completed, On Hold, Cancelled

  // Brand Assets
  String? logoUrl;
  List<String> brandColors = [];
  String? brandGuidelines;

  // Resources
  List<String> driveLinks = [];
  String? socialMediaAccess;

  // Notes
  String? meetingNotes;
  String? internalNotes;

  // Sync fields
  late String syncStatus;
  late DateTime createdAt;
  late DateTime updatedAt;
  String? userId;
  String? workspaceId;

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'business_name': businessName, 'email': email, 'phone': phone,
    'website': website, 'address': address, 'gst_number': gstNumber, 'social_links': socialLinks, 'is_retainer': isRetainer, 'retainer_amount': retainerAmount, 'project_value': projectValue,
    'amount_received': amountReceived, 'deliverables': deliverables, 'deadline': deadline?.toIso8601String(),
    'status': status, 'logo_url': logoUrl, 'brand_colors': brandColors, 'brand_guidelines': brandGuidelines,
    'drive_links': driveLinks, 'social_media_access': socialMediaAccess, 'meeting_notes': meetingNotes,
    'internal_notes': internalNotes, 'sync_status': syncStatus,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(), 'user_id': userId, 'workspace_id': workspaceId,
  };
}
