import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/booking_checkout_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/booking_confirmed_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/stay_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import 'services_fakes.dart';

const _stayLocation =
    '/services/stays/$stayId?q=Pokhara&checkIn=2026-10-21'
    '&checkOut=2026-10-23&guests=2&rooms=1';

String _text(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data ?? '';

/// From the property page: pick the Deluxe Double and Reserve.
Future<void> _quoteDeluxe(WidgetTester tester) async {
  await tapVisible(tester, find.byKey(StayDetailScreen.roomKey(roomId)));
  await tester.tap(find.byKey(StayDetailScreen.reserveKey));
  await settle(tester);
}

void main() {
  group('Property page', () {
    testWidgets('shows amenities, rooms with nightly price and policies', (
      tester,
    ) async {
      await pumpServices(tester, location: _stayLocation);

      expect(find.text('Wifi'), findsOneWidget);
      expect(find.text('Pool'), findsOneWidget);
      await reveal(tester, find.byKey(StayDetailScreen.roomKey(roomId)));
      expect(
        _text(tester, Key('stay-room-price-$roomId')),
        'Rs 4,500 / night',
      );
      await reveal(tester, find.text('Sold out for these dates'));
      expect(find.text('Sold out for these dates'), findsOneWidget);
      await reveal(tester, find.byKey(const Key('stay-cancellation-policy')));
      expect(
        _text(tester, const Key('stay-cancellation-policy')),
        policy.summary,
      );
      expect(find.text('No smoking in rooms.'), findsOneWidget);
      await reveal(tester, find.byKey(const Key('test-map')));
      expect(find.byKey(Key('test-pin-$stayId')), findsOneWidget);
    });

    testWidgets('Reserve waits for a room to be chosen', (tester) async {
      final repo = FakeBookingsRepository();
      await pumpServices(tester, location: _stayLocation, bookings: repo);

      await tester.tap(find.byKey(StayDetailScreen.reserveKey));
      await settle(tester);
      expect(repo.stayQuotes, isEmpty);
      expect(find.text('Choose a room'), findsOneWidget);
    });

    testWidgets('a sold-out room cannot be picked', (tester) async {
      final repo = FakeBookingsRepository();
      await pumpServices(tester, location: _stayLocation, bookings: repo);

      await tapVisible(tester, find.byKey(StayDetailScreen.roomKey(suiteId)));
      expect(find.text('Choose a room'), findsOneWidget);
    });

    testWidgets('Reserve quotes the room for the dates and guests', (
      tester,
    ) async {
      final repo = FakeBookingsRepository();
      await pumpServices(tester, location: _stayLocation, bookings: repo);

      await _quoteDeluxe(tester);

      final q = repo.stayQuotes.single;
      expect(q['roomTypeId'], roomId);
      expect(q['checkIn'], DateTime(2026, 10, 21));
      expect(q['checkOut'], DateTime(2026, 10, 23));
      expect(q['rooms'], 1);
      expect(q['adults'], 2);
      // The booking screen shows the server's figures.
      expect(find.byType(BookingCheckoutScreen), findsOneWidget);
      expect(_text(tester, BookingCheckoutScreen.totalKey), 'Rs 9,000');
      expect(find.text('Deluxe Double · 21 Oct'), findsOneWidget);
    });

    testWidgets('a quote that comes back unavailable says why and stays', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()
        ..nextStayQuote = () => stayQuote(available: false, reason: 'sold_out');
      await pumpServices(tester, location: _stayLocation, bookings: repo);

      await _quoteDeluxe(tester);

      expect(find.byType(BookingCheckoutScreen), findsNothing);
      await reveal(tester, find.byKey(StayDetailScreen.quoteErrorKey));
      expect(
        _text(tester, StayDetailScreen.quoteErrorKey),
        contains('Sold out'),
      );
    });

    testWidgets('a 404 for the stay page reads as coming soon', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()..failAll = comingSoon;
      await pumpServices(tester, location: _stayLocation, bookings: repo);
      expect(find.byKey(ServicesComingSoon.viewKey), findsOneWidget);
      expect(find.byKey(StayDetailScreen.reserveKey), findsNothing);
    });

    testWidgets('a removed listing (404 with a code) is not "coming soon"', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()
        ..failAll = const ServiceFailure(
          ServiceFailureKind.notFound,
          code: 'service_listing.not_found',
          statusCode: 404,
        );
      await pumpServices(tester, location: _stayLocation, bookings: repo);
      expect(find.byKey(ServicesComingSoon.viewKey), findsNothing);
      expect(find.byKey(const Key('service-not-found')), findsOneWidget);
      expect(find.text('This listing is no longer available.'), findsOneWidget);
    });
  });

  group('Payment mode and pay', () {
    testWidgets('each mode shows what is paid now and at the venue', (
      tester,
    ) async {
      await pumpServices(tester, location: _stayLocation);
      await _quoteDeluxe(tester);

      // Three modes allowed, none chosen yet.
      for (final m in PaymentMode.values) {
        expect(find.byKey(BookingCheckoutScreen.modeKey(m)), findsOneWidget);
      }
      expect(find.text('Choose how to pay'), findsOneWidget);

      await tapVisible(
        tester,
        find.byKey(BookingCheckoutScreen.modeKey(PaymentMode.deposit)),
      );
      expect(_text(tester, BookingCheckoutScreen.payNowKey), 'Rs 2,700');
      expect(_text(tester, BookingCheckoutScreen.payAtVenueKey), 'Rs 6,300');
      expect(find.text('Pay Rs 2,700'), findsOneWidget);

      await tapVisible(
        tester,
        find.byKey(BookingCheckoutScreen.modeKey(PaymentMode.payAtVenue)),
      );
      expect(_text(tester, BookingCheckoutScreen.payNowKey), 'Rs 0');
      expect(_text(tester, BookingCheckoutScreen.payAtVenueKey), 'Rs 9,000');
      expect(find.text('Confirm booking'), findsOneWidget);
      // No rails when nothing is paid online.
      expect(
        find.byKey(BookingCheckoutScreen.railKey(BookingPaymentRail.eSewa)),
        findsNothing,
      );
    });

    testWidgets('only the modes the listing allows are offered', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()
        ..nextStayQuote = () {
          final q = stayQuote();
          return BookingQuote(
            listingId: q.listingId,
            kind: q.kind,
            roomTypeId: q.roomTypeId,
            startDate: q.startDate,
            endDate: q.endDate,
            nights: q.nights,
            rooms: q.rooms,
            adults: q.adults,
            totalPrice: q.totalPrice,
            available: true,
            paymentOptions: [q.paymentOptions.first],
            cancellationPolicy: q.cancellationPolicy,
          );
        };
      await pumpServices(tester, location: _stayLocation, bookings: repo);
      await _quoteDeluxe(tester);

      expect(
        find.byKey(BookingCheckoutScreen.modeKey(PaymentMode.fullPrepay)),
        findsOneWidget,
      );
      expect(
        find.byKey(BookingCheckoutScreen.modeKey(PaymentMode.payAtVenue)),
        findsNothing,
      );
      // The only mode is chosen for the buyer.
      expect(find.text('Pay Rs 9,000'), findsOneWidget);
    });

    testWidgets('deposit: books, pays through the provider page, confirms', (
      tester,
    ) async {
      final repo = FakeBookingsRepository();
      final launched = <Uri>[];
      final router = await pumpServices(
        tester,
        location: _stayLocation,
        bookings: repo,
        launched: launched,
      );
      await _quoteDeluxe(tester);

      await tapVisible(
        tester,
        find.byKey(BookingCheckoutScreen.modeKey(PaymentMode.deposit)),
      );
      // The guest name is prefilled from the profile and editable.
      await reveal(tester, find.byKey(BookingCheckoutScreen.guestNameKey));
      expect(find.text('Sita Sharma'), findsOneWidget);
      await tester.tap(find.byKey(BookingCheckoutScreen.submitKey));
      await settle(tester);

      expect(repo.created.single['mode'], PaymentMode.deposit);
      expect(repo.created.single['guestName'], 'Sita Sharma');
      expect(repo.payments.single['bookingId'], bookingId);
      expect(repo.payments.single['rail'], BookingPaymentRail.eSewa);
      expect(launched.single.toString(), 'https://pay.example/esewa/$bookingId');
      expect(
        router.routeInformationProvider.value.uri.path,
        RouteNames.bookingConfirmedPath(bookingId),
      );
      // The provider has not reported yet: waiting, not confirmed.
      expect(
        _text(tester, BookingConfirmedScreen.headlineKey),
        'Waiting for your payment',
      );
    });

    testWidgets('pay at venue books without any payment', (tester) async {
      final repo = FakeBookingsRepository();
      final launched = <Uri>[];
      await pumpServices(
        tester,
        location: _stayLocation,
        bookings: repo,
        launched: launched,
      );
      await _quoteDeluxe(tester);

      await tapVisible(
        tester,
        find.byKey(BookingCheckoutScreen.modeKey(PaymentMode.payAtVenue)),
      );
      await tester.tap(find.byKey(BookingCheckoutScreen.submitKey));
      await settle(tester);

      expect(repo.created.single['mode'], PaymentMode.payAtVenue);
      expect(repo.payments, isEmpty);
      expect(launched, isEmpty);
      expect(
        _text(tester, BookingConfirmedScreen.headlineKey),
        'Booking confirmed',
      );
      expect(
        _text(tester, const Key('booking-confirmed-balance')),
        'Rs 6,300',
      );
    });

    testWidgets('a guest name is required', (tester) async {
      final repo = FakeBookingsRepository();
      await pumpServices(tester, location: _stayLocation, bookings: repo);
      await _quoteDeluxe(tester);

      await tapVisible(
        tester,
        find.byKey(BookingCheckoutScreen.modeKey(PaymentMode.fullPrepay)),
      );
      await reveal(tester, find.byKey(BookingCheckoutScreen.guestNameKey));
      await tester.enterText(find.byKey(BookingCheckoutScreen.guestNameKey), '');
      await tester.tap(find.byKey(BookingCheckoutScreen.submitKey));
      await settle(tester);

      expect(find.text('Enter a full name'), findsOneWidget);
      expect(repo.created, isEmpty);
    });

    testWidgets('a failed payment retries on the same booking', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()
        ..payFailure = const ServiceFailure(
          ServiceFailureKind.server,
          code: 'booking.payment_unavailable',
          statusCode: 503,
        );
      await pumpServices(tester, location: _stayLocation, bookings: repo);
      await _quoteDeluxe(tester);
      await tapVisible(
        tester,
        find.byKey(BookingCheckoutScreen.modeKey(PaymentMode.fullPrepay)),
      );
      await tester.tap(find.byKey(BookingCheckoutScreen.submitKey));
      await settle(tester);

      await reveal(tester, find.byKey(BookingCheckoutScreen.errorKey));
      expect(
        _text(tester, BookingCheckoutScreen.errorKey),
        contains('Nothing was charged'),
      );
      expect(find.byType(BookingCheckoutScreen), findsOneWidget);

      repo.payFailure = null;
      await tester.tap(find.byKey(BookingCheckoutScreen.submitKey));
      await settle(tester);

      expect(repo.created, hasLength(1), reason: 'never booked twice');
      expect(repo.payments, hasLength(2));
      expect(repo.payments[0]['key'], repo.payments[1]['key']);
      expect(find.byType(BookingConfirmedScreen), findsOneWidget);
    });

    testWidgets('sold out at booking time explains and stays', (tester) async {
      final repo = FakeBookingsRepository()
        ..bookingFailure = const ServiceFailure(
          ServiceFailureKind.conflict,
          code: 'booking.unavailable',
          statusCode: 409,
        );
      await pumpServices(tester, location: _stayLocation, bookings: repo);
      await _quoteDeluxe(tester);
      await tapVisible(
        tester,
        find.byKey(BookingCheckoutScreen.modeKey(PaymentMode.fullPrepay)),
      );
      await tester.tap(find.byKey(BookingCheckoutScreen.submitKey));
      await settle(tester);

      await reveal(tester, find.byKey(BookingCheckoutScreen.errorKey));
      expect(
        _text(tester, BookingCheckoutScreen.errorKey),
        contains('just taken'),
      );
      expect(repo.payments, isEmpty);
    });
  });
}
