import 'package:intl/intl.dart';

/// Service vendors work on Kathmandu time (UTC+5:45, no daylight saving):
/// "today's arrivals", "tonight" and "today's appointments" are Kathmandu
/// calendar days whatever the phone's own time zone is.
const Duration kathmanduOffset = Duration(hours: 5, minutes: 45);

/// Today's date in Kathmandu, as a date-only local value.
DateTime serviceToday([DateTime? nowUtc]) {
  final npt = (nowUtc ?? DateTime.now()).toUtc().add(kathmanduOffset);
  return DateTime(npt.year, npt.month, npt.day);
}

/// A calendar date as the wire wants it: `2026-10-21`.
String wireDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// A wire `date` (`2026-10-21`) as a date-only local value; null when
/// missing or unreadable. Never shifted by a time zone.
DateTime? readWireDate(Object? raw) {
  if (raw is! String) return null;
  final text = raw.trim();
  if (text.length < 10) return null;
  final parsed = DateTime.tryParse(text.substring(0, 10));
  return parsed == null ? null : DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// "21 Oct 2026" — the contract's own date wording.
String serviceDateText(DateTime date) => DateFormat('d MMM yyyy').format(date);

/// "Tue 21 Oct".
String serviceShortDateText(DateTime date) =>
    DateFormat('EEE d MMM').format(date);

/// "Today", "Tomorrow", "Yesterday", else "Tue 21 Oct".
String serviceRelativeDay(DateTime date, DateTime today) =>
    switch (daysBetween(today, date)) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ => serviceShortDateText(date),
    };

/// An instant shown on the Kathmandu clock: "21 Oct 2026, 10:00".
String serviceInstantText(DateTime instant) {
  final npt = instant.toUtc().add(kathmanduOffset);
  final local = DateTime(npt.year, npt.month, npt.day, npt.hour, npt.minute);
  return DateFormat('d MMM yyyy, HH:mm').format(local);
}
