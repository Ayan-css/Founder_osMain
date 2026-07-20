import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import 'app_theme.dart';
import '../../services/database/repositories/profile_repository.dart';

/// State class for theme management
class ThemeState {
  final AppThemeId themeId;
  final ThemeMode themeMode;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  const ThemeState({
    required this.themeId,
    required this.themeMode,
    required this.lightTheme,
    required this.darkTheme,
  });

  ThemeState copyWith({
    AppThemeId? themeId,
    ThemeMode? themeMode,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
  }) {
    return ThemeState(
      themeId: themeId ?? this.themeId,
      themeMode: themeMode ?? this.themeMode,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
    );
  }
}

/// Theme state notifier with persistence
class ThemeNotifier extends StateNotifier<ThemeState> {
  final SharedPreferences _prefs;
  final Ref _ref;

  static const _themeIdKey = 'theme_id';
  static const _themeModeKey = 'theme_mode';

  ThemeNotifier(this._prefs, this._ref) : super(_initialState(_prefs));

  static ThemeState _initialState(SharedPreferences prefs) {
    final savedThemeId = prefs.getString(_themeIdKey);
    final savedMode = prefs.getString(_themeModeKey);

    final themeId = savedThemeId != null
        ? AppThemeId.values.firstWhere(
            (e) => e.name == savedThemeId,
            orElse: () => AppThemeId.darkProfessional,
          )
        : AppThemeId.darkProfessional;

    final themeMode = savedMode != null
        ? ThemeMode.values.firstWhere(
            (e) => e.name == savedMode,
            orElse: () => ThemeMode.dark,
          )
        : ThemeMode.dark;

    final themes = AppTheme.getThemePair(themeId);

    return ThemeState(
      themeId: themeId,
      themeMode: themeMode,
      lightTheme: themes.light,
      darkTheme: themes.dark,
    );
  }

  /// Switch to a specific theme
  void setTheme(AppThemeId id) {
    final themes = AppTheme.getThemePair(id);
    state = state.copyWith(
      themeId: id,
      lightTheme: themes.light,
      darkTheme: themes.dark,
    );
    _prefs.setString(_themeIdKey, id.name);
    _syncToProfile(themeId: id.name);
  }

  /// Set theme mode (light, dark, system)
  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs.setString(_themeModeKey, mode.name);
    _syncToProfile(themeMode: mode.name);
  }
  
  void _syncToProfile({String? themeId, String? themeMode}) {
    try {
      _ref.read(profileRepositoryProvider).updateProfile(
        themeId: themeId,
        themeMode: themeMode,
      );
    } catch (_) {}
  }

  /// Toggle between light and dark mode
  void toggleThemeMode() {
    final newMode =
        state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(newMode);
  }
}

/// Provider for the theme notifier
final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs, ref);
});
