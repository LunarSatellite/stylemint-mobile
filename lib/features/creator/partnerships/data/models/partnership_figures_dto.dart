import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership_figures.dart';

/// Wire shapes for the two per-partnership figures the backend now records.
///
/// Hand-written rather than freezed, matching `brand_partnership_record_dto`
/// next door: both parse a contract whose whole point is *which fields are
/// absent*, and a `@Default` on a nullable total is exactly the fabrication
/// these endpoints exist to avoid.
///
/// ## `PartnershipAffiliateEarningsDto`
///
/// `GET /v1/creator/partnerships/{partnershipId}/affiliate-earnings`.
///
/// ```json
/// {
///   "attribution": "Unknown" | "Attributed",
///   "totalEarnings": 1250.0,
///   "totalRevenue": 12000.0,
///   "totalConversions": 3,
///   "totalClicks": 87,
///   "currencies": ["NPR"],
///   "unattributedLinkCountForPair": 2
/// }
/// ```
///
/// The four totals are **all null when `attribution` is `"Unknown"`**, and
/// this parser keeps them null rather than reaching for a fallback. Under
/// `"Attributed"` they are real, and `"totalEarnings": 0` is a **recorded**
/// zero that must reach the screen as one.
///
/// An `attribution` this client does not recognise parses as
/// [AffiliateAttribution.unknown]. That is the safe direction: a new wire
/// value makes the card say "not tracked", never invent a total.
class PartnershipAffiliateEarningsDto {
  const PartnershipAffiliateEarningsDto({
    required this.attribution,
    required this.currencies,
    required this.unattributedLinkCountForPair,
    this.totalEarnings,
    this.totalRevenue,
    this.totalConversions,
    this.totalClicks,
  });

  factory PartnershipAffiliateEarningsDto.fromJson(Map<String, dynamic> json) {
    return PartnershipAffiliateEarningsDto(
      attribution: (json['attribution'] as String?) ?? '',
      currencies:
          (json['currencies'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList(growable: false),
      // A count, not a total: it is present in both attribution states and
      // its absence genuinely means "none", so an absent key is none.
      unattributedLinkCountForPair:
          (json['unattributedLinkCountForPair'] as num?)?.toInt() ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble(),
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble(),
      totalConversions: (json['totalConversions'] as num?)?.toInt(),
      totalClicks: (json['totalClicks'] as num?)?.toInt(),
    );
  }

  /// The raw wire string, kept verbatim so [toDomain] owns the only mapping.
  final String attribution;
  final List<String> currencies;
  final int unattributedLinkCountForPair;
  final double? totalEarnings;
  final double? totalRevenue;
  final int? totalConversions;
  final int? totalClicks;

  PartnershipAffiliateEarnings toDomain() {
    if (attribution.toLowerCase() != 'attributed') {
      return PartnershipAffiliateEarnings.notAttributed(
        unattributedLinkCountForPair: unattributedLinkCountForPair,
      );
    }
    return PartnershipAffiliateEarnings(
      attribution: AffiliateAttribution.attributed,
      currencies: currencies,
      unattributedLinkCountForPair: unattributedLinkCountForPair,
      totalEarnings: totalEarnings,
      totalRevenue: totalRevenue,
      totalConversions: totalConversions,
      totalClicks: totalClicks,
    );
  }
}

/// `GET /v1/creator/reels/tagged-products/by-partnership/{id}/count`.
///
/// The payload carries the partnership id, a count of distinct products, a
/// count of the reels the tags sit in and a count of the tag rows. Only the
/// product count is parsed — see [PartnershipTagCounts] for why the other
/// three are left on the wire.
///
/// Unlike the earnings contract there is no unknown state here: the
/// partnership id has been snapshotted on every tag row since tagging began,
/// so a missing key really does mean none were tagged.
class PartnershipTagCountsDto {
  const PartnershipTagCountsDto({required this.productCount});

  factory PartnershipTagCountsDto.fromJson(Map<String, dynamic> json) {
    return PartnershipTagCountsDto(
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
    );
  }

  final int productCount;

  PartnershipTagCounts toDomain() =>
      PartnershipTagCounts(productCount: productCount);
}
