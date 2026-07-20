class RouteNames {
  RouteNames._();

  // Auth
  static const splash = '/splash';
  static const login = '/login';
  static const verificationSuccess = '/login-callback';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // Main
  static const dashboard = '/';
  static const tasks = '/tasks';
  static const contentHub = '/content';
  static const contentDetail = '/content/:id';
  static const contentCreate = '/content/create';
  static const contentKanban = '/content/kanban';
  static const contentCalendar = '/content/calendar';

  // Knowledge
  static const knowledge = '/knowledge';
  static const knowledgeDetail = '/knowledge/:id';
  static const knowledgeCreate = '/knowledge/create';

  // CRM
  static const crm = '/crm';
  static const leadDetail = '/crm/:id';
  static const leadCreate = '/crm/create';

  // Cold Outreach
  static const outreach = '/outreach';
  static const outreachAnalytics = '/outreach/analytics';
  static const templates = '/templates';

  // Clients
  static const clients = '/clients';
  static const clientDetail = '/clients/:id';
  static const clientCreate = '/clients/create';

  // Finance
  static const finance = '/finance';
  static const transactionCreate = '/finance/create';

  // Resources
  static const resources = '/resources';
  static const resourceCreate = '/resources/create';

  // Meetings
  static const meetings = '/meetings';
  static const meetingDetail = '/meetings/:id';
  static const meetingCreate = '/meetings/create';

  // Journal
  static const journal = '/journal';
  static const journalEntry = '/journal/:id';
  static const journalCreate = '/journal/create';

  // Focus
  static const focus = '/focus';

  // Reports
  static const reports = '/reports';

  // Settings
  static const settings = '/settings';
  static const settingsTheme = '/settings/theme';
  static const settingsProfile = '/settings/profile';
}
