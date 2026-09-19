import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// The commission a creator actually earns on one product, from
/// `GET /v1/creator/tag-products/commission`.
///
/// ## What this replaced
///
/// The Tag Products screen used to compute its own rate: `const pct = 10`,
/// in two `_commissionLabel()` methods, rendered as
/// `Est. 10% commission (~Rs 450 per sale)` to a creator deciding which
/// products to tag. Ten percent was not a rate anybody had agreed to. The
/// real rate is a term of that creator's partnership with the product's
/// vendor, and it is now looked up.
///
/// ## The two zero-shaped answers, which are not the same answer
///
/// * [TagProductCommissionStatus.applies] with
///   a `CommissionRateFraction` of `0` is a **recorded zero**: there is a
///   partnership, and its agreed rate is nought percent. It renders as
///   "0% commission".
/// * [TagProductCommissionStatus.noPartnership] is **absence**: no
///   partnership covers this product, so no rate exists to state. It renders
///   as "No commission applies" and draws no numeral.
///
/// The server says this twice — once in the status name, once in null versus
/// zero — precisely so the client cannot collapse them. Collapsing them is
/// the same defect as the fabricated "Rs 0" this codebase has already fixed
/// once, and it would be introduced here by treating a null rate as zero or
/// a zero rate as nothing.
enum TagProductCommissionStatus {
  /// A partnership covers this product and its rate is stated.
  applies,

  /// No partnership covers it. Every rate field is null; nothing is claimed.
  noPartnership,

  /// The product could not be resolved. **Assert nothing** about it.
  productUnavailable,
}

class TagProductCommission {
  const TagProductCommission({
    required this.productId,
    required this.status,
    this.partnershipId,
    this.commissionRateFraction,
    this.commissionRateMinFraction,
    this.commissionRateMaxFraction,
    this.productVariantId,
    this.unitPrice,
    this.commissionPerSale,
  });

  final String productId;
  final TagProductCommissionStatus status;
  final String? partnershipId;

  /// A **fraction**, matching the wire: `0.15` is fifteen percent. Never
  /// render it raw and never call `.round()` on it — `0.15.round()` is `0`,
  /// which is how a partnership paying fifteen percent came to advertise
  /// "0% commissions". Render [commissionPercentLabel].
  final double? commissionRateFraction;

  /// The band the partnership was agreed within, also fractions.
  final double? commissionRateMinFraction;
  final double? commissionRateMaxFraction;

  final String? productVariantId;
  final Money? unitPrice;

  /// The money per sale, as the server computed it. Rendered **verbatim** —
  /// the client does no arithmetic on it, because a rounding difference
  /// between what the app shows and what the ledger pays is a lie about
  /// someone's income.
  final Money? commissionPerSale;

  bool get applies => status == TagProductCommissionStatus.applies;

  /// [commissionRateFraction] as a display percent: "15%", "12.5%", "0%".
  ///
  /// Scaled by 100 and trimmed of trailing zeros — never rounded to a whole
  /// number, so a 12.5% term reads as 12.5% and a 0% term reads as 0%
  /// rather than disappearing.
  String? get commissionPercentLabel {
    final fraction = commissionRateFraction;
    if (fraction == null) return null;
    final percent = fraction * 100;
    final trimmed = percent
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    return '$trimmed%';
  }
}
