/// One order's warranty position, line by line — backend
/// `WarrantyEligibilityDto` / `WarrantyEligibilityItemDto`.
///
/// A warranty used to hang off an order line. A line for three identical
/// shirts is one row, so three garments shared one warranty and one claim
/// slot. Where a packer attached a marker to the physical goods, each unit now
/// carries its own clock, its own claim slot and its own eligibility row.
///
/// [WarrantyEligibilityItem.units] is empty for every line that carries no
/// marker, which is almost all stock and permanently so for anything sold
/// before markers existed. That is the right answer for those lines, not a
/// degraded one.
library;

/// Which recorded moment a coverage window was counted from — backend
/// `WarrantyClockBasis`, serialised by name.
///
/// Every member names a moment that is actually stored. There is deliberately
/// no member for "estimated", "assumed" or "order date": where neither moment
/// was recorded the basis is null, the start is null, and the UI says so
/// rather than substituting a date it does not have.
enum WarrantyClockBasis {
  /// The sub-order's confirmed delivery — what every warranty has always
  /// counted from, and what an unmarked item still counts from.
  subOrderDelivery('SubOrderDelivery', 'delivery'),

  /// The moment this unit's marker was attached as the goods changed hands.
  /// A pack-stage binding proves identity, not possession, so it never starts
  /// a clock on its own.
  unitHandover('UnitHandover', 'handover'),

  /// A basis this build does not know. Treated as unreadable rather than
  /// guessed into one of the others.
  unrecognised('', 'a recorded moment');

  const WarrantyClockBasis(this.wire, this.noun);

  final String wire;

  /// How the start is described in a sentence: "Cover started at handover".
  final String noun;

  /// Null in, null out. An absent basis is a fact about the record, not a
  /// value to be defaulted.
  static WarrantyClockBasis? fromJson(Object? raw) {
    if (raw == null) return null;
    final needle = raw.toString().toLowerCase();
    if (needle.isEmpty) return null;
    for (final value in values) {
      if (value != unrecognised && value.wire.toLowerCase() == needle) {
        return value;
      }
    }
    return unrecognised;
  }
}

/// One physical item on a line, identified by a marker somebody attached while
/// holding it — backend `WarrantyUnitEligibilityDto`.
///
/// [markerReference] is the non-secret `UM…` reference. The marker value
/// itself is stored only as a digest and is unreachable from this shape.
class WarrantyUnitEligibility {
  const WarrantyUnitEligibility({
    required this.unitMarkerBindingId,
    required this.markerReference,
    required this.inServiceSinceUtc,
    required this.isEligible,
    required this.statusExplanation,
    required this.hasOpenClaim,
    this.coverageStartsUtc,
    this.coverageEndsUtc,
    this.clockBasis,
  });

  final String unitMarkerBindingId;
  final String markerReference;
  final DateTime? inServiceSinceUtc;
  final bool isEligible;

  /// The backend's own sentence. Rendered verbatim — paraphrasing it here is
  /// how a screen ends up telling a buyer something that is not true.
  final String statusExplanation;
  final bool hasOpenClaim;

  /// Null when neither a delivery nor a handover binding was recorded. The UI
  /// must say the start is not recorded; it must never fall back to the order
  /// date, because a warranty with no start is not a warranty.
  final DateTime? coverageStartsUtc;
  final DateTime? coverageEndsUtc;

  /// Which of the two recorded moments [coverageStartsUtc] was counted from.
  /// Null alongside a null start, and the pair is rendered as absent.
  final WarrantyClockBasis? clockBasis;

  /// True only when the platform can say both *when* cover began and *what it
  /// counted from*. Anything less is not a coverage window.
  bool get hasRecordedStart => coverageStartsUtc != null && clockBasis != null;
}

/// One order line's warranty position — backend
/// `WarrantyEligibilityItemDto`.
///
/// Still exactly one row per line, as it has always been. When [units] is
/// non-empty the line-level fields describe the line *as a whole* and stay
/// computed exactly as before — [hasOpenClaim] remains "an open claim exists
/// somewhere on this line". The per-unit rows are the finer-grained truth, not
/// a restatement of the line.
class WarrantyEligibilityItem {
  const WarrantyEligibilityItem({
    required this.subOrderId,
    required this.subOrderLineId,
    required this.productVariantId,
    required this.title,
    required this.isEligible,
    required this.statusExplanation,
    required this.hasOpenClaim,
    required this.units,
    this.variantLabel,
    this.thumbnailUrl,
    this.coverageDays,
    this.terms,
    this.coverageStartsUtc,
    this.coverageEndsUtc,
  });

  final String subOrderId;
  final String subOrderLineId;
  final String productVariantId;
  final String title;
  final String? variantLabel;
  final String? thumbnailUrl;
  final bool isEligible;
  final String statusExplanation;
  final bool hasOpenClaim;
  final int? coverageDays;
  final String? terms;
  final DateTime? coverageStartsUtc;
  final DateTime? coverageEndsUtc;

  /// Empty for every line with no marker — almost all of them.
  final List<WarrantyUnitEligibility> units;

  /// True when this line's warranty resolves against physical items rather
  /// than against the line.
  bool get isUnitBound => units.isNotEmpty;
}

class WarrantyEligibility {
  const WarrantyEligibility({
    required this.orderNumber,
    required this.items,
    this.generatedUtc,
  });

  final String orderNumber;
  final DateTime? generatedUtc;
  final List<WarrantyEligibilityItem> items;

  /// The units bound to one order line, or empty when that line carries no
  /// marker. Empty is the common answer and means "this line's warranty is a
  /// line-level warranty", never "lookup failed".
  List<WarrantyUnitEligibility> unitsForLine(String subOrderLineId) {
    final needle = subOrderLineId.toLowerCase();
    if (needle.isEmpty) return const [];
    for (final item in items) {
      if (item.subOrderLineId.toLowerCase() == needle) return item.units;
    }
    return const [];
  }

  /// This order's warranty position for one line, or null when the report
  /// carries no row for it.
  ///
  /// Null here is "the platform has not told us about this line" — which is
  /// what a screen sees while the report loads and after it fails — and never
  /// "this line has no warranty". Those two readings look identical on screen
  /// unless a caller keeps them apart, so this returns the row rather than a
  /// flattened answer, and lets the caller render the row's own sentence.
  WarrantyEligibilityItem? itemForLine(String subOrderLineId) {
    final needle = subOrderLineId.toLowerCase();
    if (needle.isEmpty) return null;
    for (final item in items) {
      if (item.subOrderLineId.toLowerCase() == needle) return item;
    }
    return null;
  }
}
