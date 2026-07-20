import 'package:flutter/material.dart';
import 'app_theme.dart';

/// All 10 professional color schemes with light & dark variants
class AppColorSchemes {
  AppColorSchemes._();

  static ({ColorScheme light, ColorScheme dark}) getColorSchemes(AppThemeId id) {
    switch (id) {
      case AppThemeId.darkProfessional:
        return (light: _darkProfLight, dark: _darkProfDark);
      case AppThemeId.lightProfessional:
        return (light: _lightProfLight, dark: _lightProfDark);
      case AppThemeId.midnightBlue:
        return (light: _midnightLight, dark: _midnightDark);
      case AppThemeId.forestGreen:
        return (light: _forestLight, dark: _forestDark);
      case AppThemeId.royalPurple:
        return (light: _purpleLight, dark: _purpleDark);
      case AppThemeId.maroonBeige:
        return (light: _maroonLight, dark: _maroonDark);
      case AppThemeId.blackGold:
        return (light: _goldLight, dark: _goldDark);
      case AppThemeId.oceanBlue:
        return (light: _oceanLight, dark: _oceanDark);
      case AppThemeId.minimalGray:
        return (light: _grayLight, dark: _grayDark);
      case AppThemeId.highContrast:
        return (light: _hcLight, dark: _hcDark);
      case AppThemeId.monochromatic:
        return (light: _monoLight, dark: _monoDark);
      case AppThemeId.neonPurple:
        return (light: _neonPurpleLight, dark: _neonPurpleDark);
      case AppThemeId.neonBlue:
        return (light: _neonBlueLight, dark: _neonBlueDark);
      case AppThemeId.neonGreen:
        return (light: _neonGreenLight, dark: _neonGreenDark);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 1. Dark Professional
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static final _darkProfLight = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6366F1),
    brightness: Brightness.light,
  );
  static final _darkProfDark = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6366F1),
    brightness: Brightness.dark,
    surface: const Color(0xFF0F0F14),
    onSurface: const Color(0xFFE8E8ED),
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 2. Light Professional
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static final _lightProfLight = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3B82F6),
    brightness: Brightness.light,
    surface: const Color(0xFFFAFAFC),
  );
  static final _lightProfDark = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3B82F6),
    brightness: Brightness.dark,
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 3. Midnight Blue
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static final _midnightLight = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1E3A5F),
    brightness: Brightness.light,
    primary: const Color(0xFF1E3A5F),
    secondary: const Color(0xFF4A90D9),
  );
  static final _midnightDark = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1E3A5F),
    brightness: Brightness.dark,
    surface: const Color(0xFF0A1628),
    primary: const Color(0xFF5B9BD5),
    onSurface: const Color(0xFFD4E4F7),
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 4. Forest Green
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static final _forestLight = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2D6A4F),
    brightness: Brightness.light,
    primary: const Color(0xFF2D6A4F),
    secondary: const Color(0xFF52B788),
  );
  static final _forestDark = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2D6A4F),
    brightness: Brightness.dark,
    surface: const Color(0xFF0B1F15),
    primary: const Color(0xFF52B788),
    onSurface: const Color(0xFFD8F3DC),
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 5. Royal Purple
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static final _purpleLight = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7C3AED),
    brightness: Brightness.light,
    primary: const Color(0xFF7C3AED),
    secondary: const Color(0xFFA78BFA),
  );
  static final _purpleDark = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7C3AED),
    brightness: Brightness.dark,
    surface: const Color(0xFF120B24),
    primary: const Color(0xFFA78BFA),
    onSurface: const Color(0xFFE8DFFB),
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 6. Maroon & Beige
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static final _maroonLight = ColorScheme.fromSeed(
    seedColor: const Color(0xFF8B2252),
    brightness: Brightness.light,
    primary: const Color(0xFF8B2252),
    secondary: const Color(0xFFD4A574),
    surface: const Color(0xFFFFF8F0),
  );
  static final _maroonDark = ColorScheme.fromSeed(
    seedColor: const Color(0xFF8B2252),
    brightness: Brightness.dark,
    surface: const Color(0xFF1A0E14),
    primary: const Color(0xFFE8729A),
    onSurface: const Color(0xFFF5E6D3),
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 7. Black & Gold
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static final _goldLight = ColorScheme.fromSeed(
    seedColor: const Color(0xFFB8860B),
    brightness: Brightness.light,
    primary: const Color(0xFFB8860B),
    secondary: const Color(0xFFDAA520),
  );
  static final _goldDark = ColorScheme.fromSeed(
    seedColor: const Color(0xFFDAA520),
    brightness: Brightness.dark,
    surface: const Color(0xFF0C0C0C),
    primary: const Color(0xFFDAA520),
    secondary: const Color(0xFFFFD700),
    onSurface: const Color(0xFFF5F0E1),
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 8. Ocean Blue
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static final _oceanLight = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0077B6),
    brightness: Brightness.light,
    primary: const Color(0xFF0077B6),
    secondary: const Color(0xFF00B4D8),
  );
  static final _oceanDark = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0077B6),
    brightness: Brightness.dark,
    surface: const Color(0xFF041C2C),
    primary: const Color(0xFF48CAE4),
    onSurface: const Color(0xFFCAF0F8),
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 9. Minimal Gray
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static final _grayLight = ColorScheme.fromSeed(
    seedColor: const Color(0xFF64748B),
    brightness: Brightness.light,
    primary: const Color(0xFF475569),
    surface: const Color(0xFFF8FAFC),
  );
  static final _grayDark = ColorScheme.fromSeed(
    seedColor: const Color(0xFF64748B),
    brightness: Brightness.dark,
    surface: const Color(0xFF0F1419),
    primary: const Color(0xFF94A3B8),
    onSurface: const Color(0xFFE2E8F0),
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 10. High Contrast
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const _hcLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0000CC),
    onPrimary: Colors.white,
    secondary: Color(0xFF006600),
    onSecondary: Colors.white,
    error: Color(0xFFCC0000),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
  );
  static const _hcDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF6699FF),
    onPrimary: Colors.black,
    secondary: Color(0xFF66FF66),
    onSecondary: Colors.black,
    error: Color(0xFFFF6666),
    onError: Colors.black,
    surface: Colors.black,
    onSurface: Colors.white,
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 11. Monochromatic (Nothing OS Minimalist)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const _monoLight = ColorScheme(
    brightness: Brightness.light,
    primary: Colors.black,
    onPrimary: Colors.white,
    secondary: Colors.black,
    onSecondary: Colors.white,
    error: Color(0xFFFF0000), // Red for expenses/destructive
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
    outline: Colors.black,
  );
  
  static const _monoDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Colors.white,
    onPrimary: Colors.black,
    secondary: Colors.white,
    onSecondary: Colors.black,
    error: Color(0xFFFF0000), // Red for expenses/destructive
    onError: Colors.white,
    surface: Colors.black,
    onSurface: Colors.white,
    outline: Colors.white,
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 12. Neon Purple (Glassmorphism)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static final _neonPurpleLight = ColorScheme.fromSeed(
    seedColor: const Color(0xFF9D4EDD), // Bright Purple
    brightness: Brightness.light,
  );
  static final _neonPurpleDark = ColorScheme.fromSeed(
    seedColor: const Color(0xFF9D4EDD), // Bright Purple
    brightness: Brightness.dark,
    surface: const Color(0xFF0A0A0E), // Very dark background
    primary: const Color(0xFFB185FF), // Neon glowing purple
    onSurface: const Color(0xFFF3F4F6),
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 13. Neon Blue (Glassmorphism)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static final _neonBlueLight = ColorScheme.fromSeed(
    seedColor: const Color(0xFF00B4D8),
    brightness: Brightness.light,
  );
  static final _neonBlueDark = ColorScheme.fromSeed(
    seedColor: const Color(0xFF00B4D8),
    brightness: Brightness.dark,
    surface: const Color(0xFF0A0A0E), // Very dark background
    primary: const Color(0xFF48CAE4), // Neon glowing blue
    onSurface: const Color(0xFFF3F4F6),
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 14. Neon Green (Glassmorphism)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static final _neonGreenLight = ColorScheme.fromSeed(
    seedColor: const Color(0xFF00FF87),
    brightness: Brightness.light,
  );
  static final _neonGreenDark = ColorScheme.fromSeed(
    seedColor: const Color(0xFF00FF87),
    brightness: Brightness.dark,
    surface: const Color(0xFF0A0A0E), // Very dark background
    primary: const Color(0xFF60FFB5), // Neon glowing green
    onSurface: const Color(0xFFF3F4F6),
  );
}
