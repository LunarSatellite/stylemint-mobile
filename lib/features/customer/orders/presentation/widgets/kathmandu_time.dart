import 'package:intl/intl.dart';

/// Nepal Time is a fixed UTC+05:45 with no daylight saving, so a constant
/// offset is exact and doesn't depend on the timezone database being loaded.
const Duration _nptOffset = Duration(hours: 5, minutes: 45);

/// [instant] as a wall-clock time in Asia/Kathmandu. The result is only for
/// formatting; its `isUtc` flag is meaningless.
DateTime toKathmandu(DateTime instant) => instant.toUtc().add(_nptOffset);

/// "Tue 15 Sep, 2:05 PM" in Asia/Kathmandu.
String formatNptDateTime(DateTime instant) =>
    DateFormat('EEE d MMM, h:mm a').format(toKathmandu(instant));

/// "Thu 17 Sep" in Asia/Kathmandu.
String formatNptWeekday(DateTime instant) =>
    DateFormat('EEE d MMM').format(toKathmandu(instant));

/// "13 Sep 2026" in Asia/Kathmandu.
String formatNptDate(DateTime instant) =>
    DateFormat('d MMM yyyy').format(toKathmandu(instant));
