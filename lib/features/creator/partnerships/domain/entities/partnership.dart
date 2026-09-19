/// Creator-side partnership entities.
///
/// ## Why there is no `totalEarned`, `totalSales` or `productsCount` here
///
/// These three fields existed and were **always zero**. `PartnershipDto`
/// hardcoded `Money(0)`, `0` and `0` in `toActiveDomain()` and
/// `toEndedDomain()`, and the active-partnerships card drew a literal `0`
/// for "Active Campaigns" on top of them. Every creator on StyleMint was
/// therefore told they had earned **Rs 0** from every brand they work with —
/// a false statement about their own money, made to the people whose money
/// it is.
///
/// They are gone rather than made nullable, because nothing on the platform
/// can fill them. Verified against `lead360` on 2026-09-20:
///
/// * **Earnings and sales per partnership are not recorded.** The system of
///   record for creator money is `StyleMint.Modules.Payouts`'
///   `EarningsLedgerEntry`, whose dimensions are payee, order, sub-order and
///   sub-order line. It has no vendor and no partnership column — the string
///   "partnership" does not occur anywhere in that module. A per-partnership
///   total could only be reconstructed by reaching into Orders' sub-order
///   shape to find each line's vendor, which is another module's internals
///   and not ours to read.
/// * `Partnerships`' own `AffiliateLink` *does* carry `PartnershipId`
///   alongside `TotalEarnings`, `TotalRevenue` and `TotalConversions`, and
///   its attribution is real (it runs off `orders.order.paid.v1` with the
///   order's true `GrandTotal`). But the single construction site,
///   `AffiliateService.CreateLinkAsync`, passes `partnershipId: null`. Every
///   link row in the system has a null partnership, so the column is dead
///   and the figure cannot be grouped by partnership even in principle.
/// * No endpoint exposes it. `GET /v1/partnerships/{id}/potential-earnings`
///   is a *projection at 50 hypothetical sales*, not money anyone earned;
///   `GET /v1/creator/affiliate/dashboard` is creator-wide, not per brand.
/// * **Products tagged** is genuinely recorded —
///   `Reels.TaggedProduct.PartnershipIdSnapshot` is set at tag time — but no
///   repository method counts by partnership and no endpoint returns it. It
///   needs a port and a route that do not exist; synthesising it here was
///   the bug.
/// * **Active campaigns** has no source at all. `Catalog.Campaign` is an
///   editorial Home/Discover hero, `BrandStudio.CampaignWorkspace` is
///   vendor-scoped with no creator or partnership link, and Partnerships'
///   `CampaignPrediction` / `CampaignInsurance` are a forecast and an
///   insurance policy. "Campaigns this creator is running under this
///   partnership" is not a thing the platform models.
///
/// A creator's real earnings are on the Earnings screen, which reads the
/// ledger directly. The card points there instead of inventing a number.
library;

/// Commission figures on these entities are **fractions**, matching the
/// wire: the server stores `CommissionRange` as `0.15 == 15%`
/// (`Partnerships/Entity/Partnership/CommissionRange.cs`). Read
/// [PartnershipInvite.commissionPercent] and friends when rendering, never
/// the raw rate — `0.15.round()` is `0`, which is how three screens came to
/// advertise "0% commissions" on partnerships that pay fifteen.
///
/// Rounded to two decimals: the server stores the fraction to four decimal
/// places, so two is every digit it can carry, and it keeps float noise off
/// the screen — `0.22 * 100` is `22.000000000000004`, which the "%.1f"
/// formatter on the requests screen would have rendered as "22.0%".
double _toPercent(double fraction) =>
    double.parse((fraction * 100).toStringAsFixed(2));

enum PartnershipStatus { pending, accepted, declined, expired, active }

class PartnershipInvite {
  const PartnershipInvite({
    required this.id,
    required this.vendorProfileId,
    this.vendorAccountId,
    required this.vendorName,
    required this.vendorLogoUrl,
    required this.campaignBrief,
    required this.commissionRate,
    this.commissionMax,
    required this.expiresAt,
    required this.status,
    this.vendorRating,
  });

  final String id;
  final String vendorProfileId;
  final String? vendorAccountId;
  final String vendorName;
  final String vendorLogoUrl;
  final String campaignBrief;

  /// Fraction, not percent — `0.15` is fifteen percent. Render
  /// [commissionPercent].
  final double commissionRate;

  /// Fraction, not percent. Render [commissionMaxPercent].
  final double? commissionMax;
  final DateTime expiresAt;
  final PartnershipStatus status;
  final double? vendorRating;

  /// [commissionRate] as a percent, for display.
  double get commissionPercent => _toPercent(commissionRate);

  /// [commissionMax] as a percent, for display. Null when the invite carries
  /// a single fixed rate.
  double? get commissionMaxPercent {
    final max = commissionMax;
    return max == null ? null : _toPercent(max);
  }

  PartnershipInvite copyWith({
    String? id,
    String? vendorProfileId,
    String? vendorName,
    String? vendorLogoUrl,
    String? campaignBrief,
    double? commissionRate,
    double? commissionMax,
    DateTime? expiresAt,
    PartnershipStatus? status,
    double? vendorRating,
  }) {
    return PartnershipInvite(
      id: id ?? this.id,
      vendorProfileId: vendorProfileId ?? this.vendorProfileId,
      vendorName: vendorName ?? this.vendorName,
      vendorLogoUrl: vendorLogoUrl ?? this.vendorLogoUrl,
      campaignBrief: campaignBrief ?? this.campaignBrief,
      commissionRate: commissionRate ?? this.commissionRate,
      commissionMax: commissionMax ?? this.commissionMax,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      vendorRating: vendorRating ?? this.vendorRating,
    );
  }
}

/// A partnership the creator is currently working under.
///
/// Carries only what the partnerships endpoint actually returns: who the
/// brand is, the agreed commission, and when it started. See the library
/// doc above for why there is no earnings, sales or product count.
class ActivePartnership {
  const ActivePartnership({
    required this.id,
    required this.vendorProfileId,
    this.vendorAccountId,
    required this.vendorName,
    required this.vendorLogoUrl,
    required this.commissionRate,
    required this.startedAt,
  });

  final String id;
  final String vendorProfileId;
  final String? vendorAccountId;
  final String vendorName;
  final String vendorLogoUrl;

  /// Fraction, not percent — `0.15` is fifteen percent. Render
  /// [commissionPercent].
  final double commissionRate;
  final DateTime startedAt;

  /// [commissionRate] as a percent, for display.
  double get commissionPercent => _toPercent(commissionRate);

  ActivePartnership copyWith({
    String? id,
    String? vendorProfileId,
    String? vendorName,
    String? vendorLogoUrl,
    double? commissionRate,
    DateTime? startedAt,
  }) {
    return ActivePartnership(
      id: id ?? this.id,
      vendorProfileId: vendorProfileId ?? this.vendorProfileId,
      vendorName: vendorName ?? this.vendorName,
      vendorLogoUrl: vendorLogoUrl ?? this.vendorLogoUrl,
      commissionRate: commissionRate ?? this.commissionRate,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}

/// A partnership that has ended. Same shape as [ActivePartnership] plus when
/// and why it closed.
class EndedPartnership {
  const EndedPartnership({
    required this.id,
    required this.vendorName,
    required this.vendorLogoUrl,
    required this.commissionRate,
    required this.startedAt,
    required this.endedAt,
    this.endReason,
  });

  final String id;
  final String vendorName;
  final String vendorLogoUrl;

  /// Fraction, not percent — `0.15` is fifteen percent. Render
  /// [commissionPercent].
  final double commissionRate;
  final DateTime startedAt;
  final DateTime endedAt;
  final String? endReason;

  /// [commissionRate] as a percent, for display.
  double get commissionPercent => _toPercent(commissionRate);
}
