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
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/vendor_earnings_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

/// **Money paid to creators was billed to the vendor as a platform fee.**
///
/// The Revenue Breakdown card on the vendor earnings screen drew a row
/// labelled "Platform Fees" against `summary.platformFees`, which the
/// repository computed as `grossSales − netRevenue` off the analytics
/// overview. The platform charges a vendor no fee on order revenue —
/// nothing on the order records one — so every rupee in that row was
/// creator commission, named after the wrong recipient. It was also
/// inflated, because `VendorAnalyticsService` subtracted an invented 5 %
/// platform fee from gross before the commission; a vendor with Rs 10,000
/// of commission on Rs 100,000 of gross read "Platform Fees −Rs 15,000".
///
/// The row now says what it is. Asserted over what the screen renders.
class _MockVendorEarningsRepository extends Mock
    implements VendorEarningsRepository {}

class _MockPayoutDestinationsDataSource extends Mock
    implements PayoutDestinationsRemoteDataSource {}

void main() {
  testWidgets('the revenue breakdown names creators, not the platform', (
    tester,
  ) async {
    await _pumpEarnings(tester);

    final text = _allText(tester);
    expect(text, contains('Creator Commission'));
    expect(
      text.any((s) => s.toLowerCase().contains('platform fee')),
      isFalse,
      reason: 'the platform charges no fee on a vendor\'s order revenue',
    );
  });

  testWidgets('the deducted amount is the commission, not more', (
    tester,
  ) async {
    await _pumpEarnings(tester);

    final text = _allText(tester);
    // Gross 100,000 − commission 10,000. Nothing else comes off.
    expect(text.any((s) => s.contains('10,000')), isTrue);
    expect(
      text.any((s) => s.contains('15,000')),
      isFalse,
      reason: 'an invented 5 % of gross must not be added to the deduction',
    );
    expect(
      text.any((s) => s.contains('90,000')),
      isTrue,
      reason: 'net earnings is gross minus the commission actually paid',
    );
  });
}

// ── Harness ──────────────────────────────────────────────────────────────────

Future<void> _pumpEarnings(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final earnings = _MockVendorEarningsRepository();
  final destinations = _MockPayoutDestinationsDataSource();

  when(() => earnings.getEarningsSummary()).thenAnswer(
    (_) async => right(
      VendorEarningsSummary(
        totalRevenue: const Money(amount: 100000, currency: 'NPR'),
        creatorCommission: const Money(amount: 10000, currency: 'NPR'),
        totalOrders: 12,
        thisMonth: const Money(amount: 40000, currency: 'NPR'),
        lastMonth: const Money(amount: 60000, currency: 'NPR'),
        nextPayoutDate: DateTime.utc(2026, 9, 25),
      ),
    ),
  );
  when(() => earnings.getBalance()).thenAnswer(
    (_) async => right(
      const VendorEarningsBalance(
        available: Money(amount: 5000, currency: 'NPR'),
        pending: Money(amount: 2000, currency: 'NPR'),
        lifetime: Money(amount: 7000, currency: 'NPR'),
      ),
    ),
  );
  when(() => earnings.getPayouts()).thenAnswer(
    (_) async => right(
      const PagedResult<VendorPayout>(
        items: [],
        totalCount: 0,
        pageSize: 20,
        hasMore: false,
      ),
    ),
  );
  when(() => destinations.list(2)).thenAnswer((_) async => []);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vendorEarningsRepositoryProvider.overrideWithValue(earnings),
        payoutDestinationsControllerProvider(2).overrideWith(
          (ref) => PayoutDestinationsController(destinations, 2),
        ),
      ],
      child: const MaterialApp(home: VendorEarningsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every string the screen put on screen, plus every spoken label.
List<String> _allText(WidgetTester tester) => [
  ...tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? t.textSpan?.toPlainText() ?? ''),
  ...tester
      .widgetList<Semantics>(find.byType(Semantics))
      .map((s) => s.properties.label ?? ''),
].where((s) => s.isNotEmpty).toList();
