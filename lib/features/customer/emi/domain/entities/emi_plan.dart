import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// The tenures EMI phase 1 allows. A vendor offers any subset of these.
const emiAllowedTenures = <int>[3, 6, 9, 12];

/// Down payment bounds of phase 1, in percent.
const emiMinDownPaymentPercent = 20;
const emiMaxDownPaymentPercent = 90;

/// The down-payment slider moves in these steps.
const emiDownPaymentStep = 5;

/// Only variants priced at or above this are EMI-eligible (NPR).
const emiMinimumPriceAmount = 20000.0;

/// One EMI plan, worked out on the device with the contract's rounding rule.
///
/// The backend computes the same numbers for `GET /v1/emi/quote`, and the two
/// MUST agree to the rupee:
///
/// ```text
/// downPayment     = roundUp(price * downPaymentPercent / 100)   // whole rupees
/// financed        = price - downPayment
/// installment     = roundUp(financed / tenureMonths)            // whole rupees
/// lastInstallment = financed - installment * (tenureMonths - 1) // absorbs rounding
/// totalPayable    = price                                       // 0 % interest
/// ```
///
/// Everything is done in integer paisa so a price like 33,333 at 30 % does not
/// become 9,999.900000001 and round up a rupee too far — `ceil` on a binary
/// double is exactly where two implementations of "the same" rule drift apart.
class EmiPlan {
  const EmiPlan({
    required this.price,
    required this.downPaymentPercent,
    required this.downPayment,
    required this.financedAmount,
    required this.tenureMonths,
    required this.monthlyInstallment,
    required this.lastInstallment,
    required this.totalPayable,
  });

  /// Works out the plan for [price] at [downPaymentPercent] over
  /// [tenureMonths]. Percent is clamped to 0–100 and tenure to at least 1, so
  /// a bad input yields a plan rather than a division by zero.
  factory EmiPlan.compute({
    required Money price,
    required int downPaymentPercent,
    required int tenureMonths,
  }) {
    final percent = downPaymentPercent.clamp(0, 100);
    final months = tenureMonths < 1 ? 1 : tenureMonths;
    final pricePaisa = _paisa(price.amount);

    // roundUp(price * pct / 100) in rupees == ceil(paisa * pct / 10000).
    final downRupees = _ceilDiv(pricePaisa * percent, 100 * 100);
    final financedPaisa = pricePaisa - downRupees * 100;
    final installmentRupees = financedPaisa <= 0
        ? 0
        : _ceilDiv(financedPaisa, months * 100);
    final lastPaisa = financedPaisa <= 0
        ? 0
        : financedPaisa - installmentRupees * 100 * (months - 1);

    Money money(num rupees) =>
        Money(amount: rupees.toDouble(), currency: price.currency);

    return EmiPlan(
      price: price,
      downPaymentPercent: percent,
      downPayment: money(downRupees),
      financedAmount: money(financedPaisa / 100),
      tenureMonths: months,
      monthlyInstallment: money(installmentRupees),
      lastInstallment: money(lastPaisa / 100),
      totalPayable: price,
    );
  }

  final Money price;
  final int downPaymentPercent;
  final Money downPayment;
  final Money financedAmount;
  final int tenureMonths;
  final Money monthlyInstallment;

  /// The final month's amount — never more than [monthlyInstallment].
  final Money lastInstallment;

  /// Equal to [price] while EMI is interest-free (phase 1).
  final Money totalPayable;

  /// Every monthly payment after delivery, in order. All equal
  /// [monthlyInstallment] except the last, which absorbs the rounding.
  List<Money> get schedule => [
    for (var month = 1; month <= tenureMonths; month++)
      month == tenureMonths ? lastInstallment : monthlyInstallment,
  ];

  static int _paisa(double amount) => (amount * 100).round();

  /// Ceiling division for a non-negative [a] and a positive [b].
  static int _ceilDiv(int a, int b) => a <= 0 ? 0 : (a + b - 1) ~/ b;
}

/// The "EMI from x/month" figure for a product: the installment for its
/// **lowest** EMI-eligible variant price, at the **effective minimum** down
/// payment, over the **longest** tenure offered. Null when nothing qualifies.
Money? emiFromMonthly({
  required Iterable<Money> eligiblePrices,
  required int effectiveMinDownPaymentPercent,
  required Iterable<int> tenures,
}) {
  if (eligiblePrices.isEmpty || tenures.isEmpty) return null;
  final lowest = eligiblePrices.reduce((a, b) => a.amount <= b.amount ? a : b);
  final longest = tenures.reduce((a, b) => a >= b ? a : b);
  return EmiPlan.compute(
    price: lowest,
    downPaymentPercent: effectiveMinDownPaymentPercent,
    tenureMonths: longest,
  ).monthlyInstallment;
}

/// [percent] rounded up to the slider's 5 % step and kept within 20–90.
int snapDownPaymentPercent(int percent) {
  final stepped =
      ((percent + emiDownPaymentStep - 1) ~/ emiDownPaymentStep) *
      emiDownPaymentStep;
  return stepped.clamp(emiMinDownPaymentPercent, emiMaxDownPaymentPercent);
}
