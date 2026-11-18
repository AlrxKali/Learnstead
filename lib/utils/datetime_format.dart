/// Small date/time formatters shared across screens.
library;

const monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const weekdayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday',
];

/// "JAN", "FEB", …
String monthAbbr(DateTime d) =>
    monthNames[d.month - 1].substring(0, 3).toUpperCase();

/// "3:05 PM"
String formatTime(DateTime dt) {
  final h = dt.hour;
  final m = dt.minute.toString().padLeft(2, '0');
  final period = h >= 12 ? 'PM' : 'AM';
  final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
  return '$hour12:$m $period';
}

/// "10:00 AM – 12:00 PM"
String formatTimeRange(DateTime start, DateTime end) =>
    '${formatTime(start)} – ${formatTime(end)}';

/// "Wednesday, November 18"
String formatLongDate(DateTime d) =>
    '${weekdayNames[d.weekday - 1]}, ${monthNames[d.month - 1]} ${d.day}';

/// "Nov 18" (adds the year when it isn't the current one).
String formatShortDate(DateTime d) {
  final m = monthNames[d.month - 1].substring(0, 3);
  return d.year == DateTime.now().year ? '$m ${d.day}' : '$m ${d.day}, ${d.year}';
}

/// "now" / "5m ago" / "2h ago" / "3d ago" / "Nov 18"
String formatTimeAgo(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatShortDate(t);
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
