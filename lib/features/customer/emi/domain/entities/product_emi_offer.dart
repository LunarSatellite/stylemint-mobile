import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_plan.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// One variant as EMI sees it: its catalogue price and whether the vendor's
/// terms cover it (`variants[].emiEligible`).
class EmiVariantTerms {
  const EmiVariantTerms({required this.price, required this.eligible});

  final Money price;
  final bool eligible;
}

/// The `emi` block of the product detail payload, plus each variant's
/// `emiEligible`.
///
/// The detail response carries `emi: null` when the vendor has not enabled EMI
/// or no variant qualifies, and an older backend carries no `emi` at all.
/// Both parse to no offer, and the product page then draws nothing about EMI —
/// the app ships before the backend that sends this.
class ProductEmiOffer {
  const ProductEmiOffer({
    required this.minDownPaymentPercent,
    required this.tenures,
    this.fromMonthly,
    this.interestRatePercentMonthly = 0,
    this.minimumPrice,
    this.variants = const <String, EmiVariantTerms>{},
  });

  /// The **effective** minimum down payment (after the 20 % floor and the
  /// commission rule) — the slider's lower end.
  final int minDownPaymentPercent;

  /// Tenures in months, ascending; a subset of 3, 6, 9, 12.
  final List<int> tenures;

  /// The server's "EMI from" figure for the product as a whole.
  final Money? fromMonthly;

  /// Always 0 in phase 1.
  final double interestRatePercentMonthly;
  final Money? minimumPrice;

  /// Variant id → its price and eligibility.
  final Map<String, EmiVariantTerms> variants;

  int get longestTenure => tenures.isEmpty ? 0 : tenures.last;

  /// The slider's lower end, on a 5 % step and never below 20 %.
  int get sliderMinPercent => snapDownPaymentPercent(minDownPaymentPercent);

  /// Whether [variantId] can be bought on EMI. An unknown id is not eligible.
  bool isEligible(String? variantId) =>
      variantId != null && (variants[variantId]?.eligible ?? false);

  /// The price EMI uses for [variantId], or null when it is not eligible.
  Money? priceOf(String? variantId) {
    final terms = variantId == null ? null : variants[variantId];
    return terms != null && terms.eligible ? terms.price : null;
  }

  /// "EMI from x/month" for one variant: its installment at the minimum down
  /// payment over the longest tenure. Null when it is not eligible.
  Money? fromMonthlyFor(String? variantId) {
    final price = priceOf(variantId);
    if (price == null || tenures.isEmpty) return null;
    return EmiPlan.compute(
      price: price,
      downPaymentPercent: sliderMinPercent,
      tenureMonths: longestTenure,
    ).monthlyInstallment;
  }
}
