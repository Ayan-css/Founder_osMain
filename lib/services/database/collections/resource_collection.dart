import 'package:isar/isar.dart';

part 'resource_collection.g.dart';

@collection
class ResourceItem {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String name;
  late String type; // Software, Equipment, Templates, Courses, Assets, Tools
  double cost = 0;
  String? description;
  bool isPurchased = true;

  // For existing resources
  DateTime? renewalDate;
  String? licenseKey;
  String? url;

  // For future purchases
  double estimatedCost = 0;
  late String priority; // Critical, High, Medium, Low
  String? purchaseReason;
  DateTime? targetPurchaseDate;

  // Sync fields
  late String syncStatus;
  late DateTime createdAt;
  late DateTime updatedAt;
  String? userId;
  String? workspaceId;

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'type': type, 'cost': cost, 'description': description,
    'is_purchased': isPurchased, 'renewal_date': renewalDate?.toIso8601String(),
    'license_key': licenseKey, 'url': url, 'estimated_cost': estimatedCost, 'priority': priority,
    'purchase_reason': purchaseReason, 'target_purchase_date': targetPurchaseDate?.toIso8601String(),
    'sync_status': syncStatus, 'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(), 'user_id': userId, 'workspace_id': workspaceId,
  };
}
