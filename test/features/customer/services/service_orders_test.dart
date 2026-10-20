import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/orders/order_bookings_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/orders/orders_services_strip.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/booking_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_line_widgets.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import 'services_fakes.dart';

/// A stand-in page that shows [widget] at `/host`, inside the app's real
/// service routes (booking detail, bookings, bank requests).
GoRoute _host(Widget widget) => GoRoute(
  path: '/host',
  builder: (_, _) => Scaffold(body: SingleChildScrollView(child: widget)),
);

void main() {
  group('an order\'s bookings', () {
    testWidgets('show the reference, state, dates and the two amounts', (
      tester,
    ) async {
      await pumpServices(
        tester,
        location: '/host',
        extraRoutes: [
          _host(
            OrderBookingsCard(
              lines: [
                stayLine(
                  bookingId: bookingId,
                  state: BookingState.confirmed,
                  canCancel: true,
                ),
              ],
              payAtVenue: npr(6300),
            ),
          ),
        ],
      );
      expect(
        tester
            .widget<Text>(find.byKey(OrderBookingsCard.referenceKey(bookingId)))
            .data,
        'Booking BK-7F3A9C21',
      );
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Paid now'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(ServiceLineSummary.payNowKey('line-stay')))
            .data,
        'Rs 2,700',
      );
      expect(find.byKey(const Key('order-pay-at-venue')), findsOneWidget);
      expect(find.byKey(OrderBookingsCard.cancelKey(bookingId)), findsOneWidget);
    });

    testWidgets('Cancel booking opens the booking and its refund preview', (
      tester,
    ) async {
      final repo = FakeBookingsRepository();
      await pumpServices(
        tester,
        location: '/host',
        bookings: repo,
        extraRoutes: [
          _host(
            OrderBookingsCard(
              lines: [stayLine(bookingId: bookingId, canCancel: true)],
            ),
          ),
        ],
      );
      await tapVisible(tester, find.byKey(OrderBookingsCard.cancelKey(bookingId)));
      expect(find.byType(BookingDetailScreen), findsOneWidget);
      await tapVisible(tester, find.byKey(BookingDetailScreen.cancelKey));
      expect(repo.previews, 1);
      expect(find.byKey(BookingDetailScreen.previewRefundKey), findsOneWidget);
    });

    testWidgets('a booking that cannot be cancelled offers only a view', (
      tester,
    ) async {
      await pumpServices(
        tester,
        location: '/host',
        extraRoutes: [
          _host(OrderBookingsCard(lines: [stayLine(bookingId: bookingId)])),
        ],
      );
      expect(find.byKey(OrderBookingsCard.openKey(bookingId)), findsOneWidget);
      expect(find.byKey(OrderBookingsCard.cancelKey(bookingId)), findsNothing);
    });

    testWidgets('an order with no bookings shows nothing', (tester) async {
      await pumpServices(
        tester,
        location: '/host',
        extraRoutes: [_host(const OrderBookingsCard(lines: []))],
      );
      expect(find.byKey(OrderBookingsCard.cardKey), findsNothing);
    });
  });

  group('booking detail', () {
    testWidgets('names the order it was bought in, and is never paid here', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()
        ..bookings = [
          booking(
            state: BookingState.pendingPayment,
            canPay: true,
            orderNumber: 'NK2026-00042',
          ),
        ];
      await pumpServices(
        tester,
        location: RouteNames.bookingDetailPath(bookingId),
        bookings: repo,
      );
      expect(find.byKey(BookingDetailScreen.orderKey), findsOneWidget);
      expect(find.text('NK2026-00042'), findsOneWidget);
      expect(find.byKey(BookingDetailScreen.payKey), findsNothing);
    });
  });

  group('the Orders entry points', () {
    testWidgets('My orders shows the next booking with its reference, and '
        'the ways to bookings and bank requests', (tester) async {
      await pumpServices(
        tester,
        location: '/host',
        extraRoutes: [_host(const OrdersServicesStrip())],
      );
      expect(find.byKey(Key('booking-tile-$bookingId')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(Key('booking-tile-ref-$bookingId')))
            .data,
        'Booking BK-7F3A9C21',
      );

      await tester.tap(find.byKey(OrdersServicesStrip.bankRequestsKey));
      await settle(tester);
      // The bookings screen, on its Banks tab.
      expect(find.byKey(Key('enquiry-tile-$leadId')), findsOneWidget);
      expect(find.byKey(Key('appointment-tile-$appointmentId')), findsOneWidget);
    });

    testWidgets('with no bookings, only the links', (tester) async {
      await pumpServices(
        tester,
        location: '/host',
        bookings: FakeBookingsRepository()..bookings = [],
        extraRoutes: [_host(const OrdersServicesStrip())],
      );
      expect(find.byKey(Key('booking-tile-$bookingId')), findsNothing);
      await tester.tap(find.byKey(OrdersServicesStrip.bookingsKey));
      await settle(tester);
      expect(find.byKey(const Key('my-bookings-empty-upcoming')), findsOneWidget);
    });

    testWidgets('the bookings service not deployed yet: only the links', (
      tester,
    ) async {
      await pumpServices(
        tester,
        location: '/host',
        bookings: FakeBookingsRepository()..failAll = comingSoon,
        extraRoutes: [_host(const OrdersServicesStrip())],
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(OrdersServicesStrip.bookingsKey), findsOneWidget);
    });
  });

  group('v1 links', () {
    testWidgets('a v1 booking link opens the booking under Orders', (
      tester,
    ) async {
      await pumpServices(tester, location: '/services/bookings/$bookingId');
      expect(find.byType(BookingDetailScreen), findsOneWidget);
    });

    testWidgets('a v1 appointment link opens the appointment', (tester) async {
      final router = await pumpServices(
        tester,
        location: '/services/banks/appointments/$appointmentId',
      );
      expect(
        router.routeInformationProvider.value.uri.path,
        RouteNames.bankAppointmentDetailPath(appointmentId),
      );
    });
  });
}
