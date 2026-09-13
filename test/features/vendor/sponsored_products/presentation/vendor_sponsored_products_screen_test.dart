import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/entities/sponsored_listing.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/repositories/sponsored_products_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/presentation/screens/vendor_sponsored_products_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';

class _MockRepository extends Mock implements SponsoredProductsRepository {}

const _note =
    'Units sold in the last 7 days against the 7 days before. Other things '
    'change too, so treat the difference as a guide, not proof.';

const _live = SponsoredListing(
  id: 'l-1',
  productId: 'p-live',
  productName: 'Linen shirt',
  state: SponsoredListingState.active,
  isLive: true,
  dailyImpressionCap: 500,
  impressionsToday: 12,
  impressionsLast7Days: 1340,
  unitsSoldLast7Days: 9,
  unitsSoldPrevious7Days: 4,
  disclosure:
      'Shoppers see it labelled "Sponsored", only when it matches their '
      'search and is in stock, at most 500 times a day.',
  salesComparisonNote: _note,
);

const _paused = SponsoredListing(
  id: 'l-2',
  productId: 'p-paused',
  productName: 'Canvas tote',
  state: SponsoredListingState.paused,
  isLive: false,
  dailyImpressionCap: 50,
  impressionsLast7Days: 1,
  unitsSoldPrevious7Days: 2,
  salesComparisonNote: _note,
);

final _ended = SponsoredListing(
  id: 'l-3',
  productId: 'p-ended',
  productName: 'Wool coat',
  state: SponsoredListingState.active,
  isLive: false,
  dailyImpressionCap: 300,
  endsUtc: DateTime.utc(2026, 9, 2),
  impressionsToday: 1,
  impressionsLast7Days: 1,
  unitsSoldLast7Days: 1,
  salesComparisonNote: _note,
);

Finder _inCard(String productId, Finder matching) => find.descendant(
  of: find.byKey(ValueKey('sponsored-listing-$productId')),
  matching: matching,
);

void main() {
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(DateTime.utc(2000)));

  setUp(() => repository = _MockRepository());

  void stubList(Either<NetworkExceptions, List<SponsoredListing>> result) {
    when(
      () => repository.getSponsoredListings(),
    ).thenAnswer((_) async => result);
  }

  Future<void> pumpScreen(WidgetTester tester, {bool settle = true}) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sponsoredProductsRepositoryProvider.overrideWithValue(repository),
          sponsorableProductsProvider.overrideWith(
            (ref) async => right(const [
              SponsorProductTarget(
                productId: 'p-new',
                productName: 'Silk scarf',
              ),
            ]),
          ),
        ],
        child: const MaterialApp(home: VendorSponsoredProductsScreen()),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('shows the brand page loader while loading', (tester) async {
    final pending =
        Completer<Either<NetworkExceptions, List<SponsoredListing>>>();
    when(
      () => repository.getSponsoredListings(),
    ).thenAnswer((_) => pending.future);

    await pumpScreen(tester, settle: false);

    expect(find.byType(SmPageLoader), findsOneWidget);
    expect(find.text('Sponsored products'), findsOneWidget);

    pending.complete(right(const []));
    await tester.pumpAndSettle();
    expect(find.byType(SmPageLoader), findsNothing);
  });

  testWidgets('shows Live, Paused and Ended sponsorships with their figures', (
    tester,
  ) async {
    stubList(right([_live, _paused, _ended]));

    await pumpScreen(tester);

    expect(find.text(sponsoredProductsIntro), findsOneWidget);

    expect(_inCard('p-live', find.text('Linen shirt')), findsOneWidget);
    expect(_inCard('p-live', find.text('Live')), findsOneWidget);
    expect(
      _inCard('p-live', find.text('Shown 12 times today · 1,340 this week')),
      findsOneWidget,
    );
    expect(
      _inCard(
        'p-live',
        find.text('Sold 9 in the last 7 days (4 the week before)'),
      ),
      findsOneWidget,
    );
    expect(_inCard('p-live', find.text(_live.disclosure)), findsOneWidget);
    expect(
      _inCard('p-live', find.text('Runs until you pause it')),
      findsOneWidget,
    );
    expect(_inCard('p-live', find.text('Pause')), findsOneWidget);
    expect(_inCard('p-live', find.text('Change')), findsOneWidget);
    expect(_inCard('p-live', find.text('Restart')), findsNothing);

    expect(_inCard('p-paused', find.text('Paused')), findsOneWidget);
    expect(
      _inCard('p-paused', find.text('Shown 0 times today · 1 this week')),
      findsOneWidget,
    );
    expect(
      _inCard(
        'p-paused',
        find.text('Sold 0 in the last 7 days (2 the week before)'),
      ),
      findsOneWidget,
    );
    expect(_inCard('p-paused', find.text('Restart')), findsOneWidget);
    expect(_inCard('p-paused', find.text('Pause')), findsNothing);

    expect(_inCard('p-ended', find.text('Ended')), findsOneWidget);
    expect(
      _inCard('p-ended', find.text('Shown 1 time today · 1 this week')),
      findsOneWidget,
    );
    expect(
      _inCard('p-ended', find.textContaining('Ran through')),
      findsOneWidget,
    );
    expect(_inCard('p-ended', find.text('Restart')), findsOneWidget);
    expect(_inCard('p-ended', find.text('Pause')), findsNothing);

    expect(find.text(_note), findsNWidgets(3));
  });

  testWidgets('Pause switches the card to Paused', (tester) async {
    stubList(right([_live]));
    when(() => repository.pause('p-live')).thenAnswer(
      (_) async => right(
        const SponsoredListing(
          id: 'l-1',
          productId: 'p-live',
          productName: 'Linen shirt',
          state: SponsoredListingState.paused,
          isLive: false,
          dailyImpressionCap: 500,
        ),
      ),
    );

    await pumpScreen(tester);
    await tester.tap(_inCard('p-live', find.text('Pause')));
    await tester.pumpAndSettle();

    verify(() => repository.pause('p-live')).called(1);
    expect(_inCard('p-live', find.text('Paused')), findsOneWidget);
    expect(_inCard('p-live', find.text('Restart')), findsOneWidget);
  });

  testWidgets('a pause 404 shows our copy and re-checks the list', (
    tester,
  ) async {
    stubList(right([_live]));
    when(
      () => repository.pause('p-live'),
    ).thenAnswer((_) async => left(const NetworkExceptions.notFound()));

    await pumpScreen(tester);
    await tester.tap(_inCard('p-live', find.text('Pause')));
    await tester.pumpAndSettle();

    expect(
      find.text("We couldn't find that product in your store."),
      findsOneWidget,
    );
    verify(() => repository.getSponsoredListings()).called(2);
  });

  testWidgets('empty state offers to sponsor a product', (tester) async {
    stubList(right(const []));

    await pumpScreen(tester);

    expect(
      find.text("You aren't sponsoring any products yet."),
      findsOneWidget,
    );
    await tester.tap(find.text('Sponsor a product'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a live product'), findsOneWidget);
    expect(
      find.text('Shoppers always see the Sponsored label.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a retryable error and recovers on retry', (tester) async {
    stubList(left(const NetworkExceptions.serverUnavailable()));

    await pumpScreen(tester);
    expect(
      find.text('Could not load your sponsored products.'),
      findsOneWidget,
    );

    stubList(right([_live]));
    await tester.tap(find.text('Tap to retry'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load your sponsored products.'), findsNothing);
    expect(find.text('Linen shirt'), findsOneWidget);
  });

  testWidgets('Restart on an ended sponsorship opens the form prefilled', (
    tester,
  ) async {
    stubList(right([_ended]));

    await pumpScreen(tester);
    await tester.tap(_inCard('p-ended', find.text('Restart')));
    await tester.pumpAndSettle();

    expect(find.text('Restart sponsorship'), findsOneWidget);
    final cap = tester.widget<TextFormField>(
      find.byKey(const ValueKey('sponsor-daily-cap')),
    );
    expect(cap.controller?.text, '300');
    // Its end date has passed, so it restarts with no end date.
    expect(find.text('No end date. Runs until you pause it.'), findsOneWidget);
  });

  testWidgets('Change saves through the notifier and closes the form', (
    tester,
  ) async {
    stubList(right([_live]));
    when(
      () => repository.sponsor(
        productId: any(named: 'productId'),
        dailyImpressionCap: any(named: 'dailyImpressionCap'),
        endsUtc: any(named: 'endsUtc'),
      ),
    ).thenAnswer((_) async => right(_live));

    await pumpScreen(tester);
    await tester.tap(_inCard('p-live', find.text('Change')));
    await tester.pumpAndSettle();

    expect(find.text('Change sponsorship'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('sponsor-daily-cap')),
      '750',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(
      () => repository.sponsor(productId: 'p-live', dailyImpressionCap: 750),
    ).called(1);
    expect(find.text('Change sponsorship'), findsNothing);
    expect(find.text('Saved. Linen shirt is sponsored.'), findsOneWidget);
  });
}
