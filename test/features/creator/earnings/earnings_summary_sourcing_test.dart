import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/data/models/earnings_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// **Three money fields on the creator's earnings summary had no producer
/// but a literal zero.**
///
/// `GET /v1/earnings/balance` returns `LedgerBalanceDto` — available,
/// pending, lifetime, currency — and nothing else. `EarningsSummaryDto`
/// nevertheless produced an `EarningsSummary` carrying `totalCommission:
/// 0`, `thisMonthEarnings: Money(0)` and `totalPayouts: Money(0)`, with a
/// comment saying they "default to zero until a confirmed source is
/// wired". Nothing rendered them — which is the only reason no creator was
/// ever shown "Total Payouts Rs 0" about money they had actually been
/// paid. This app has drawn precisely that zero before, on the Active
/// Partnerships card.
///
/// The three fields are gone. The month-to-date figures have a real home
/// in [MonthlySummary] (`GET /v1/earnings/summary`); lifetime payouts have
/// no producer anywhere in Payouts, so nothing may stand in for one.
///
/// These assert over the produced entity, so a re-added constant fails
/// here rather than on a creator's screen.
void main() {
  test('every money field on the summary traces to the response', () {
    final summary = EarningsSummaryDto.fromJson(_balanceJson()).toDomain();

    expect(summary.availableBalance.amount, 12589.98);
    expect(summary.pendingBalance.amount, 4210.02);
    expect(summary.totalEarnings.amount, 24500);
    expect(summary.availableBalance.currency, 'NPR');
  });

  test('a second response moves every field — none of them is a constant', () {
    final a = EarningsSummaryDto.fromJson(_balanceJson()).toDomain();
    final b = EarningsSummaryDto.fromJson(
      _balanceJson(available: 1, pending: 2, lifetime: 3),
    ).toDomain();

    final movedA = _amounts(a);
    final movedB = _amounts(b);
    expect(movedA.length, movedB.length);
    for (var i = 0; i < movedA.length; i++) {
      expect(
        movedA[i],
        isNot(movedB[i]),
        reason:
            'field $i held the same value for two different balances, so it '
            'is not read from the response',
      );
    }
  });

  test('a creator with money is never described with a zero', () {
    final summary = EarningsSummaryDto.fromJson(_balanceJson()).toDomain();

    expect(
      _amounts(summary),
      everyElement(isNot(0)),
      reason:
          'a zero rupee figure reads as "you have earned nothing", which is '
          'its own claim',
    );
  });

  test('a genuinely empty ledger still reads as zero', () {
    final summary = EarningsSummaryDto.fromJson(
      _balanceJson(available: 0, pending: 0, lifetime: 0),
    ).toDomain();

    expect(_amounts(summary), everyElement(0));
  });

  /// Enumerating the summary's money by hand here is the point: adding a
  /// field to [EarningsSummary] means coming back to this list and saying
  /// where it comes from.
  test('the summary carries exactly the three balances and no fourth', () {
    const summary = EarningsSummary(
      totalEarnings: Money(amount: 3, currency: 'NPR'),
      availableBalance: Money(amount: 1, currency: 'NPR'),
      pendingBalance: Money(amount: 2, currency: 'NPR'),
    );

    expect(_amounts(summary), [1.0, 2.0, 3.0]);
  });
}

List<double> _amounts(EarningsSummary s) => [
  s.availableBalance.amount,
  s.pendingBalance.amount,
  s.totalEarnings.amount,
];

Map<String, dynamic> _balanceJson({
  double available = 12589.98,
  double pending = 4210.02,
  double lifetime = 24500,
}) => <String, dynamic>{
  'availableValue': available,
  'pendingValue': pending,
  'lifetimeValue': lifetime,
  'currency': 'NPR',
};
