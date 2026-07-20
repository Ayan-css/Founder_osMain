import 'package:intl/intl.dart';

extension DateExtensions on DateTime {
  /// Format as "Jan 15, 2025"
  String get formatted => DateFormat('MMM d, y').format(this);

  /// Format as "January 15, 2025"
  String get formattedLong => DateFormat('MMMM d, y').format(this);

  /// Format as "15/01/2025"
  String get formattedShort => DateFormat('dd/MM/y').format(this);

  /// Format as "3:30 PM"
  String get formattedTime => DateFormat('h:mm a').format(this);

  /// Format as "Jan 15, 3:30 PM"
  String get formattedWithTime => DateFormat('MMM d, h:mm a').format(this);

  /// Format as "Monday, January 15"
  String get formattedDay => DateFormat('EEEE, MMMM d').format(this);

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Check if date is this week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Check if date is this month
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Human-readable relative time
  String get relative {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';
    final diff = difference(DateTime.now());
    if (diff.inDays.abs() < 7) {
      return diff.isNegative
          ? '${diff.inDays.abs()} days ago'
          : 'in ${diff.inDays} days';
    }
    return formatted;
  }

  /// Start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// End of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  /// Start of month
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// End of month
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59);

  /// Start of year
  DateTime get startOfYear => DateTime(year, 1, 1);
}
