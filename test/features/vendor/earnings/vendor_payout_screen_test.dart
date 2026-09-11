import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/payouts/data/datasources/payout_destinations_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/payouts/presentation/notifiers/payout_destinations_controller.dart';
import 'package:stylemint_mobile_frontend/features/payouts/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/entities/vendor_earnings.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/repositories/vendor_earnings_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/notifiers/vendor_earnings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/vendor_payout_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _MockVendorEarningsRepository extends Mock
    implements VendorEarningsRepository {}

class _MockPayoutDestinationsDataSource extends Mock
    implements PayoutDestinationsRemoteDataSource {}

void main() {
  testWidgets('confirm payout stays above the system navigation area', (
    tester,
  ) async {
    final earnings = _MockVendorEarningsRepository();
    final destinations = _MockPayoutDestinationsDataSource();
    when(() => earnings.getBalance()).thenAnswer(
      (_) async => right(
        const VendorEarningsBalance(
          available: Money(amount: 0, currency: 'NPR'),
          pending: Money(amount: 999, currency: 'NPR'),
          lifetime: Money(amount: 999, currency: 'NPR'),
        ),
      ),
    );
    when(() => destinations.list(2)).thenAnswer((_) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vendorBalanceNotifierProvider.overrideWith(
            (ref) => BalanceNotifier(earnings),
          ),
          payoutNotifierProvider.overrideWith(
            (ref) => PayoutNotifier(earnings),
          ),
          payoutDestinationsControllerProvider(2).overrideWith(
            (ref) => PayoutDestinationsController(destinations, 2),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(bottom: 48),
              viewPadding: const EdgeInsets.only(bottom: 48),
            ),
            child: child!,
          ),
          home: const VendorPayoutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final bodyInset = tester.widget<Padding>(
      find.byKey(const Key('vendor-payout-body-inset')),
    );
    expect((bodyInset.padding as EdgeInsets).bottom, 64);
    final confirmButton = find.ancestor(
      of: find.text('Confirm Payout'),
      matching: find.byType(ElevatedButton),
    );
    final logicalHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(
      tester.getBottomRight(confirmButton).dy,
      lessThanOrEqualTo(logicalHeight - 48),
    );
  });
}
