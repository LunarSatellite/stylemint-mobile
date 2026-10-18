import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/data/booking_json.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/domain/service_booking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/presentation/vendor_availability_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_category.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';

import 'service_fixtures.dart';

const _roomA = 'f0000000-0000-4000-8000-00000000000a';
const _roomB = 'f0000000-0000-4000-8000-00000000000b';
const _listing = 'e0000000-0000-4000-8000-000000000001';
const _departure1 = 'd1000000-0000-4000-8000-000000000001';
const _departure2 = 'd1000000-0000-4000-8000-000000000002';

VendorListing _stay() => readVendorListing({
  'listingId': _listing,
  'kind': 1,
  'status': 2,
  'title': 'Hotel Yak & Yeti',
  'roomTypes': [
    {'roomTypeId': _roomA, 'name': 'Deluxe Double', 'totalUnits': 5, 'status': 1},
    {'roomTypeId': _roomB, 'name': 'Suite', 'totalUnits': 2, 'status': 1},
    {'roomTypeId': 'archived', 'name': 'Old wing', 'totalUnits': 3, 'status': 2},
  ],
});

List<RoomNight> _nights({required int tonight, bool closedTomorrow = false}) => [
  readRoomNight({
    'date': '2026-10-21',
    'totalUnits': 5,
    'booked': 5 - tonight,
    'held': 0,
    'available': tonight,
    'closed': false,
  }),
  readRoomNight({
    'date': '2026-10-22',
    'totalUnits': 5,
    'booked': 1,
    'held': 0,
    'available': closedTomorrow ? 0 : 4,
    'closed': closedTomorrow,
  }),
];

void main() {
  setUpAll(registerServiceFallbacks);

  group('hotel: rooms per night', () {
    void stub(MockVendorBookingsRepository repo) {
      when(
        () => repo.listListings(ServiceListingKind.stay),
      ).thenAnswer((_) async => ok([_stay()]));
      when(
        () => repo.getCalendar(
          _roomA,
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => ok(_nights(tonight: 3)));
      when(
        () => repo.getCalendar(
          _roomB,
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => ok(_nights(tonight: 0, closedTomorrow: true)));
    }

    testWidgets('rooms free tonight and the next nights per room type', (
      tester,
    ) async {
      final repo = MockVendorBookingsRepository();
      stub(repo);
      await pumpServiceScreen(
        tester,
        const VendorAvailabilityScreen(),
        bookings: repo,
      );

      expect(find.text('3 rooms free tonight'), findsOneWidget);
      expect(find.text('Deluxe Double'), findsOneWidget);
      expect(find.text('Suite'), findsOneWidget);
      expect(find.text('Old wing'), findsNothing, reason: 'archived');
      expect(find.text('3 free'), findsOneWidget);
      expect(find.text('Full'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);
      verify(
        () => repo.getCalendar(
          _roomA,
          from: serviceTestToday,
          to: DateTime(2026, 11, 3),
        ),
      ).called(1);
    });

    testWidgets('tap a night to close it, tap a closed one to reopen it', (
      tester,
    ) async {
      final repo = MockVendorBookingsRepository();
      stub(repo);
      when(
        () => repo.setNightClosed(any(), any(), closed: any(named: 'closed')),
      ).thenAnswer((_) async => ok(_nights(tonight: 3)));
      await pumpServiceScreen(
        tester,
        const VendorAvailabilityScreen(),
        bookings: repo,
      );

      await tapAndSettle(
        tester,
        find.byKey(VendorAvailabilityScreen.nightKey(_roomA, serviceTestToday)),
      );
      expect(find.text('Close 21 Oct 2026?'), findsOneWidget);
      expect(
        find.textContaining('2 existing bookings stay'),
        findsOneWidget,
      );
      await tapAndSettle(tester, find.byKey(ServiceConfirmDialogKeys.confirm));
      verify(
        () => repo.setNightClosed(_roomA, serviceTestToday, closed: true),
      ).called(1);

      await tapAndSettle(
        tester,
        find.byKey(
          VendorAvailabilityScreen.nightKey(_roomB, DateTime(2026, 10, 22)),
        ),
      );
      expect(find.text('Reopen 22 Oct 2026?'), findsOneWidget);
      await tapAndSettle(tester, find.byKey(ServiceConfirmDialogKeys.confirm));
      verify(
        () => repo.setNightClosed(_roomB, DateTime(2026, 10, 22), closed: false),
      ).called(1);
    });

    testWidgets('says it is being set up while the endpoint is 404', (
      tester,
    ) async {
      final repo = MockVendorBookingsRepository();
      when(
        () => repo.listListings(any()),
      ).thenAnswer((_) async => left(notDeployed));
      await pumpServiceScreen(
        tester,
        const VendorAvailabilityScreen(),
        bookings: repo,
      );
      expect(find.byKey(ServiceSettingUpView.viewKey), findsOneWidget);
      expect(find.text('Availability is being set up'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('travel agency: seats per departure', () {
    void stub(MockVendorBookingsRepository repo) {
      when(() => repo.listListings(ServiceListingKind.package)).thenAnswer(
        (_) async => ok([
          readVendorListing({
            'listingId': _listing,
            'kind': 2,
            'status': 2,
            'title': 'Annapurna Base Camp 7D',
          }),
        ]),
      );
      when(
        () => repo.listDepartures(_listing, from: any(named: 'from')),
      ).thenAnswer(
        (_) async => ok([
          readVendorDeparture({
            'departureId': _departure1,
            'date': '2026-11-02',
            'endDate': '2026-11-08',
            'seatsTotal': 12,
            'seatsAvailable': 5,
            'seatsBooked': 7,
            'status': 1,
          }),
          readVendorDeparture({
            'departureId': _departure2,
            'date': '2026-11-16',
            'seatsTotal': 12,
            'seatsAvailable': 12,
            'status': 2,
          }),
        ]),
      );
    }

    testWidgets('seats left per departure; switch one off and on', (
      tester,
    ) async {
      final repo = MockVendorBookingsRepository();
      stub(repo);
      when(
        () => repo.setDepartureClosed(any(), closed: any(named: 'closed')),
      ).thenAnswer(
        (_) async => ok(
          readVendorDeparture({
            'departureId': _departure1,
            'seatsTotal': 12,
            'seatsAvailable': 5,
            'status': 2,
          }),
        ),
      );
      await pumpServiceScreen(
        tester,
        const VendorAvailabilityScreen(),
        bookings: repo,
        category: ServiceCategory.travelAgency,
      );

      expect(find.text('Seats available'), findsOneWidget);
      expect(find.text('Annapurna Base Camp 7D'), findsOneWidget);
      expect(find.text('5 of 12 seats left'), findsOneWidget);
      expect(find.text('Mon 2 Nov · 2 Nov 2026'), findsOneWidget);

      final open = tester.widget<Switch>(
        find.byKey(VendorAvailabilityScreen.departureSwitchKey(_departure1)),
      );
      expect(open.value, isTrue);
      final closed = tester.widget<Switch>(
        find.byKey(VendorAvailabilityScreen.departureSwitchKey(_departure2)),
      );
      expect(closed.value, isFalse);

      await tapAndSettle(
        tester,
        find.byKey(VendorAvailabilityScreen.departureSwitchKey(_departure1)),
      );
      verify(() => repo.setDepartureClosed(_departure1, closed: true)).called(1);

      await tapAndSettle(
        tester,
        find.byKey(VendorAvailabilityScreen.departureSwitchKey(_departure2)),
      );
      verify(
        () => repo.setDepartureClosed(_departure2, closed: false),
      ).called(1);
    });
  });
}
