import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Reads the backend `VendorOrderPaymentPlanDto` (`paymentPlan` on the vendor
/// sub-order list row and detail). Null when absent — an ordinary order.
VendorOrderPaymentPlan? readVendorOrderPaymentPlan(Object? json) {
  if (json is! Map) return null;
  final wireCurrency = json['currency'];
  final currency = wireCurrency is String && wireCurrency.isNotEmpty
      ? wireCurrency
      : 'NPR';
  Money money(Object? v) =>
      Money(amount: v is num ? v.toDouble() : 0, currency: currency);
  return VendorOrderPaymentPlan(
    kind: json['kind'] is String ? json['kind'] as String : 'Instalment',
    price: money(json['priceAmount']),
    downPayment: money(json['downPaymentAmount']),
    financed: money(json['financedAmount']),
    tenureMonths: json['tenureMonths'] is num
        ? (json['tenureMonths'] as num).toInt()
        : 0,
    monthlyInstalment: money(json['monthlyInstalmentAmount']),
    downPaymentOnDelivery: json['downPaymentOnDelivery'] == true,
    downPaymentPaid: json['downPaymentPaid'] == true,
    agreementId: switch (json['agreementId']) {
      final String id when id.trim().isNotEmpty => id.trim(),
      _ => null,
    },
  );
}

/// The detail's `cashToCollectAmount` / `cashToCollectCurrency`; null when
/// nothing is collected.
Money? readCashToCollect(Map<String, dynamic> json) {
  final amount = json['cashToCollectAmount'];
  if (amount is! num || amount <= 0) return null;
  final currency = json['cashToCollectCurrency'];
  return Money(
    amount: amount.toDouble(),
    currency: currency is String && currency.isNotEmpty ? currency : 'NPR',
  );
}
