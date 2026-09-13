import 'package:flutter/foundation.dart';

/// Fewest and most sponsored views a day the backend accepts
/// (`SponsoredListing.MinDailyImpressions` / `MaxDailyImpressions`).
const int minDailyImpressionCap = 10;
const int maxDailyImpressionCap = 10000;

/// Whether the vendor has the sponsorship switched on. Backend
/// `SponsoredListingState`: Active=1, Paused=2.
enum SponsoredListingState {
  active,
  paused,

  /// A state this app version doesn't know yet.
  unknown,
}

/// What the vendor sees on the sponsorship's chip.
enum SponsorshipStatus {
  /// Running now: switched on and not past its end date.
  live,

  /// Switched off by the vendor.
  paused,

  /// Still switched on, but its end date has passed.
  ended,
}

/// Voyager "Transparent Sponsored Product Boosting": one of the vendor's
/// sponsored products with what it has done — how often it was shown and how
/// sales moved against the week before. Backend `SponsoredListingDto`.
@immutable
class SponsoredListing {
  const SponsoredListing({
    required this.id,
    required this.productId,
    required this.productName,
    required this.state,
    required this.isLive,
    required this.dailyImpressionCap,
    this.endsUtc,
    this.impressionsToday = 0,
    this.impressionsLast7Days = 0,
    this.unitsSoldLast7Days = 0,
    this.unitsSoldPrevious7Days = 0,
    this.disclosure = '',
    this.salesComparisonNote = '',
    this.createdUtc,
    this.updatedUtc,
  });

  final String id;
  final String productId;
  final String productName;
  final SponsoredListingState state;

  /// The backend's own answer to "is it running right now".
  final bool isLive;

  /// Most times a day search may show it in the sponsored slot.
  final int dailyImpressionCap;

  /// When it stops by itself; null runs until paused.
  final DateTime? endsUtc;
  final int impressionsToday;
  final int impressionsLast7Days;
  final int unitsSoldLast7Days;
  final int unitsSoldPrevious7Days;

  /// How shoppers see the placement, in the backend's words.
  final String disclosure;

  /// Why the before/after sales figures are a guide, not proof.
  final String salesComparisonNote;
  final DateTime? createdUtc;
  final DateTime? updatedUtc;

  SponsorshipStatus get status {
    if (state == SponsoredListingState.paused) return SponsorshipStatus.paused;
    return isLive ? SponsorshipStatus.live : SponsorshipStatus.ended;
  }

  @override
  bool operator ==(Object other) =>
      other is SponsoredListing &&
      other.id == id &&
      other.productId == productId &&
      other.productName == productName &&
      other.state == state &&
      other.isLive == isLive &&
      other.dailyImpressionCap == dailyImpressionCap &&
      other.endsUtc == endsUtc &&
      other.impressionsToday == impressionsToday &&
      other.impressionsLast7Days == impressionsLast7Days &&
      other.unitsSoldLast7Days == unitsSoldLast7Days &&
      other.unitsSoldPrevious7Days == unitsSoldPrevious7Days &&
      other.disclosure == disclosure &&
      other.salesComparisonNote == salesComparisonNote &&
      other.createdUtc == createdUtc &&
      other.updatedUtc == updatedUtc;

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    productName,
    state,
    isLive,
    dailyImpressionCap,
    endsUtc,
    impressionsToday,
    impressionsLast7Days,
    unitsSoldLast7Days,
    unitsSoldPrevious7Days,
    disclosure,
    salesComparisonNote,
    createdUtc,
    updatedUtc,
  );
}

/// The product a sponsor form is for.
@immutable
class SponsorProductTarget {
  const SponsorProductTarget({
    required this.productId,
    required this.productName,
  });

  final String productId;
  final String productName;

  @override
  bool operator ==(Object other) =>
      other is SponsorProductTarget &&
      other.productId == productId &&
      other.productName == productName;

  @override
  int get hashCode => Object.hash(productId, productName);
}

/// The last full day a sponsorship runs, in the vendor's time zone. The form
/// saves an end date as midnight after the chosen day, so that moment minus a
/// tick lands back on the chosen day.
DateTime sponsorshipLastDay(DateTime endsUtc) {
  final local = endsUtc.toLocal().subtract(const Duration(microseconds: 1));
  return DateTime(local.year, local.month, local.day);
}

/// The moment a sponsorship chosen to run through [lastDay] stops: the start
/// of the next local day.
DateTime sponsorshipEndsAfter(DateTime lastDay) =>
    DateTime(lastDay.year, lastDay.month, lastDay.day + 1);
