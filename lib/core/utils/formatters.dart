import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  /// Format currency (USD)
  static String currency(double amount) {
    return NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount);
  }

  /// Format currency with decimals
  static String currencyDecimal(double amount) {
    return NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }

  /// Format compact number (e.g., 1.2K, 3.4M)
  static String compactNumber(num number) {
    return NumberFormat.compact().format(number);
  }

  /// Format compact currency
  static String compactCurrency(num amount) {
    return NumberFormat.compactCurrency(
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount);
  }

  /// Format percentage
  static String percentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format duration from minutes
  static String duration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  /// Format duration from seconds
  static String durationFromSeconds(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Format file size
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
