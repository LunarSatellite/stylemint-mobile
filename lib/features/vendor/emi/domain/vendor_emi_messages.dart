import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/emi_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_plan.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// The contract's vendor EMI error codes.
abstract final class VendorEmiErrorCode {
  static const priceBelowMinimum = 'emi_terms.price_below_minimum';
  static const downPaymentOutOfRange = 'emi_terms.down_payment_out_of_range';
  static const invalidTenure = 'emi_terms.invalid_tenure';
  static const interestNotAllowed = 'emi_terms.interest_not_allowed';
  static const approvalModeNotAllowed = 'emi_terms.approval_mode_not_allowed';
  static const exposureAboveMaximum = 'emi_settings.exposure_above_maximum';
}

String _minimumPrice(Money? minimumPrice) => formatMoney(
  minimumPrice ?? const Money(amount: emiMinimumPriceAmount, currency: 'NPR'),
  decimalDigits: 0,
);

/// The sentence for a vendor EMI failure. Every `emi_terms.*` and
/// `emi_settings.*` code has its own.
String vendorEmiErrorMessage(
  EmiFailure failure, {
  Money? minimumPrice,
  Money? maxExposureLimit,
}) {
  switch (failure.code) {
    case VendorEmiErrorCode.priceBelowMinimum:
      return 'EMI needs at least one variant priced at '
          '${_minimumPrice(minimumPrice)} or more. Raise a price, or keep EMI '
          'off for this product.';
    case VendorEmiErrorCode.downPaymentOutOfRange:
      return 'The minimum down payment must be between '
          '$emiMinDownPaymentPercent% and $emiMaxDownPaymentPercent%.';
    case VendorEmiErrorCode.invalidTenure:
      return 'Choose at least one of 3, 6, 9 or 12 months.';
    case VendorEmiErrorCode.interestNotAllowed:
      return 'EMI is interest-free for now — interest cannot be charged.';
    case VendorEmiErrorCode.approvalModeNotAllowed:
      return 'Every EMI order needs your approval for now; automatic approval '
          'is not available yet.';
    case VendorEmiErrorCode.exposureAboveMaximum:
      return maxExposureLimit == null
          ? 'That limit is above what StyleMint allows.'
          : 'That limit is above the '
                '${formatMoney(maxExposureLimit, decimalDigits: 0)} StyleMint '
                'allows.';
  }
  return emiCommonMessage(failure) ??
      serverMessageOr(failure, 'We could not save that. Please try again.');
}

/// The draft's problem, worded like the server's, or null when it can be
/// sent. Mirrors the server rules so a vendor hears about them before the
/// round trip — the server still has the last word.
String? validateVendorEmiTerms({
  required bool enabled,
  required int minDownPaymentPercent,
  required List<int> tenures,
  required int eligibleVariantCount,
  Money? minimumPrice,
}) {
  if (minDownPaymentPercent < emiMinDownPaymentPercent ||
      minDownPaymentPercent > emiMaxDownPaymentPercent ||
      minDownPaymentPercent % emiDownPaymentStep != 0) {
    return vendorEmiErrorMessage(
      const EmiFailure.local(VendorEmiErrorCode.downPaymentOutOfRange),
    );
  }
  if (tenures.isEmpty || tenures.any((t) => !emiAllowedTenures.contains(t))) {
    return vendorEmiErrorMessage(
      const EmiFailure.local(VendorEmiErrorCode.invalidTenure),
    );
  }
  if (enabled && eligibleVariantCount <= 0) {
    return vendorEmiErrorMessage(
      const EmiFailure.local(VendorEmiErrorCode.priceBelowMinimum),
      minimumPrice: minimumPrice,
    );
  }
  return null;
}

/// The minimum down payment buyers would get if the vendor chose [selected],
/// for the live preview before saving.
///
/// The commission floor itself is not sent to the app; it shows only as the
/// gap between the saved terms' effective and chosen minimums. So the
/// preview applies that floor when the server revealed one, and the 20 %
/// floor otherwise — after saving, the server's own figure replaces it.
int previewEffectiveMinDownPercent({
  required int selected,
  required int savedMinDownPaymentPercent,
  required int savedEffectiveMinDownPaymentPercent,
}) {
  final commissionFloor =
      savedEffectiveMinDownPaymentPercent > savedMinDownPaymentPercent
      ? savedEffectiveMinDownPaymentPercent
      : emiMinDownPaymentPercent;
  final floor = commissionFloor > emiMinDownPaymentPercent
      ? commissionFloor
      : emiMinDownPaymentPercent;
  return selected > floor ? selected : floor;
}
