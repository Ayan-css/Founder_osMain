class SupabaseConstants {
  SupabaseConstants._();

  // These should be set via environment variables or .env file
  // NEVER commit real values
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  // Table Names
  static const String usersTable = 'profiles';
  static const String contentTable = 'content_items';
  static const String knowledgeTable = 'knowledge_items';
  static const String leadsTable = 'leads';
  static const String clientsTable = 'clients';
  static const String transactionsTable = 'transactions';
  static const String resourcesTable = 'resources';
  static const String meetingsTable = 'meetings';
  static const String journalTable = 'journal_entries';
  static const String focusSessionsTable = 'focus_sessions';
  static const String tasksTable = 'tasks';
  static const String activityLogTable = 'activity_logs';

  // Storage Buckets
  static const String attachmentsBucket = 'attachments';
  static const String brandAssetsBucket = 'brand-assets';
}
