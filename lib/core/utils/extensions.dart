import 'package:intl/intl.dart';

/// DateTime extensions for common formatting patterns.
extension DateTimeExtensions on DateTime {
  /// e.g. "Mar 28, 2026"
  String get formatted => DateFormat('MMM d, y').format(this);

  /// e.g. "09:30 AM"
  String get timeFormatted => DateFormat('hh:mm a').format(this);

  /// e.g. "Mar 28, 2026 at 09:30 AM"
  String get fullFormatted =>
      '${DateFormat('MMM d, y').format(this)} at ${DateFormat('hh:mm a').format(this)}';

  /// e.g. "Monday"
  String get dayName => DateFormat('EEEE').format(this);

  /// e.g. "Mon"
  String get shortDayName => DateFormat('E').format(this);

  /// e.g. "28"
  String get dayOfMonth => day.toString();

  /// Returns "Today", "Tomorrow", "Yesterday", or formatted date.
  String get relativeDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(year, month, day);

    if (date == today) return 'Today';
    if (date == today.add(const Duration(days: 1))) return 'Tomorrow';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return formatted;
  }

  /// Time ago string: "Just now", "5m ago", "2h ago", "3d ago", etc.
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatted;
  }

  /// Whether this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}

/// String extensions for common operations.
extension StringExtensions on String {
  /// Capitalize first letter.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Convert snake_case to Title Case.
  String get snakeToTitle =>
      split('_').map((w) => w.capitalized).join(' ');

  /// Truncate with ellipsis.
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}...';
}
