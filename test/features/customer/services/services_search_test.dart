import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_search.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/services_home_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/stay_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/stay_results_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/travel_results_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import 'services_fakes.dart';

void main() {
  group('Services home', () {
    testWidgets('shows Stays, Travel and Banks with My bookings', (
      tester,
    ) async {
      await pumpServices(tester, location: RouteNames.services);

      expect(find.byKey(const Key('services-tab-stays')), findsOneWidget);
      expect(find.byKey(const Key('services-tab-travel')), findsOneWidget);
      expect(find.byKey(const Key('services-tab-banks')), findsOneWidget);
      expect(find.byKey(ServicesHomeScreen.myBookingsKey), findsOneWidget);
      expect(find.byKey(StaySearchForm.locationKey), findsOneWidget);
    });

    testWidgets('a stay search needs a city or area', (tester) async {
      final repo = FakeBookingsRepository();
      await pumpServices(tester, location: RouteNames.services, bookings: repo);

      await tester.tap(find.byKey(StaySearchForm.submitKey));
      await settle(tester);

      expect(find.byKey(StaySearchForm.errorKey), findsOneWidget);
      expect(repo.searches, isEmpty);
    });

    testWidgets('searching stays opens results for the dates and guests', (
      tester,
    ) async {
      final repo = FakeBookingsRepository();
      await pumpServices(
        tester,
        location: RouteNames.services,
        bookings: repo,
      );

      await tester.enterText(find.byKey(StaySearchForm.locationKey), 'Pokhara');
      await tester.tap(find.byKey(const Key('stay-guests-plus')));
      await tester.tap(find.byKey(const Key('stay-rooms-plus')));
      await settle(tester);
      expect(
        tester.widget<Text>(find.byKey(const Key('stay-guests-value'))).data,
        '3',
      );
      await tester.tap(find.byKey(StaySearchForm.submitKey));
      await settle(tester);

      final s = tester
          .widget<StayResultsScreen>(find.byType(StayResultsScreen))
          .search!;
      // Tomorrow (Kathmandu) for one night.
      expect(s.checkIn, DateTime(2026, 10, 19));
      expect(s.checkOut, DateTime(2026, 10, 20));
      expect(s.location, 'Pokhara');
      expect(s.guests, 3);
      expect(s.rooms, 2);

      expect(repo.searches.single.location, 'Pokhara');
      expect(repo.searches.single.guests, 3);
      expect(find.byKey(Key('stay-result-$stayId')), findsOneWidget);
      expect(find.text('Rs 9,000'), findsOneWidget);
      // The stay has coordinates, so it is pinned on the map.
      expect(find.byKey(Key('test-pin-$stayId')), findsOneWidget);
    });

    testWidgets('a pin on the results map opens that stay', (tester) async {
      await pumpServices(
        tester,
        location:
            '${RouteNames.serviceStayResults}?q=Pokhara&checkIn=2026-10-21'
            '&checkOut=2026-10-23&guests=2&rooms=1',
      );

      await tester.tap(find.byKey(Key('test-pin-$stayId')));
      await settle(tester);

      final detail = tester.widget<StayDetailScreen>(
        find.byType(StayDetailScreen),
      );
      expect(detail.listingId, stayId);
      expect(detail.search!.checkIn, DateTime(2026, 10, 21));
      expect(find.byKey(StayDetailScreen.reserveKey), findsOneWidget);
    });

    testWidgets('no stays for the dates says so', (tester) async {
      final repo = FakeBookingsRepository()..stays = [];
      await pumpServices(
        tester,
        location:
            '${RouteNames.serviceStayResults}?q=Jomsom&checkIn=2026-10-21'
            '&checkOut=2026-10-23',
        bookings: repo,
      );
      expect(find.byKey(const Key('stay-results-empty')), findsOneWidget);
    });

    testWidgets('stay results 404 reads as coming soon, not an error', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()..failAll = comingSoon;
      await pumpServices(
        tester,
        location:
            '${RouteNames.serviceStayResults}?q=Pokhara&checkIn=2026-10-21'
            '&checkOut=2026-10-23',
        bookings: repo,
      );
      expect(find.byKey(ServicesComingSoon.viewKey), findsOneWidget);
      expect(find.text('Services are coming soon'), findsOneWidget);
      expect(find.byKey(const Key('service-error')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a 500 shows a retryable error', (tester) async {
      final repo = FakeBookingsRepository()
        ..failAll = serverDown;
      await pumpServices(
        tester,
        location:
            '${RouteNames.serviceStayResults}?q=Pokhara&checkIn=2026-10-21'
            '&checkOut=2026-10-23',
        bookings: repo,
      );
      expect(find.byKey(const Key('service-error')), findsOneWidget);
      expect(find.byKey(ServicesComingSoon.viewKey), findsNothing);
    });
  });

  group('Travel search', () {
    testWidgets('destination, month and travellers open trips', (
      tester,
    ) async {
      final repo = FakeBookingsRepository();
      await pumpServices(
        tester,
        location: RouteNames.services,
        bookings: repo,
      );

      await tester.tap(find.byKey(const Key('services-tab-travel')));
      await settle(tester);
      await tester.enterText(
        find.byKey(TravelSearchForm.destinationKey),
        'Annapurna',
      );
      // Next month (November 2026).
      // Selected the way a tap would; the chip row scrolls sideways.
      tester
          .widget<ChoiceChip>(find.byKey(TravelSearchForm.monthKey(1)))
          .onSelected!(true);
      await tester.pump();
      await tester.tap(find.byKey(const Key('travel-travellers-plus')));
      await settle(tester);
      await tester.tap(find.byKey(TravelSearchForm.submitKey));
      await settle(tester);

      final t = tester
          .widget<TravelResultsScreen>(find.byType(TravelResultsScreen))
          .search;
      expect(t.monthWire, '2026-11');
      expect(t.travellers, 3);
      expect(repo.travelSearches.single, isA<TravelSearch>());
      expect(repo.travelSearches.single.destination, 'Annapurna');
      expect(repo.travelSearches.single.monthWire, '2026-11');
      expect(find.byKey(Key('package-result-$packageId')), findsOneWidget);
    });

    testWidgets('trips 404 reads as coming soon', (tester) async {
      final repo = FakeBookingsRepository()..failAll = comingSoon;
      await pumpServices(
        tester,
        location: '${RouteNames.serviceTravelResults}?q=Annapurna',
        bookings: repo,
      );
      expect(find.byKey(ServicesComingSoon.viewKey), findsOneWidget);
    });
  });

  group('Search values', () {
    test('a stay search round-trips through its query', () {
      final s = StaySearch(
        location: 'Thamel',
        checkIn: DateTime(2026, 10, 21),
        checkOut: DateTime(2026, 10, 24),
        guests: 3,
        rooms: 2,
      );
      expect(StaySearch.fromQuery(s.toQuery()), s);
      expect(s.nights, 3);
      expect(s.isValid, isTrue);
    });

    test('a stay search without dates cannot be read', () {
      expect(StaySearch.fromQuery(const {'q': 'Thamel'}), isNull);
    });

    test('Kathmandu is ahead of UTC by 5:45', () {
      expect(
        kathmanduDay(DateTime.utc(2026, 10, 18, 18, 20)),
        DateTime(2026, 10, 19),
      );
      expect(
        kathmanduDay(DateTime.utc(2026, 10, 18, 18, 10)),
        DateTime(2026, 10, 18),
      );
    });
  });
}
