import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

extension ContextExtensions on BuildContext {
  /// Quick access to theme
  ThemeData get theme => Theme.of(this);

  /// Quick access to color scheme
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Quick access to status colors
  AppStatusColors get statusColors => Theme.of(this).extension<AppStatusColors>()!;

  /// Quick access to text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Screen dimensions
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Check if device is tablet (width >= 600)
  bool get isTablet => screenWidth >= 600;

  /// Check if landscape
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// Padding
  EdgeInsets get padding => MediaQuery.paddingOf(this);

  /// Show snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colors.error : colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  /// Show success snackbar
  void showSuccess(String message) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: statusColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
