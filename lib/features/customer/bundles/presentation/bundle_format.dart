import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// "Rs 12,500" — whole rupees without decimals, paisa when there are any.
String bundleMoney(Money money) => formatMoney(
  money,
  decimalDigits: money.amount == money.amount.roundToDouble() ? 0 : 2,
);

/// "10% off" — or null for a kit sold at list price.
String? bundleDiscountLabel(double percent) {
  if (percent <= 0) return null;
  final whole = percent == percent.roundToDouble();
  return '${whole ? percent.toInt() : percent.toStringAsFixed(1)}% off';
}

/// "4 items from 2 shops" (counts the server did not send are left out).
String bundleCountsLabel({required int items, required int shops}) {
  final parts = <String>[
    if (items > 0) '$items ${items == 1 ? 'item' : 'items'}',
    if (shops > 0) shops == 1 ? 'from 1 shop' : 'from $shops shops',
  ];
  return parts.join(' ');
}

/// The cart's `unavailableReason` wire value as a sentence.
String bundleUnavailableSentence(String? wire) =>
    (BundleUnavailableReason.fromWire(wire) ?? BundleUnavailableReason.other)
        .sentence;
