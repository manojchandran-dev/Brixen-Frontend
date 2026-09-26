const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Time-of-day greeting with no trailing punctuation — callers add their
/// own ("," or "!") to match their own copy.
String greetingPrefix() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

/// e.g. "Monday, 3 Sep 2026" (default separator) or with `\n` for a
/// two-line header.
String weekdayDateLabel(DateTime d, {String separator = ', '}) {
  return '${_weekdayNames[d.weekday - 1]}$separator${d.day} ${_monthNames[d.month - 1]} ${d.year}';
}

/// Formats a date as `yyyy-MM-dd` for query params that expect an ISO date
/// (not a full timestamp) — e.g. `from`/`to` on sales, expenses and reports.
String toIsoDateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
