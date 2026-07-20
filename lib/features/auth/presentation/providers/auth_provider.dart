import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/database/isar_service.dart';
import '../../../../services/workspace_service.dart';

/// Auth state for the app
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isGuest;

  const AuthState({this.user, this.isLoading = false, this.error, this.isGuest = false});

  bool get isAuthenticated => user != null;
  bool get hasAccess => user != null || isGuest;

  AuthState copyWith({User? user, bool? isLoading, String? error, bool clearUser = false, bool clearError = false, bool? isGuest}) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

/// Auth state notifier with Supabase integration
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription<AuthChangeEvent>? _authSubscription;

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  void _init() {
    // Check current session
    final session = _supabase.auth.currentSession;
    if (session != null) {
      state = AuthState(user: session.user);
    }

    // Listen to auth changes
    _authSubscription = _supabase.auth.onAuthStateChange.map((data) => data.event).listen((event) {
      switch (event) {
        case AuthChangeEvent.signedIn:
          state = AuthState(user: _supabase.auth.currentUser);
          break;
        case AuthChangeEvent.signedOut:
          state = const AuthState();
          break;
        case AuthChangeEvent.tokenRefreshed:
          state = AuthState(user: _supabase.auth.currentUser);
          break;
        default:
          break;
      }
    });
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      state = AuthState(user: _supabase.auth.currentUser);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An error occurred. Please try again.');
      return false;
    }
  }

  /// Sign in with magic link (OTP)
  Future<bool> signInWithMagicLink(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _supabase.auth.signInWithOtp(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An error occurred. Please try again.');
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _supabase.auth.signUp(email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An error occurred. Please try again.');
      return false;
    }
  }

  /// Send password reset email
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to send reset email. Try again.');
      return false;
    }
  }

  /// Comprehensive sign out: stops sync, closes Isar, clears workspace prefs.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. Sign out from Supabase
      await _supabase.auth.signOut();

      // 2. Close Isar (don't delete — user data stays for next login)
      await IsarService.close();

      // 3. Clear workspace from SharedPreferences
      final ws = WorkspaceService();
      await ws.clearCurrentWorkspace();

      // 4. Reset auth state
      state = const AuthState();
      debugPrint('[AuthNotifier] Signed out successfully');
    } catch (e) {
      debugPrint('[AuthNotifier] Sign out error: $e');
      // Force-reset state even on error so UI doesn't get stuck
      state = const AuthState();
    }
  }

  /// Set guest mode
  void setGuestMode(bool isGuest) {
    state = state.copyWith(isGuest: isGuest, clearUser: true);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Providers
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

final hasAccessProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).hasAccess;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authNotifierProvider).user;
});
