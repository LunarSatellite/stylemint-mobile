import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/entities/customer_kyc.dart';

/// The `reasons` values of `GET /v1/customer/emi/eligibility`.
abstract final class EmiIneligibleReason {
  static const kycRequired = 'kyc_required';
  static const kycInReview = 'kyc_in_review';
  static const kycRejected = 'kyc_rejected';
}

/// What the calculator's button offers the buyer.
enum EmiCta {
  /// Not signed in: sign in first.
  signIn,

  /// KYC needed or rejected: "Get verified for EMI".
  getVerified,

  /// KYC sent and waiting: "Verification in review".
  inReview,

  /// Verified. Phase 1 has no EMI checkout, so the button says it is coming.
  comingSoon,
}

/// `GET /v1/customer/emi/eligibility`.
class EmiEligibility {
  const EmiEligibility({
    required this.kycTier,
    required this.kycStatus,
    required this.eligible,
    this.reasons = const <String>[],
    this.band,
  });

  final int kycTier;
  final KycStatus kycStatus;
  final bool eligible;
  final List<String> reasons;

  /// Risk band A–D. Always null in phase 1.
  final String? band;

  /// The calculator's button for a signed-in buyer.
  ///
  /// `reasons` decides when it is present; `kycStatus` is the fallback for a
  /// payload that says "not eligible" without a reason this build knows, so a
  /// buyer whose documents are with a reviewer is never sent to upload them
  /// again.
  EmiCta get cta {
    if (eligible) return EmiCta.comingSoon;
    if (reasons.contains(EmiIneligibleReason.kycInReview)) {
      return EmiCta.inReview;
    }
    if (reasons.contains(EmiIneligibleReason.kycRequired) ||
        reasons.contains(EmiIneligibleReason.kycRejected)) {
      return EmiCta.getVerified;
    }
    return kycStatus.isInReview ? EmiCta.inReview : EmiCta.getVerified;
  }
}
