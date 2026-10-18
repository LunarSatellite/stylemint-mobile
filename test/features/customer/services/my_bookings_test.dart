import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/booking_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import 'services_fakes.dart';

String _text(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data ?? '';

void main() {
  group('My bookings', () {
    testWidgets('splits upcoming from past', (tester) async {
      final repo = FakeBookingsRepository()
        ..bookings = [
          booking(),
          booking(
            id: pastBookingId,
            state: BookingState.completed,
            start: DateTime(2026, 9, 1),
            end: DateTime(2026, 9, 3),
          ),
        ];
      await pumpServices(
        tester,
        location: RouteNames.myBookings,
        bookings: repo,
      );

      expect(find.byKey(Key('booking-tile-$bookingId')), findsOneWidget);
      expect(find.byKey(Key('booking-tile-$pastBookingId')), findsNothing);
      expect(find.text('Rs 6,300 to pay at the venue'), findsOneWidget);

      await tester.tap(find.byKey(const Key('my-bookings-tab-past')));
      await settle(tester);
      expect(find.byKey(Key('booking-tile-$pastBookingId')), findsOneWidget);
      expect(find.byKey(Key('booking-tile-$bookingId')), findsNothing);
    });

    testWidgets('bank enquiries and appointments show with their status', (
      tester,
    ) async {
      await pumpServices(tester, location: RouteNames.myBookings);
      await tester.tap(find.byKey(const Key('my-bookings-tab-banks')));
      await settle(tester);

      expect(find.byKey(Key('enquiry-tile-$leadId')), findsOneWidget);
      expect(find.byKey(Key('appointment-tile-$appointmentId')), findsOneWidget);
      expect(find.text('Sent'), findsOneWidget);
      expect(find.text('Booked'), findsOneWidget);
    });

    testWidgets('no bookings says so', (tester) async {
      final repo = FakeBookingsRepository()..bookings = [];
      await pumpServices(
        tester,
        location: RouteNames.myBookings,
        bookings: repo,
      );
      expect(
        find.byKey(const Key('my-bookings-empty-upcoming')),
        findsOneWidget,
      );
    });

    testWidgets('bookings 404 reads as coming soon', (tester) async {
      final repo = FakeBookingsRepository()..failAll = comingSoon;
      await pumpServices(
        tester,
        location: RouteNames.myBookings,
        bookings: repo,
      );
      expect(find.byKey(ServicesComingSoon.viewKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Booking detail', () {
    testWidgets('dates, guests, paid, balance at the venue and policy', (
      tester,
    ) async {
      await pumpServices(
        tester,
        location: RouteNames.bookingDetailPath(bookingId),
      );

      expect(
        _text(tester, const Key('booking-detail-dates')),
        'Wed, 21 Oct → Fri, 23 Oct',
      );
      expect(_text(tester, const Key('booking-detail-guests')), '2 guests');
      await reveal(tester, find.byKey(const Key('booking-detail-balance')));
      expect(_text(tester, const Key('booking-detail-paid')), 'Rs 2,700');
      expect(_text(tester, const Key('booking-detail-balance')), 'Rs 6,300');
      await reveal(tester, find.byKey(const Key('booking-detail-policy')));
      expect(
        _text(tester, const Key('booking-detail-policy')),
        policy.summary,
      );
    });

    testWidgets('Cancel shows the refund preview before cancelling', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()
        ..cancelPreview = CancellationQuote(
          bookingId: bookingId,
          cancellable: true,
          fee: npr(4500),
          refundAmount: npr(0),
          freeUntilDate: DateTime(2026, 10, 18),
        );
      await pumpServices(
        tester,
        location: RouteNames.bookingDetailPath(bookingId),
        bookings: repo,
      );

      await tapVisible(tester, find.byKey(BookingDetailScreen.cancelKey));
      expect(repo.previews, 1);
      expect(_text(tester, BookingDetailScreen.previewFeeKey), 'Rs 4,500');
      expect(_text(tester, BookingDetailScreen.previewRefundKey), 'Rs 0');
      expect(repo.cancels, isEmpty, reason: 'nothing cancelled yet');

      // Keeping it changes nothing.
      await tester.tap(find.byKey(BookingDetailScreen.keepKey));
      await settle(tester);
      expect(repo.cancels, isEmpty);
    });

    testWidgets('confirming the preview cancels and shows the refund', (
      tester,
    ) async {
      final repo = FakeBookingsRepository();
      await pumpServices(
        tester,
        location: RouteNames.bookingDetailPath(bookingId),
        bookings: repo,
      );

      await tapVisible(tester, find.byKey(BookingDetailScreen.cancelKey));
      expect(_text(tester, BookingDetailScreen.previewRefundKey), 'Rs 2,700');
      await tester.tap(find.byKey(BookingDetailScreen.confirmCancelKey));
      await settle(tester);

      expect(repo.cancels, [bookingId]);
      expect(find.text('Cancelled'), findsOneWidget);
      await reveal(tester, find.byKey(const Key('booking-detail-refund')));
      expect(_text(tester, const Key('booking-detail-refund')), 'Rs 2,700');
      expect(find.byKey(BookingDetailScreen.cancelKey), findsNothing);
    });

    testWidgets('a booking that has started cannot be cancelled', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()
        ..cancelPreview = CancellationQuote(
          bookingId: bookingId,
          cancellable: false,
          reason: 'started',
          fee: npr(0),
          refundAmount: npr(0),
        );
      await pumpServices(
        tester,
        location: RouteNames.bookingDetailPath(bookingId),
        bookings: repo,
      );

      await tapVisible(tester, find.byKey(BookingDetailScreen.cancelKey));
      expect(find.byKey(BookingDetailScreen.confirmCancelKey), findsNothing);
      await reveal(tester, find.byKey(BookingDetailScreen.errorKey));
      expect(
        _text(tester, BookingDetailScreen.errorKey),
        contains('already started'),
      );
      expect(repo.cancels, isEmpty);
    });

    testWidgets('an unpaid booking can be paid from its page', (tester) async {
      final repo = FakeBookingsRepository()
        ..bookings = [
          booking(state: BookingState.pendingPayment, canPay: true),
        ];
      final launched = <Uri>[];
      await pumpServices(
        tester,
        location: RouteNames.bookingDetailPath(bookingId),
        bookings: repo,
        launched: launched,
      );

      await tapVisible(tester, find.byKey(BookingDetailScreen.payKey));
      expect(repo.payments.single['bookingId'], bookingId);
      expect(launched, hasLength(1));
    });

    testWidgets('someone else\'s or a missing booking is "not found"', (
      tester,
    ) async {
      await pumpServices(
        tester,
        location: RouteNames.bookingDetailPath(pastBookingId),
      );
      expect(find.byKey(const Key('service-not-found')), findsOneWidget);
      expect(find.text('We could not find this booking.'), findsOneWidget);
    });
  });
}
