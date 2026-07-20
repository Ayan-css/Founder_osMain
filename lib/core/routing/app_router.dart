import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/verification_successful_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../services/database/collections/lead_collection.dart';
import '../../services/database/collections/client_collection.dart';
import '../../services/database/collections/transaction_collection.dart';
import '../../services/database/collections/meeting_collection.dart';
import '../../features/dashboard/presentation/screens/task_screen.dart';
import '../../features/content/presentation/screens/content_hub_screen.dart';
import '../../features/content/presentation/screens/content_detail_screen.dart';
import '../../features/content/presentation/screens/content_create_screen.dart';
import '../../features/content/presentation/screens/content_kanban_screen.dart';
import '../../features/content/presentation/screens/content_calendar_screen.dart';
import '../../features/knowledge/presentation/screens/knowledge_screen.dart';
import '../../features/knowledge/presentation/screens/knowledge_create_screen.dart';
import '../../features/crm/presentation/screens/crm_screen.dart';
import '../../features/crm/presentation/screens/lead_detail_screen.dart';
import '../../features/crm/presentation/screens/lead_create_screen.dart';
import '../../features/crm/presentation/screens/outreach_screen.dart';
import '../../features/crm/presentation/screens/outreach_detail_screen.dart';
import '../../features/crm/presentation/screens/outreach_analytics_screen.dart';
import '../../features/crm/presentation/screens/templates_screen.dart';
import '../../features/clients/presentation/screens/clients_screen.dart';
import '../../features/clients/presentation/screens/client_detail_screen.dart';
import '../../features/clients/presentation/screens/client_create_screen.dart';
import '../../features/finance/presentation/screens/finance_screen.dart';
import '../../features/finance/presentation/screens/invoice_generate_screen.dart';
import '../../features/finance/presentation/screens/invoice_preview_screen.dart';
import '../../features/finance/presentation/screens/transaction_create_screen.dart';
import '../../features/resources/presentation/screens/resources_screen.dart';
import '../../features/resources/presentation/screens/resource_create_screen.dart';
import '../../features/meetings/presentation/screens/meetings_screen.dart';
import '../../features/meetings/presentation/screens/meeting_detail_screen.dart';
import '../../features/meetings/presentation/screens/meeting_create_screen.dart';
import '../../features/journal/presentation/screens/journal_screen.dart';
import '../../features/journal/presentation/screens/journal_create_screen.dart';
import '../../features/focus/presentation/screens/focus_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/theme_settings_screen.dart';
import '../../features/settings/presentation/screens/agency_settings_screen.dart';
import '../../features/settings/presentation/screens/workspace_settings_screen.dart';
import '../../features/settings/presentation/screens/profile_screen.dart';
import '../../features/dashboard/presentation/screens/activity_feed_screen.dart';
import '../../shared/widgets/navigation_shell.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splash,
    routes: [
      // Splash (initial init)
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes (outside shell)
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.verificationSuccess,
        builder: (context, state) => const VerificationSuccessfulScreen(),
      ),

      // Main app shell with bottom nav + drawer
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => NavigationShell(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: RouteNames.dashboard,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const DashboardScreen(),
            ),
            routes: [
              GoRoute(
                path: 'activity',
                builder: (context, state) => const ActivityFeedScreen(),
              ),
            ],
          ),

          // Tasks
          GoRoute(
            path: RouteNames.tasks,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const TaskScreen(),
            ),
          ),

          // Content Hub
          GoRoute(
            path: RouteNames.contentHub,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const ContentHubScreen(),
            ),
            routes: [
              GoRoute(
                path: 'kanban',
                builder: (context, state) => const ContentKanbanScreen(),
              ),
              GoRoute(
                path: 'calendar',
                builder: (context, state) => const ContentCalendarScreen(),
              ),
              GoRoute(
                path: 'create',
                builder: (context, state) => const ContentCreateScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => ContentDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),

          // Knowledge
          GoRoute(
            path: RouteNames.knowledge,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const KnowledgeScreen(),
            ),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const KnowledgeCreateScreen(),
              ),
            ],
          ),

          // CRM
          GoRoute(
            path: RouteNames.crm,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const CrmScreen(),
            ),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const LeadCreateScreen(),
              ),
              GoRoute(
                path: 'edit',
                builder: (context, state) => LeadCreateScreen(
                  editingLead: state.extra as LeadItem?,
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => LeadDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),

          // Cold Outreach
          GoRoute(
            path: RouteNames.outreach,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const OutreachScreen(),
            ),
            routes: [
              GoRoute(
                path: 'analytics',
                builder: (context, state) => const OutreachAnalyticsScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => OutreachDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          
          // Templates
          GoRoute(
            path: RouteNames.templates,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const TemplatesScreen(),
            ),
          ),

          // Clients
          GoRoute(
            path: RouteNames.clients,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const ClientsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const ClientCreateScreen(),
              ),
              GoRoute(
                path: 'edit',
                builder: (context, state) => ClientCreateScreen(
                  editingClient: state.extra as ClientItem?,
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => ClientDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),

          // Finance
          GoRoute(
            path: RouteNames.finance,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const FinanceScreen(),
            ),
            routes: [
              GoRoute(
                path: 'invoice/generate',
                builder: (context, state) {
                  final initialClientId = state.extra as String?;
                  return InvoiceGenerateScreen(initialClientId: initialClientId);
                },
              ),
              GoRoute(
                path: 'invoices/:id/preview',
                builder: (context, state) {
                  final client = state.extra as ClientItem?;
                  return InvoicePreviewScreen(
                    invoiceId: state.pathParameters['id']!,
                    client: client,
                  );
                },
              ),
              GoRoute(
                path: 'create',
                builder: (context, state) {
                  final editing = state.extra as TransactionItem?;
                  return TransactionCreateScreen(editingTransaction: editing);
                },
              ),
            ],
          ),

          // Resources
          GoRoute(
            path: RouteNames.resources,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const ResourcesScreen(),
            ),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const ResourceCreateScreen(),
              ),
            ],
          ),

          // Meetings
          GoRoute(
            path: RouteNames.meetings,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const MeetingsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) {
                  final editing = state.extra as MeetingItem?;
                  return MeetingCreateScreen(editingMeeting: editing);
                },
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => MeetingDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),

          // Journal
          GoRoute(
            path: RouteNames.journal,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const JournalScreen(),
            ),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const JournalCreateScreen(),
              ),
            ],
          ),

          // Focus
          GoRoute(
            path: RouteNames.focus,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const FocusScreen(),
            ),
          ),

          // Reports
          GoRoute(
            path: RouteNames.reports,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const ReportsScreen(),
            ),
          ),

          // Settings
          GoRoute(
            path: RouteNames.settings,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const SettingsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: 'theme',
                builder: (context, state) => const ThemeSettingsScreen(),
              ),
              GoRoute(
                path: 'agency',
                builder: (context, state) => const AgencySettingsScreen(),
              ),
              GoRoute(
                path: 'workspaces',
                builder: (context, state) => const WorkspaceSettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
