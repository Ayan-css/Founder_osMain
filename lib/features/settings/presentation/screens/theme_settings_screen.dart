import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/app_theme.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final themeState = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Theme')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme mode selector
          Text('Mode', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode, size: 18)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode, size: 18)),
              ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.settings_brightness, size: 18)),
            ],
            selected: {themeState.themeMode},
            onSelectionChanged: (v) => ref.read(themeNotifierProvider.notifier).setThemeMode(v.first),
          ),
          const SizedBox(height: 24),

          // Theme selection grid
          Text('Color Themes', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...AppThemeId.values.map((id) {
            final isSelected = themeState.themeId == id;
            final previewColors = _themePreviewColors(id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isSelected ? BorderSide(color: colors.primary, width: 2) : BorderSide.none,
                ),
                child: InkWell(
                  onTap: () => ref.read(themeNotifierProvider.notifier).setTheme(id),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      // Color preview
                      Row(children: previewColors.map((c) =>
                        Container(width: 24, height: 24, margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
                      ).toList()),
                      const SizedBox(width: 16),
                      // Name
                      Expanded(child: Text(id.displayName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500))),
                      // Check
                      if (isSelected) Icon(Icons.check_circle, color: colors.primary, size: 22),
                    ]),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Color> _themePreviewColors(AppThemeId id) {
    switch (id) {
      case AppThemeId.neonPurple: return [const Color(0xFFE0B0FF), const Color(0xFF0F0F14), const Color(0xFF9D4EDD)];
      case AppThemeId.neonBlue: return [const Color(0xFF00E5FF), const Color(0xFF0A0F1F), const Color(0xFF0077B6)];
      case AppThemeId.neonGreen: return [const Color(0xFF00FF7F), const Color(0xFF0B1F15), const Color(0xFF2D6A4F)];
      case AppThemeId.darkProfessional: return [const Color(0xFF6366F1), const Color(0xFF0F0F14), const Color(0xFFE8E8ED)];
      case AppThemeId.lightProfessional: return [const Color(0xFF3B82F6), const Color(0xFFFAFAFC), const Color(0xFF1E293B)];
      case AppThemeId.midnightBlue: return [const Color(0xFF1E3A5F), const Color(0xFF0A1628), const Color(0xFF5B9BD5)];
      case AppThemeId.forestGreen: return [const Color(0xFF2D6A4F), const Color(0xFF0B1F15), const Color(0xFF52B788)];
      case AppThemeId.royalPurple: return [const Color(0xFF7C3AED), const Color(0xFF120B24), const Color(0xFFA78BFA)];
      case AppThemeId.maroonBeige: return [const Color(0xFF8B2252), const Color(0xFF1A0E14), const Color(0xFFF5E6D3)];
      case AppThemeId.blackGold: return [const Color(0xFFDAA520), const Color(0xFF0C0C0C), const Color(0xFFFFD700)];
      case AppThemeId.oceanBlue: return [const Color(0xFF0077B6), const Color(0xFF041C2C), const Color(0xFF48CAE4)];
      case AppThemeId.minimalGray: return [const Color(0xFF475569), const Color(0xFF0F1419), const Color(0xFF94A3B8)];
      case AppThemeId.highContrast: return [const Color(0xFF0000CC), Colors.black, Colors.white];
      case AppThemeId.monochromatic: return [Colors.black, Colors.white, const Color(0xFFFF0000)];
    }
  }
}
