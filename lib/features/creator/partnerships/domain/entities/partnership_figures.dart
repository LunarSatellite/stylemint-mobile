/// Per-partnership figures the server genuinely records — and the shape of
/// the absence where it does not.
///
/// Four figures were removed from the creator's brand cards on 2026-09-20
/// because nothing on the platform recorded them (see the library doc on
/// `partnership.dart`). Two of the four are now served:
///
/// * **Affiliate earnings per partnership** —
///   `GET /v1/creator/partnerships/{id}/affiliate-earnings`. Real, but only
///   for partnerships whose affiliate links carry a `PartnershipId`.
///   `AffiliateLink.PartnershipId` was null on every historic row and
///   **nothing was backfilled, deliberately**, so a partnership whose links
///   predate that change cannot be attributed and the server says so in
///   [AffiliateAttribution.unknown] rather than answering zero.
/// * **Products tagged** —
///   `GET /v1/creator/reels/tagged-products/by-partnership/{id}/count`. Real
///   for every partnership without exception: the snapshot
///   (`Reels.TaggedProduct.PartnershipIdSnapshot`) has been written at tag
///   time since tagging began, so **zero here is a recorded zero**.
///
/// The other two are still absent and stay absent. "Total sales" per brand
/// lives only in Payouts' `EarningsLedgerEntry`, which has no vendor and no
/// partnership dimension; "active campaigns per partnership" is not modelled
/// anywhere on the platform. Neither is defaulted, nulled into a dash, or
/// given a slot on the card.
///
/// ## The one distinction this file exists to keep
///
/// `Unknown` and a recorded `0` are **not the same answer** and must never
/// render the same way. `Unknown` means *nobody looked and nobody can*;
/// `TotalEarnings: 0` under [AffiliateAttribution.attributed] means *we
/// looked, and the answer is nothing*. Collapsing them undoes the whole
/// point of the contract — it is the fabricated-zero defect in a new coat.
library;

/// Whether the server could attribute affiliate activity to one partnership.
enum AffiliateAttribution {
  /// No affiliate link carries this partnership, so no total can be claimed.
  /// Every figure on [PartnershipAffiliateEarnings] is null in this state and
  /// the UI must draw no numeral for any of them.
  unknown,

  /// Links were attributed to this partnership. Every total is a **recorded**
  /// figure, zero included.
  attributed,
}

/// What `GET /v1/creator/partnerships/{id}/affiliate-earnings` recorded.
class PartnershipAffiliateEarnings {
  const PartnershipAffiliateEarnings({
    required this.attribution,
    required this.currencies,
    required this.unattributedLinkCountForPair,
    this.totalEarnings,
    this.totalRevenue,
    this.totalConversions,
    this.totalClicks,
  });

  /// The honest fallback: nothing attributed, nothing claimed.
  const PartnershipAffiliateEarnings.notAttributed({
    this.unattributedLinkCountForPair = 0,
  }) : attribution = AffiliateAttribution.unknown,
       currencies = const <String>[],
       totalEarnings = null,
       totalRevenue = null,
       totalConversions = null,
       totalClicks = null;

  final AffiliateAttribution attribution;

  /// The currencies the totals were summed across.
  ///
  /// **Empty** when there were no conversions at all. **More than one entry
  /// means the totals span currencies**, which no single amount can honestly
  /// represent — see [spansMultipleCurrencies]; the UI must break the figure
  /// out rather than print one number.
  final List<String> currencies;

  /// Affiliate links between this same creator and vendor that carry **no**
  /// partnership at all.
  ///
  /// A completeness signal, not an attribution claim: it explains why
  /// [AffiliateAttribution.unknown] is honest rather than lazy. These links
  /// are **not** this partnership's earnings and must never be presented as
  /// such, nor as belonging to this brand's partnership.
  final int unattributedLinkCountForPair;

  /// Null in [AffiliateAttribution.unknown]. Under
  /// [AffiliateAttribution.attributed] a `0` is a **recorded** zero.
  final double? totalEarnings;

  /// Null in [AffiliateAttribution.unknown]. Order value attributed to the
  /// links, not the creator's cut.
  final double? totalRevenue;

  /// Null in [AffiliateAttribution.unknown].
  final int? totalConversions;

  /// Null in [AffiliateAttribution.unknown].
  final int? totalClicks;

  bool get isAttributed => attribution == AffiliateAttribution.attributed;

  /// True when the totals were summed across more than one currency. One
  /// amount cannot stand for them, so none is drawn.
  bool get spansMultipleCurrencies => currencies.length > 1;

  /// The single currency the totals are in, or null when there are none
  /// (no conversions) or several (see [spansMultipleCurrencies]).
  String? get singleCurrency =>
      currencies.length == 1 ? currencies.first : null;

  /// True only when one amount can be drawn without inventing a currency.
  bool get hasSingleCurrencyAmount =>
      isAttributed && totalEarnings != null && singleCurrency != null;
}

/// What
/// `GET /v1/creator/reels/tagged-products/by-partnership/{id}/count`
/// recorded. Every field is real for every partnership, and **zero is a
/// zero** — the snapshot is written at tag time, so an empty count means the
/// creator tagged nothing under this partnership, not that nobody looked.
/// The response also carries a count of the reels those tags sit in and a
/// count of the tag rows themselves. Neither is parsed: nothing reads them,
/// and a figure parsed without a reader is the first half of a figure
/// rendered without a source. "Products tagged" is the count the card asks
/// for, and the only one taken.
class PartnershipTagCounts {
  const PartnershipTagCounts({required this.productCount});

  /// Distinct products tagged under this partnership. A zero is recorded.
  final int productCount;
}
