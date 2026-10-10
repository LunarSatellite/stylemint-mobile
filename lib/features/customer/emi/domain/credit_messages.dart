import 'package:stylemint_mobile_frontend/features/customer/emi/domain/emi_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';

/// The sentences payment plans speak in. Codes come from the Credit module;
/// each maps to something a buyer or a seller can act on, and none of them
/// pretends to know more than the server said.

/// What to say when a quote, an application, a cancellation or a payment is
/// refused.
String creditFailureMessage(EmiFailure failure) {
  switch (failure.code) {
    case 'credit_quote.unavailable':
      return 'Payment plans are not available right now. '
          'Please try again later.';
    case 'credit_quote.expired':
      return 'This offer has expired. Go back and ask for a new one.';
    case 'credit_quote.stale':
      return 'The price or the terms changed since this offer was made. '
          'Go back and ask for a new one.';
    case 'credit_quote.invalid':
    case 'credit_quote.not_yours':
      return 'This offer is not valid any more. Go back and ask for a new one.';
    case 'credit_offer.not_available':
      return 'This item can no longer be paid for this way.';
    case 'credit_schedule.refused':
      return serverMessageOr(
        failure,
        'That plan does not work for this price.',
      );
    case 'credit_agreement.invalid_transition':
      return 'This plan has changed. Refresh to see where it stands.';
    case 'credit_agreement.not_active':
      return 'This plan is not active, so nothing can be paid on it.';
    case 'credit_payment.nothing_due':
      return 'Nothing is due on this plan right now.';
    case 'credit_payment.unavailable':
      return 'The payment could not be started. Nothing has been charged.';
    case 'credit_payment.exceeds_outstanding':
    case 'credit_payment.payoff_mismatch':
      return 'The amount owed has changed. Refresh and try again.';
    case 'resource.not_found':
      return 'We could not find this plan.';
  }
  if (failure.kind == EmiFailureKind.notFound) {
    return 'Payment plans are not available yet. Please check back soon.';
  }
  return emiCommonMessage(failure) ??
      serverMessageOr(failure, 'Something went wrong. Please try again.');
}

/// Why a plan was referred or not approved, for the buyer. Unknown codes —
/// a seller's own reason, say — are shown as words rather than hidden.
String reasonForBuyer(String code) => switch (code) {
  'kyc_required' => 'Verify your identity to use payment plans.',
  'identity_unavailable' =>
    'We could not confirm your identity right now. Please try again later.',
  'band_too_low' =>
    'Your account does not have enough history with StyleMint yet. '
        'Completed orders help.',
  'buyer_limit_exceeded' =>
    'This is more than your current payment-plan limit.',
  'vendor_exposure_exceeded' =>
    'The seller cannot take on more payment plans right now.',
  'reserve_insufficient' =>
    'Pay later is fully used right now. Please try again in a few days.',
  'prior_default' => 'A previous payment plan was not paid.',
  'velocity_exceeded' =>
    'Too many applications today. Please try again tomorrow.',
  'too_many_active_agreements' =>
    'You have the most open payment plans allowed. Finish one first.',
  'cooling_off' =>
    'Please wait a few days after a plan is not approved before applying '
        'again.',
  'duplicate_identity' =>
    'We could not match this identity to your account. Contact support.',
  'kind_disabled' ||
  'guarantor_disabled' => 'This kind of plan is not available right now.',
  'amount_below_minimum' => 'This item costs less than this plan allows.',
  'amount_above_maximum' => 'This item costs more than this plan allows.',
  'manual_review_required' => 'The seller reviews each request personally.',
  // Reasons a seller or a StyleMint reviewer gives for declining. Said
  // without naming who declined: the same code comes from either.
  'insufficient_history' =>
    'More purchase history is needed before a plan can be offered.',
  'platform_review_declined' =>
    'StyleMint reviewed this request and could not approve it.',
  'identity_concern' =>
    'We need to check some of your details. Contact support to continue.',
  'out_of_stock' => 'The seller no longer has this item.',
  'pricing_error' => 'The seller found a mistake in the price.',
  'not_offered_now' => 'The seller is not offering plans right now.',
  'interest_requires_partner' ||
  'guarantor_not_allowed_for_kind' => 'This plan is not available.',
  _ => _words(code),
};

/// The same reasons, for the seller deciding a referral. A seller sees why
/// StyleMint referred it, never the buyer's documents or score inputs.
String reasonForVendor(String code) => switch (code) {
  'band_too_low' => 'The buyer has little purchase history with StyleMint yet.',
  'buyer_limit_exceeded' =>
    'The amount is above what StyleMint would lend this buyer itself.',
  'manual_review_required' => 'Your EMI terms ask to review every request.',
  _ => reasonForBuyer(code),
};

/// What moved the buyer's score, as a label.
String scoreFactorLabel(String code) => switch (code) {
  'kyc_verified' => 'Identity verified',
  'phone_verified' => 'Phone verified',
  'email_verified' => 'Email verified',
  'duplicate_identity' => 'Identity check',
  'account_age' => 'Time with StyleMint',
  'completed_orders' => 'Completed orders',
  'completed_value' => 'Value of completed orders',
  'return_cancel_rate' => 'Returns and cancellations',
  'on_time_instalments' => 'Payments made on time',
  'late_instalments' => 'Late payments',
  'prior_defaults' => 'Unpaid plans',
  _ => _words(code),
};

/// `out_of_stock` → `Out of stock`.
String _words(String code) {
  final words = code.replaceAll('_', ' ').trim();
  if (words.isEmpty) return 'Not available for this purchase.';
  return words[0].toUpperCase() + words.substring(1);
}
