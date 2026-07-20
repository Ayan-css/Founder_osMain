import 'package:isar/isar.dart';

part 'invoice_collection.g.dart';

@collection
class InvoiceItem {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String clientId;
  late String clientName;
  String? clientContactNumber;
  late String serviceName;
  late String duration;
  late double baseAmount;
  String? agencyGstInfo;
  String? clientGstInfo;
  late double gstRate;
  late double taxAmount;
  late double totalAmount;

  late String paymentType; // Advance Payment, Retainer Payment, Sign Up Payment, Remaining Payment
  late double amountPaidPreviously;

  late DateTime issueDate;
  late DateTime dueDate;
  
  late String status; // Draft, Sent, Paid, Overdue
  String? pdfFilePath;
  String? qrCodeImagePath;

  // Sync fields
  late String syncStatus;
  late DateTime createdAt;
  late DateTime updatedAt;
  String? userId;
  String? workspaceId;

  Map<String, dynamic> toJson() => {
    'id': id, 'client_id': clientId, 'client_name': clientName,
    'client_contact_number': clientContactNumber,
    'service_name': serviceName, 'duration': duration,
    'base_amount': baseAmount, 'agency_gst_info': agencyGstInfo, 'client_gst_info': clientGstInfo, 'gst_rate': gstRate,
    'tax_amount': taxAmount, 'total_amount': totalAmount,
    'payment_type': paymentType, 'amount_paid_previously': amountPaidPreviously,
    'issue_date': issueDate.toIso8601String(), 'due_date': dueDate.toIso8601String(),
    'status': status, 'pdf_file_path': pdfFilePath, 'qr_code_image_path': qrCodeImagePath,
    'sync_status': syncStatus,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(), 'user_id': userId, 'workspace_id': workspaceId,
  };
}
