import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/core/utils/media_urls.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel_journey.dart';

/// `journeys[0]` of a reel (journey reels contract v1 §2), or null when the
/// field is missing, empty or unreadable — an ordinary reel.
///
/// A journey with fewer than two readable steps is dropped as well: there is
/// nothing to swipe to, and the reel should look exactly like any other.
ReelJourney? readFirstReelJourney(Object? raw) {
  if (raw is! List || raw.isEmpty) return null;
  final first = raw.first;
  if (first is! Map) return null;
  final journey = readReelJourney(Map<String, dynamic>.from(first));
  return journey != null && journey.isSwipeable ? journey : null;
}

/// One `ReelJourneyDto`, or null without a journey id.
ReelJourney? readReelJourney(Map<String, dynamic> json) {
  final id = readString(json['journeyId'] ?? json['id']);
  if (id.isEmpty) return null;
  final steps = readJourneySteps(json['steps']);
  final count = json['stepCount'];
  return ReelJourney(
    journeyId: id,
    title: readOptionalString(json['title']),
    city: readOptionalString(json['city']),
    stepIndex: readInt(json['stepIndex']),
    stepCount: count is num ? count.toInt() : null,
    prevReelId: readOptionalString(json['prevReelId']),
    nextReelId: readOptionalString(json['nextReelId']),
    steps: steps,
  );
}

/// The steps, ordered by `index` (then as sent). A step without a reel id
/// is skipped: it has nothing to show.
List<ReelJourneyStep> readJourneySteps(Object? raw) {
  if (raw is! List) return const [];
  final steps = <ReelJourneyStep>[];
  for (final row in raw) {
    if (row is! Map) continue;
    final reelId = readString(row['reelId']);
    if (reelId.isEmpty) continue;
    final logo = readOptionalString(row['vendorLogoUrl']);
    final thumb = readOptionalString(row['thumbnailUrl']);
    steps.add(
      ReelJourneyStep(
        stepId: readString(row['stepId'] ?? row['id']),
        index: readInt(row['index']),
        vendorAccountId: readString(row['vendorAccountId']),
        vendorName: readString(row['vendorName']),
        vendorLogoUrl: logo == null ? null : absoluteMediaUrl(logo),
        reelId: reelId,
        thumbnailUrl: thumb == null ? null : absoluteMediaUrl(thumb),
      ),
    );
  }
  final ordered = [
    for (var i = 0; i < steps.length; i++) (i, steps[i]),
  ]..sort((a, b) {
      final byIndex = a.$2.index.compareTo(b.$2.index);
      return byIndex != 0 ? byIndex : a.$1.compareTo(b.$1);
    });
  return List.unmodifiable([for (final (_, step) in ordered) step]);
}
