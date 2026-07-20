import 'package:isar/isar.dart';

part 'transaction_collection.g.dart';

@collection
class TransactionItem {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String type; // revenue, expense
  late double amount;
  late String category; // Software, Marketing, Equipment, Client Payment, etc.
  String? clientId;
  String? clientName;
  late DateTime date;
  String? description;
  String? receiptUrl;
  String? resourceName;
  String? resourceType;

  // Sync fields
  late String syncStatus;
  late DateTime createdAt;
  late DateTime updatedAt;
  String? userId;
  String? workspaceId;

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type, 'amount': amount, 'category': category,
    'client_id': clientId, 'client_name': clientName, 'date': date.toIso8601String(),
    'description': description, 'receipt_url': receiptUrl,
    'resource_name': resourceName, 'resource_type': resourceType,
    'sync_status': syncStatus,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(), 'user_id': userId, 'workspace_id': workspaceId,
  };
}
