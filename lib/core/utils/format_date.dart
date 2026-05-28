import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

void initTimezone() => tz_data.initializeTimeZones();

/// Relative time — "2h ago", "3d ago", etc.
String formatRelative(DateTime iso) {
  final diff = DateTime.now().difference(iso);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1)   return '${diff.inMinutes}m ago';
  if (diff.inDays < 1)    return '${diff.inHours}h ago';
  if (diff.inDays < 7)    return '${diff.inDays}d ago';
  return DateFormat.yMMMd().format(iso.toLocal());
}

/// Display in user's local timezone.
String formatDateTime(DateTime iso, {String? localeTag}) =>
    DateFormat.yMd(localeTag).add_jm().format(iso.toLocal());

/// Ops-context — always show in NPT (Asia/Kathmandu, UTC+5:45).
String formatInNpt(DateTime iso) {
  final npt = tz.getLocation('Asia/Kathmandu');
  final zoned = tz.TZDateTime.from(iso, npt);
  return '${DateFormat.yMd().add_jm().format(zoned)} NPT';
}
