import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_order_payment_plan_json.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_order_tile.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// An EMI order on the seller's screens: the plan's down payment, how it is
/// paid, the instalments, and what the rider collects — never the price as
/// cash to collect.
void main() {
  const planWire = <String, dynamic>{
    'agreementId': '8849f7d8-9f0f-429e-9ccb-0181ab4299e0',
    'kind': 'Instalment',
    'priceAmount': 100000,
    'downPaymentAmount': 30000,
    'financedAmount': 70000,
    'tenureMonths': 3,
    'monthlyInstalmentAmount': 23334,
    'currency': 'NPR',
    'downPaymentOnDelivery': true,
    'downPaymentPaid': false,
  };

  test('the detail carries the plan and only the down payment as cash', () {
    final order = VendorOrderDetailDto.fromJson({
      'id': 'e03e857e-0000-0000-0000-000000000000',
      'orderNumber': 'NK2026-00028',
      'state': 13,
      'subtotalAmount': 100000,
      'subtotalCurrency': 'NPR',
      'paymentMethod': 4,
      'paymentPlan': planWire,
      'cashToCollectAmount': 30000,
      'cashToCollectCurrency': 'NPR',
      'lines': const <dynamic>[],
    }).toDomain();

    expect(order.total.amount, 100000, reason: 'the item price stays the total');
    final plan = order.paymentPlan!;
    expect(plan.label, 'EMI');
    expect(plan.downPayment, const Money(amount: 30000, currency: 'NPR'));
    expect(plan.financed.amount, 70000);
    expect(plan.tenureMonths, 3);
    expect(plan.monthlyInstalment.amount, 23334);
    expect(plan.downPaymentOnDelivery, isTrue);
    expect(order.cashToCollect, const Money(amount: 30000, currency: 'NPR'));
  });

  test('an ordinary order has no plan, and nothing collected when absent', () {
    final order = VendorOrderDetailDto.fromJson({
      'id': 'x',
      'orderNumber': 'NK2026-00029',
      'state': 2,
      'subtotalAmount': 500,
      'subtotalCurrency': 'NPR',
      'lines': const <dynamic>[],
    }).toDomain();

    expect(order.paymentPlan, isNull);
    expect(order.cashToCollect, isNull);
  });

  test('the row says how the down payment is paid', () {
    final cash = readVendorOrderPaymentPlan(planWire)!;
    expect(
      vendorPlanSummary(cash),
      'EMI · Rs 30,000 down payment — collect in cash on delivery',
    );
    final online = readVendorOrderPaymentPlan({
      ...planWire,
      'downPaymentOnDelivery': false,
      'downPaymentPaid': true,
    })!;
    expect(vendorPlanSummary(online), 'EMI · Rs 30,000 down payment — paid online');
    expect(readVendorOrderPaymentPlan(null), isNull);
  });
}
