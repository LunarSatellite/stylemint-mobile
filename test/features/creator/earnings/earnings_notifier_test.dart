import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings_breakdown.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/repositories/earnings_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/notifiers/earnings_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

const _npr = 'NPR';

class _FakeRepository implements EarningsRepository {
  _FakeRepository({this.summary, this.ledger, this.methods});

  NetworkEither<EarningsSummary>? summary;
  NetworkEither<List<EarningsLedgerEntry>>? ledger;
  NetworkEither<List<PayoutMethod>>? methods;

  int summaryCalls = 0;

  @override
  Future<NetworkEither<EarningsSummary>> getSummary() async {
    summaryCalls++;
    return summary ?? networkRight(_summary());
  }

  @override
  Future<NetworkEither<List<EarningsLedgerEntry>>> getLedger({
    int limit = 20,
    String? cursor,
  }) async => ledger ?? networkRight(const <EarningsLedgerEntry>[]);

  @override
  Future<NetworkEither<List<PayoutMethod>>> getPayoutMethods() async =>
      methods ?? networkRight(const <PayoutMethod>[]);

  @override
  Future<NetworkEither<Unit>> requestPayout({
    required Money amount,
    required String payoutMethodId,
  }) async => networkRight(unit);

  @override
  Future<NetworkEither<Unit>> addBankPayoutMethod({
    required int kind,
    required String label,
    String? maskedAccountNumber,
    String? beneficiaryName,
    String? processorReference,
  }) async => networkRight(unit);

  @override
  Future<NetworkEither<Unit>> addExternalWalletPayoutMethod({
    required int kind,
    required String label,
    String? externalIdentifier,
    String? processorReference,
  }) async => networkRight(unit);

  @override
  Future<NetworkEither<Unit>> removePayoutMethod(String methodId) async =>
      networkRight(unit);

  @override
  Future<NetworkEither<List<PayoutRecord>>> getPayouts({
    int pageSize = 25,
    String? cursor,
  }) async => networkRight(const <PayoutRecord>[]);

  @override
  Future<NetworkEither<EarningsBreakdown>> getDashboardBreakdown() async =>
      networkRight(
        const EarningsBreakdown(
          salesCount: 1,
          reelCount: 1,
          avgPerSale: Money(amount: 1, currency: _npr),
          highestReelEarnings: Money(amount: 1, currency: _npr),
        ),
      );

  @override
  Future<NetworkEither<PayoutInvoice>> getPayoutInvoice(
    String payoutId,
  ) async => networkLeft(const NetworkExceptions.unexpectedError());

  @override
  Future<NetworkEither<Unit>> cancelPayout(String payoutId) async =>
      networkRight(unit);
}

EarningsSummary _summary() => const EarningsSummary(
  totalEarnings: Money(amount: 100, currency: _npr),
  availableBalance: Money(amount: 60, currency: _npr),
  pendingBalance: Money(amount: 40, currency: _npr),
  totalCommission: 2,
  thisMonthEarnings: Money(amount: 25, currency: _npr),
  totalPayouts: Money(amount: 10, currency: _npr),
);

/// The notifier loads from its constructor; settle that before asserting.
Future<EarningsNotifier> _settled(_FakeRepository repo) async {
  final notifier = EarningsNotifier(repo);
  await Future<void>.delayed(Duration.zero);
  return notifier;
}

void main() {
  group('EarningsNotifier', () {
    test(
      'composes summary, ledger and payout methods into one success state',
      () async {
        final notifier = await _settled(_FakeRepository());

        final balance = notifier.state.maybeWhen(
          loadSuccess: (summary, _, _) => summary.availableBalance.amount,
          orElse: () => -1.0,
        );
        expect(balance, 60);
      },
    );

    test('a failing summary fails the whole load', () async {
      final notifier = await _settled(
        _FakeRepository(
          summary: networkLeft(const NetworkExceptions.noInternetConnection()),
        ),
      );

      expect(
        notifier.state.maybeWhen(
          loadFailure: (f) => NetworkExceptions.getMessage(f),
          orElse: () => null,
        ),
        'No internet connection.',
      );
    });

    test(
      'a failing ledger fails the load even when the summary succeeded',
      () async {
        final notifier = await _settled(
          _FakeRepository(
            ledger: networkLeft(const NetworkExceptions.unexpectedError()),
          ),
        );

        expect(
          notifier.state.maybeWhen(
            loadFailure: (_) => true,
            orElse: () => false,
          ),
          isTrue,
        );
      },
    );

    test('a failing payout-method lookup fails the load', () async {
      final notifier = await _settled(
        _FakeRepository(
          methods: networkLeft(const NetworkExceptions.serverUnavailable()),
        ),
      );

      expect(
        notifier.state.maybeWhen(loadFailure: (_) => true, orElse: () => false),
        isTrue,
      );
    });

    test('load() can be called again to refresh', () async {
      final repo = _FakeRepository();
      final notifier = await _settled(repo);

      await notifier.load();

      expect(repo.summaryCalls, 2);
    });
  });
}
