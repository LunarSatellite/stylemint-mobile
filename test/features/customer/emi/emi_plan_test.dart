import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_plan.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

Money _npr(num amount) => Money(amount: amount.toDouble(), currency: 'NPR');

/// The EMI arithmetic of the phase 1 contract. The backend computes the same
/// figures for `GET /v1/emi/quote`, so every case here is one the two sides
/// must agree on to the rupee.
void main() {
  group('EmiPlan.compute', () {
    test('rounds the down payment and the installment up to whole rupees', () {
      final plan = EmiPlan.compute(
        price: _npr(25000),
        downPaymentPercent: 30,
        tenureMonths: 6,
      );

      expect(plan.downPayment, _npr(7500));
      expect(plan.financedAmount, _npr(17500));
      // 17,500 / 6 = 2,916.67 -> 2,917.
      expect(plan.monthlyInstallment, _npr(2917));
      // 17,500 - 2,917 x 5 = 2,915: the last month absorbs the rounding.
      expect(plan.lastInstallment, _npr(2915));
      expect(plan.totalPayable, _npr(25000));
    });

    test('a fractional down payment rounds up, not to nearest', () {
      // 33,333 x 30 % = 9,999.9 -> 10,000.
      final plan = EmiPlan.compute(
        price: _npr(33333),
        downPaymentPercent: 30,
        tenureMonths: 12,
      );

      expect(plan.downPayment, _npr(10000));
      expect(plan.financedAmount, _npr(23333));
      expect(plan.monthlyInstallment, _npr(1945));
      expect(plan.lastInstallment, _npr(1938));
    });

    test('an even split leaves the last installment equal to the rest', () {
      final plan = EmiPlan.compute(
        price: _npr(24000),
        downPaymentPercent: 25,
        tenureMonths: 12,
      );

      expect(plan.monthlyInstallment, _npr(1500));
      expect(plan.lastInstallment, _npr(1500));
      expect(plan.schedule, everyElement(_npr(1500)));
    });

    test('a price with paisa still yields whole-rupee down payments', () {
      // 20,000.10 x 30 % = 6,000.03 -> 6,001.
      final plan = EmiPlan.compute(
        price: _npr(20000.10),
        downPaymentPercent: 30,
        tenureMonths: 3,
      );

      expect(plan.downPayment, _npr(6001));
      expect(plan.financedAmount.amount, closeTo(13999.10, 1e-9));
      expect(plan.monthlyInstallment, _npr(4667));
      expect(plan.lastInstallment.amount, closeTo(4665.10, 1e-9));
    });

    test('the minimum price at the minimum down payment over 3 months', () {
      final plan = EmiPlan.compute(
        price: _npr(20000),
        downPaymentPercent: 20,
        tenureMonths: 3,
      );

      expect(plan.downPayment, _npr(4000));
      expect(plan.monthlyInstallment, _npr(5334));
      expect(plan.lastInstallment, _npr(5332));
      expect(plan.schedule, [_npr(5334), _npr(5334), _npr(5332)]);
    });

    test('schedule and down payment always add up to the price, and the last '
        'installment never exceeds the others', () {
      for (final price in [20000, 20001, 23457, 49999, 99999, 125000]) {
        for (var percent = 20; percent <= 90; percent += 5) {
          for (final tenure in emiAllowedTenures) {
            final plan = EmiPlan.compute(
              price: _npr(price),
              downPaymentPercent: percent,
              tenureMonths: tenure,
            );
            final paid =
                plan.downPayment.amount +
                plan.schedule.fold<double>(0, (sum, m) => sum + m.amount);
            final label = '$price @ $percent% x $tenure';
            expect(paid, closeTo(price, 1e-6), reason: label);
            expect(plan.schedule, hasLength(tenure), reason: label);
            expect(
              plan.lastInstallment.amount,
              lessThanOrEqualTo(plan.monthlyInstallment.amount),
              reason: label,
            );
            expect(plan.lastInstallment.amount, greaterThan(0), reason: label);
          }
        }
      }
    });

    test('keeps the price currency', () {
      final plan = EmiPlan.compute(
        price: const Money(amount: 30000, currency: 'USD'),
        downPaymentPercent: 50,
        tenureMonths: 3,
      );
      expect(plan.monthlyInstallment.currency, 'USD');
    });
  });

  group('emiFromMonthly', () {
    test('uses the lowest eligible price and the longest tenure', () {
      final monthly = emiFromMonthly(
        eligiblePrices: [_npr(30000), _npr(25000)],
        effectiveMinDownPaymentPercent: 30,
        tenures: const [3, 6],
      );
      // 25,000 at 30 % over 6 months.
      expect(monthly, _npr(2917));
    });

    test('is null when nothing qualifies', () {
      expect(
        emiFromMonthly(
          eligiblePrices: const [],
          effectiveMinDownPaymentPercent: 30,
          tenures: const [3],
        ),
        isNull,
      );
      expect(
        emiFromMonthly(
          eligiblePrices: [_npr(30000)],
          effectiveMinDownPaymentPercent: 30,
          tenures: const [],
        ),
        isNull,
      );
    });
  });

  test('snapDownPaymentPercent rounds up to a 5 % step within 20–90', () {
    expect(snapDownPaymentPercent(5), 20);
    expect(snapDownPaymentPercent(20), 20);
    expect(snapDownPaymentPercent(31), 35);
    expect(snapDownPaymentPercent(35), 35);
    expect(snapDownPaymentPercent(95), 90);
  });
}
