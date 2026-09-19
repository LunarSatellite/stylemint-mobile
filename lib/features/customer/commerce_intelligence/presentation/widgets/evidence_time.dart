import 'package:intl/intl.dart';

/// Plain-language time for evidence.
///
/// Everything here formats a timestamp the backend sent. Nothing here infers
/// recency, freshness or staleness as a *claim* — the one comparison made is
/// between the backend's own `asOfUtc` and the device clock, and it is
/// spoken as "as things stood on `<date>`", never as "out of date".
abstract final class EvidenceTime {
  /// Older than this and the as-of moment is worth naming as the past.
  static const Duration historicalAfter = Duration(hours: 12);

  /// `19 Sep 2026 at 2:32 PM` in the reader's own zone.
  static String moment(DateTime utc) =>
      DateFormat.yMMMd().add_jm().format(utc.toLocal());

  /// `19 Sep 2026` in the reader's own zone.
  static String day(DateTime utc) => DateFormat.yMMMd().format(utc.toLocal());

  /// The sentence that sits under the answer.
  ///
  /// [now] is injectable so a test never depends on the wall clock.
  static String asOfSentence(DateTime asOfUtc, {DateTime? now}) {
    final reference = (now ?? DateTime.now()).toUtc();
    final age = reference.difference(asOfUtc.toUtc());
    if (age >= historicalAfter) {
      return 'This is how things stood on ${moment(asOfUtc)}, '
          'not necessarily how they stand now.';
    }
    if (age.isNegative && age.abs() > const Duration(minutes: 5)) {
      // The server clamps a future as-of, so this only happens when the two
      // clocks disagree. Say the moment and claim nothing about "now".
      return 'Evidence selected as of ${moment(asOfUtc)}.';
    }
    return 'Evidence as it stood at ${moment(asOfUtc)}.';
  }

  /// The validity window of one fact, or null when the backend sent none.
  static String? validity({
    required DateTime? validFromUtc,
    required DateTime? validToUtc,
  }) {
    if (validFromUtc == null && validToUtc == null) return null;
    if (validFromUtc != null && validToUtc != null) {
      return 'True from ${day(validFromUtc)} until ${day(validToUtc)}';
    }
    if (validFromUtc != null) return 'True since ${day(validFromUtc)}';
    return 'True until ${day(validToUtc!)}';
  }

  /// When the fact was recorded, or null when the backend sent nothing.
  static String? observed(DateTime? observedUtc) =>
      observedUtc == null ? null : 'Recorded ${moment(observedUtc)}';

  /// `within 5 days`, or null when the forecast carries no horizon.
  static String? horizon(int days) {
    if (days <= 0) return null;
    if (days == 1) return 'within 1 day';
    return 'within $days days';
  }
}
