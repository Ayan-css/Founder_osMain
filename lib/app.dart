import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'core/routing/app_router.dart';
import 'core/routing/route_names.dart';
import 'core/theme/theme_provider.dart';

class RightCraftMediaApp extends ConsumerStatefulWidget {
  const RightCraftMediaApp({super.key});

  @override
  ConsumerState<RightCraftMediaApp> createState() => _RightCraftMediaAppState();
}

class _RightCraftMediaAppState extends ConsumerState<RightCraftMediaApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link if app was in cold state (terminated)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("Failed to get initial link: $e");
    }

    // Handle link when app is in warm state (foreground or background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint("Failed to handle incoming link: $err");
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'io.supabase.rcmos' && uri.host == 'login-callback') {
      // Small delay to ensure router is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        ref.read(routerProvider).go(RouteNames.verificationSuccess);
      });
    } else if (uri.scheme == 'rcmos') {
      Future.delayed(const Duration(milliseconds: 500), () {
        final router = ref.read(routerProvider);
        if (uri.host == 'create-task') {
          router.push('/tasks/create');
        } else if (uri.host == 'create-lead') {
          router.push('/crm/create');
        } else if (uri.host == 'create-outreach') {
          // No direct outreach create route yet, pushing to CRM with tab index?
          // Or pushing to outreach screen?
          router.go('/crm');
        } else if (uri.host == 'dashboard') {
          router.go('/');
        }
      });
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeNotifierProvider);

    return MaterialApp.router(
      title: 'RCM OS',
      debugShowCheckedModeBanner: false,
      theme: themeState.lightTheme,
      darkTheme: themeState.darkTheme,
      themeMode: themeState.themeMode,
      routerConfig: router,
    );
  }
}
