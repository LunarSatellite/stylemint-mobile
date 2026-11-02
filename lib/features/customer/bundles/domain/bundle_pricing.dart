import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// The bundle money math (contract §B7), mirrored for display only — the
/// server prices the cart.
///
/// `unitDiscount = round(P × d / 100, 2, AwayFromZero)`, `U = P − unitDiscount`.
double bundleUnitPrice(double listPrice, double discountPercent) {
  if (discountPercent <= 0) return listPrice;
  final discount = roundMoney(listPrice * discountPercent / 100);
  return roundMoney(listPrice - discount);
}

/// Two decimals, halves away from zero (C# `MidpointRounding.AwayFromZero`).
/// The nudge keeps a float like 1.005 (stored as 1.00499…) on the side a
/// decimal would put it.
double roundMoney(double value) {
  final scaled = value * 100;
  final nudged = scaled >= 0 ? scaled + 1e-7 : scaled - 1e-7;
  return nudged.round() / 100;
}

/// What one bundle costs with the variants the buyer picked.
class BundleQuote {
  const BundleQuote({
    required this.listTotal,
    required this.bundleTotal,
    required this.complete,
  });

  final Money listTotal;
  final Money bundleTotal;

  /// Every item has a variant that can cover its quantity.
  final bool complete;

  Money get saving => Money(
    amount: roundMoney(listTotal.amount - bundleTotal.amount),
    currency: bundleTotal.currency,
  );
}

/// Prices [bundle] with [chosen] (bundle item id → variant id). An item with
/// no pick, or a pick that is gone, is priced at its default variant and
/// leaves the quote incomplete.
BundleQuote quoteBundle(BundleDetail bundle, Map<String, String> chosen) {
  var list = 0.0;
  var total = 0.0;
  var complete = true;
  for (final item in bundle.items) {
    final variantId = chosen[item.id];
    BundleVariant? variant;
    for (final v in item.variants) {
      if (v.id == variantId) variant = v;
    }
    if (variant == null || !variant.canCover(item.quantity)) complete = false;
    final p = variant?.price.amount ?? item.listUnitPrice.amount;
    final u = variant == null
        ? item.bundleUnitPrice.amount
        : bundleUnitPrice(p, bundle.discountPercent);
    list += p * item.quantity;
    total += u * item.quantity;
  }
  return BundleQuote(
    listTotal: Money(amount: roundMoney(list), currency: bundle.currency),
    bundleTotal: Money(amount: roundMoney(total), currency: bundle.currency),
    complete: complete && bundle.items.isNotEmpty,
  );
}
