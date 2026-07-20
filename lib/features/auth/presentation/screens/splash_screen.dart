import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../services/database/isar_service.dart';
import '../../../../services/widget_service.dart';
import '../../../../services/workspace_service.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  String _statusText = 'Initializing services...';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);

    _initializeApp();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => _statusText = 'Loading local data...');

      // Read saved workspace ID to open the correct Isar DB
      final prefs = await SharedPreferences.getInstance();
      final savedWorkspaceId = prefs.getString('current_workspace_id');
      final dbName = IsarService.dbNameForWorkspace(savedWorkspaceId);
      await IsarService.initialize(dbName);

      setState(() => _statusText = 'Setting up widgets...');
      await WidgetService.initialize();
      await WidgetService.syncWidgets();

      setState(() => _statusText = 'Connecting to cloud...');
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );

      // Re-initialize auth provider now that Supabase is ready
      ref.invalidate(authNotifierProvider);

      setState(() => _statusText = 'Checking authentication...');
      final isGuest = prefs.getBool('isGuest') ?? false;
      final session = Supabase.instance.client.auth.currentSession;

      // Set workspace state provider if we have a saved workspace
      if (savedWorkspaceId != null && session != null) {
        ref.read(currentWorkspaceIdProvider.notifier).state = savedWorkspaceId;
      }

      // Small delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        if (session != null || isGuest) {
          context.go(RouteNames.dashboard);
        } else {
          context.go(RouteNames.login);
        }
      }
    } catch (e, stack) {
      debugPrint('App initialization error: $e');
      debugPrint(stack.toString());
      if (mounted) {
        setState(() => _statusText = '$_statusText\nFailed! Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Fake App Bar for skeleton
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colors.outline.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 14,
                        decoration: BoxDecoration(
                          color: colors.outline.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.outline.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _statusText,
                style: TextStyle(
                  color: _statusText.contains('failed') ? Colors.red : colors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: _statusText.contains('failed')
                  ? const SizedBox() // hide skeleton on fail
                  : const DashboardLoadingSkeleton(),
            ),
          ],
        ),
      ),
    );
  }
}
