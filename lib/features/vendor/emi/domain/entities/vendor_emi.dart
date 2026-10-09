import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_quote.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// `VendorEmiTermsDto` — one listing's EMI terms as the vendor set them, with
/// what the server worked out from them.
class VendorEmiTerms {
  const VendorEmiTerms({
    required this.productId,
    required this.enabled,
    required this.minDownPaymentPercent,
    required this.effectiveMinDownPaymentPercent,
    required this.tenures,
    this.productName = '',
    this.interestRatePercentMonthly = 0,
    this.approvalMode = 'Manual',
    this.eligibleVariantCount = 0,
    this.minimumPrice,
    this.sampleQuote,
    this.updatedUtc,
  });

  final String productId;
  final String productName;
  final bool enabled;

  /// What the vendor chose.
  final int minDownPaymentPercent;

  /// What buyers actually get: the vendor's choice, raised to 20 % and to
  /// cover StyleMint's commission (`roundUpTo5(commission + 5)`) when either
  /// is higher.
  final int effectiveMinDownPaymentPercent;
  final List<int> tenures;
  final double interestRatePercentMonthly;
  final String approvalMode;

  /// Variants priced at or above [minimumPrice].
  final int eligibleVariantCount;
  final Money? minimumPrice;

  /// The lowest eligible variant at the effective minimum over the longest
  /// tenure. Null when nothing qualifies.
  final EmiQuote? sampleQuote;
  final DateTime? updatedUtc;

  /// The commission rule (or the 20 % floor) raised the vendor's minimum.
  bool get minimumWasRaised =>
      effectiveMinDownPaymentPercent > minDownPaymentPercent;
}

/// `GET|PUT /v1/vendor/emi/settings`.
class VendorEmiSettings {
  const VendorEmiSettings({required this.maxExposureLimit, this.exposureLimit});

  /// The total the vendor lets buyers owe them. Null means not set.
  final Money? exposureLimit;

  /// StyleMint's ceiling for [exposureLimit] (default NPR 500,000).
  final Money maxExposureLimit;
}
