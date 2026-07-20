import '../database/collections/task_collection.dart';
import '../database/collections/content_collection.dart';
import '../database/collections/lead_collection.dart';
import '../database/collections/client_collection.dart';
import '../database/collections/transaction_collection.dart';
import '../database/collections/knowledge_collection.dart';
import '../database/collections/meeting_collection.dart';
import '../database/collections/journal_collection.dart';
import '../database/collections/focus_session_collection.dart';
import '../database/collections/resource_collection.dart';
import '../database/collections/invoice_collection.dart';
import '../database/collections/outreach_collection.dart';
import '../database/collections/outreach_activity_collection.dart';
import '../database/collections/template_collection.dart';
import '../database/collections/campaign_collection.dart';
class SyncMapper {
  static TaskItem taskFromJson(Map<String, dynamic> json) {
    return TaskItem()
      ..id = json['id']
      ..title = json['title']
      ..description = json['description']
      ..priority = json['priority']
      ..dueDate = json['due_date'] != null ? DateTime.parse(json['due_date']) : null
      ..isCompleted = json['is_completed'] ?? false
      ..isPinned = json['is_pinned'] ?? false
      ..sortOrder = json['sort_order'] ?? 0
      ..syncStatus = 'synced'
      ..createdAt = DateTime.parse(json['created_at'])
      ..updatedAt = DateTime.parse(json['updated_at'])
      ..userId = json['user_id']
      ..workspaceId = json['workspace_id'];
  }

  static ContentItem contentFromJson(Map<String, dynamic> json) {
    return ContentItem()
      ..id = json['id']
      ..title = json['title']
      ..description = json['description']
      ..stage = json['stage'] ?? 'Raw Thought'
      ..tags = (json['tags'] as List?)?.cast<String>() ?? []
      ..category = json['category']
      ..format = json['format']
      ..platform = json['platform']
      ..priority = json['priority'] ?? 'Low'
      ..dueDate = json['due_date'] != null ? DateTime.parse(json['due_date']) : null
      ..notes = json['notes']
      ..attachmentUrls = (json['attachment_urls'] as List?)?.cast<String>() ?? []
      ..relatedContentIds = (json['related_content_ids'] as List?)?.cast<String>() ?? []
      ..version = json['version'] ?? 1
      ..syncStatus = 'synced'
      ..createdAt = DateTime.parse(json['created_at'])
      ..updatedAt = DateTime.parse(json['updated_at'])
      ..userId = json['user_id']
      ..workspaceId = json['workspace_id'];
  }

  static LeadItem leadFromJson(Map<String, dynamic> json) {
    return LeadItem()
      ..id = json['id']
      ..name = json['name']
      ..company = json['company']
      ..email = json['email']
      ..phone = json['phone']
      ..leadSource = json['lead_source'] ?? 'Other'
      ..industry = json['industry']
      ..dealValue = (json['deal_value'] as num?)?.toDouble() ?? 0.0
      ..stage = json['stage'] ?? 'New'
      ..notes = json['notes']
      ..followUpDate = json['follow_up_date'] != null ? DateTime.parse(json['follow_up_date']) : null
      ..meetingHistory = (json['meeting_history'] as List?)?.cast<String>() ?? []
      ..syncStatus = 'synced'
      ..createdAt = DateTime.parse(json['created_at'])
      ..updatedAt = DateTime.parse(json['updated_at'])
      ..userId = json['user_id']
      ..workspaceId = json['workspace_id'];
  }

  static ClientItem clientFromJson(Map<String, dynamic> json) {
    return ClientItem()
      ..id = json['id']
      ..name = json['name']
      ..businessName = json['business_name']
      ..email = json['email']
      ..phone = json['phone']
      ..website = json['website']
      ..address = json['address']
      ..gstNumber = json['gst_number']
      ..socialLinks = (json['social_links'] as List?)?.cast<String>() ?? []
      ..isRetainer = json['is_retainer'] ?? false
      ..retainerAmount = (json['retainer_amount'] as num?)?.toDouble() ?? 0.0
      ..projectValue = (json['project_value'] as num?)?.toDouble() ?? 0.0
      ..amountReceived = (json['amount_received'] as num?)?.toDouble() ?? 0.0
      ..deliverables = (json['deliverables'] as List?)?.cast<String>() ?? []
      ..deadline = json['deadline'] != null ? DateTime.parse(json['deadline']) : null
      ..status = json['status'] ?? 'Active'
      ..logoUrl = json['logo_url']
      ..brandColors = (json['brand_colors'] as List?)?.cast<String>() ?? []
      ..brandGuidelines = json['brand_guidelines']
      ..driveLinks = (json['drive_links'] as List?)?.cast<String>() ?? []
      ..socialMediaAccess = json['social_media_access']
      ..meetingNotes = json['meeting_notes']
      ..internalNotes = json['internal_notes']
      ..syncStatus = 'synced'
      ..createdAt = DateTime.parse(json['created_at'])
      ..updatedAt = DateTime.parse(json['updated_at'])
      ..userId = json['user_id']
      ..workspaceId = json['workspace_id'];
  }

  static TransactionItem transactionFromJson(Map<String, dynamic> json) {
    return TransactionItem()
      ..id = json['id']
      ..type = json['type']
      ..amount = (json['amount'] as num).toDouble()
      ..category = json['category']
      ..clientId = json['client_id']
      ..clientName = json['client_name']
      ..date = DateTime.parse(json['date'])
      ..description = json['description']
      ..receiptUrl = json['receipt_url']
      ..resourceName = json['resource_name']
      ..resourceType = json['resource_type']
      ..syncStatus = 'synced'
      ..createdAt = DateTime.parse(json['created_at'])
      ..updatedAt = DateTime.parse(json['updated_at'])
      ..userId = json['user_id']
      ..workspaceId = json['workspace_id'];
  }

  static KnowledgeItem knowledgeFromJson(Map<String, dynamic> json) {
    return KnowledgeItem()
      ..id = json['id']
      ..title = json['title']
      ..content = json['content']
      ..category = json['category']
      ..collectionName = json['collection_name']
      ..tags = (json['tags'] as List?)?.cast<String>() ?? []
      ..isFavorite = json['is_favorite'] ?? false
      ..syncStatus = 'synced'
      ..createdAt = DateTime.parse(json['created_at'])
      ..updatedAt = DateTime.parse(json['updated_at'])
      ..userId = json['user_id']
      ..workspaceId = json['workspace_id'];
  }

  static MeetingItem meetingFromJson(Map<String, dynamic> json) {
    return MeetingItem()
      ..id = json['id']
      ..type = json['type'] ?? 'client'
      ..title = json['title']
      ..agenda = json['agenda']
      ..participants = (json['participants'] as List?)?.cast<String>() ?? []
      ..notes = json['notes']
      ..actionItems = (json['action_items'] as List?)?.cast<String>() ?? []
      ..date = DateTime.parse(json['date'])
      ..clientId = json['client_id']
      ..clientName = json['client_name']
      ..requirements = json['requirements']
      ..decisions = json['decisions']
      ..followUps = (json['follow_ups'] as List?)?.cast<String>() ?? []
      ..attachmentUrls = (json['attachment_urls'] as List?)?.cast<String>() ?? []
      ..syncStatus = 'synced'
      ..createdAt = DateTime.parse(json['created_at'])
      ..updatedAt = DateTime.parse(json['updated_at'])
      ..userId = json['user_id']
      ..workspaceId = json['workspace_id'];
  }

  static JournalEntry journalFromJson(Map<String, dynamic> json) {
    return JournalEntry()
      ..id = json['id']
      ..date = DateTime.parse(json['date'])
      ..wentWell = json['went_well']
      ..didNotGoWell = json['did_not_go_well']
      ..lessonsLearned = json['lessons_learned']
      ..wins = json['wins']
      ..mistakes = json['mistakes']
      ..gratitude = json['gratitude']
      ..improvementsForTomorrow = json['improvements_for_tomorrow']
      ..mood = json['mood'] ?? 'Neutral'
      ..syncStatus = 'synced'
      ..createdAt = DateTime.parse(json['created_at'])
      ..updatedAt = DateTime.parse(json['updated_at'])
      ..userId = json['user_id']
      ..workspaceId = json['workspace_id'];
  }

  static FocusSession focusSessionFromJson(Map<String, dynamic> json) {
    return FocusSession()
      ..id = json['id']
      ..type = json['type'] ?? 'pomodoro'
      ..durationMinutes = json['duration_minutes'] ?? 0
      ..startTime = DateTime.parse(json['start_time'])
      ..endTime = json['end_time'] != null ? DateTime.parse(json['end_time']) : null
      ..completed = json['completed'] ?? false
      ..label = json['label']
      ..syncStatus = 'synced'
      ..createdAt = DateTime.parse(json['created_at'])
      ..updatedAt = DateTime.parse(json['updated_at'])
      ..userId = json['user_id']
      ..workspaceId = json['workspace_id'];
  }

  static ResourceItem resourceFromJson(Map<String, dynamic> json) {
    return ResourceItem()
      ..id = json['id']
      ..name = json['name']
      ..type = json['type'] ?? 'Tool'
      ..cost = (json['cost'] as num?)?.toDouble() ?? 0.0
      ..description = json['description']
      ..isPurchased = json['is_purchased'] ?? false
      ..renewalDate = json['renewal_date'] != null ? DateTime.parse(json['renewal_date']) : null
      ..licenseKey = json['license_key']
      ..url = json['url']
      ..estimatedCost = (json['estimated_cost'] as num?)?.toDouble() ?? 0.0
      ..priority = json['priority'] ?? 'Low'
      ..purchaseReason = json['purchase_reason']
      ..targetPurchaseDate = json['target_purchase_date'] != null ? DateTime.parse(json['target_purchase_date']) : null
      ..syncStatus = 'synced'
      ..createdAt = DateTime.parse(json['created_at'])
      ..updatedAt = DateTime.parse(json['updated_at'])
      ..userId = json['user_id']
      ..workspaceId = json['workspace_id'];
  }

  static InvoiceItem invoiceFromJson(Map<String, dynamic> json) {
    return InvoiceItem()
      ..id = json['id']
      ..clientId = json['client_id']
      ..clientName = json['client_name']
      ..serviceName = json['service_name']
      ..duration = json['duration']
      ..baseAmount = (json['base_amount'] as num).toDouble()
      ..gstRate = (json['gst_rate'] as num).toDouble()
      ..taxAmount = (json['tax_amount'] as num).toDouble()
      ..totalAmount = (json['total_amount'] as num).toDouble()
      ..paymentType = json['payment_type']
      ..amountPaidPreviously = (json['amount_paid_previously'] as num).toDouble()
      ..issueDate = DateTime.parse(json['issue_date'])
      ..dueDate = DateTime.parse(json['due_date'])
      ..status = json['status'] ?? 'Unpaid'
      ..pdfFilePath = json['pdf_file_path']
      ..createdAt = DateTime.parse(json['created_at'])
      ..updatedAt = DateTime.parse(json['updated_at'])
      ..syncStatus = 'synced'
      ..userId = json['user_id']
      ..workspaceId = json['workspace_id'];
  }

  static OutreachItem outreachFromJson(Map<String, dynamic> json) {
    return OutreachItem()
      ..id = json['id']
      ..name = json['name']
      ..company = json['company']
      ..platform = json['platform'] ?? 'Other'
      ..status = json['status'] ?? 'Not Replied'
      ..contactDetail = json['contact_detail']
      ..notes = json['notes']
      ..followUpDate = json['follow_up_date'] != null ? DateTime.parse(json['follow_up_date']) : null
      ..campaignId = json['campaign_id']
      ..priority = json['priority'] ?? 'Medium'
      ..syncStatus = 'synced'
      ..createdAt = DateTime.parse(json['created_at'])
      ..updatedAt = DateTime.parse(json['updated_at'])
      ..userId = json['user_id']
      ..workspaceId = json['workspace_id'];
  }

  static OutreachActivity outreachActivityFromJson(Map<String, dynamic> json) {
    return OutreachActivity()
      ..id = json['id']
      ..outreachItemId = json['outreach_item_id']
      ..type = json['type']
      ..description = json['description']
      ..timestamp = DateTime.parse(json['timestamp'])
      ..syncStatus = 'synced'
      ..createdAt = DateTime.parse(json['created_at'])
      ..updatedAt = DateTime.parse(json['updated_at'])
      ..userId = json['user_id']
      ..workspaceId = json['workspace_id'];
  }

  static TemplateItem templateFromJson(Map<String, dynamic> json) {
    return TemplateItem()
      ..id = json['id']
      ..name = json['name']
      ..platform = json['platform']
      ..subject = json['subject']
      ..body = json['body']
      ..syncStatus = 'synced'
      ..createdAt = DateTime.parse(json['created_at'])
      ..updatedAt = DateTime.parse(json['updated_at'])
      ..userId = json['user_id']
      ..workspaceId = json['workspace_id'];
  }

  static CampaignItem campaignFromJson(Map<String, dynamic> json) {
    return CampaignItem()
      ..id = json['id']
      ..name = json['name']
      ..description = json['description']
      ..status = json['status'] ?? 'Active'
      ..syncStatus = 'synced'
      ..createdAt = DateTime.parse(json['created_at'])
      ..updatedAt = DateTime.parse(json['updated_at'])
      ..userId = json['user_id']
      ..workspaceId = json['workspace_id'];
  }
}
