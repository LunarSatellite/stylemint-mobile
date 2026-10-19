import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/data/booking_json.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/data/vendor_bookings_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/domain/service_booking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/presentation/booking_widgets.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/presentation/vendor_booking_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/presentation/vendor_bookings_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_category.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import 'service_fixtures.dart';

BookingsTodayBoard _board() => BookingsTodayBoard(
  arrivals: [booking()],
  leaving: [
    booking(
      id: booking2Id,
      number: 'BK-00000002',
      state: 3,
      guestName: 'Hari Gurung',
      startDate: '2026-10-19',
      endDate: '2026-10-21',
    ),
  ],
  inHouse: [
    booking(
      id: booking3Id,
      number: 'BK-00000003',
      state: 3,
      guestName: 'Gita Rai',
      startDate: '2026-10-20',
      endDate: '2026-10-24',
      balanceDue: 0,
    ),
  ],
);

void _stubLists(
  MockVendorBookingsRepository repo, {
  BookingsTodayBoard? board,
  List<ServiceBooking>? upcoming,
  ServiceFailure? failure,
}) {
  when(() => repo.getToday(any())).thenAnswer(
    (_) async => failure != null ? left(failure) : ok(board ?? _board()),
  );
  when(() => repo.getSummary()).thenAnswer(
    (_) async => failure != null
        ? left(failure)
        : ok(
            const BookingsSummary(
              upcoming: 4,
              inHouse: 2,
              pendingPayment: 1,
              balanceToCollect: Money(amount: 12600, currency: 'NPR'),
            ),
          ),
  );
  when(
    () => repo.getUpcoming(any(), days: any(named: 'days')),
  ).thenAnswer(
    (_) async => failure != null ? left(failure) : ok(upcoming ?? const []),
  );
  when(
    () => repo.listBookings(
      state: any(named: 'state'),
      query: any(named: 'query'),
      cursor: any(named: 'cursor'),
    ),
  ).thenAnswer(
    (_) async => failure != null ? left(failure) : ok(page([booking()])),
  );
}

void main() {
  setUpAll(registerServiceFallbacks);

  group('reading bookings (contract v1)', () {
    test('a vendor booking: names, dates, money and the allowed actions', () {
      final b = booking();
      expect(b.number, 'BK-7F3A9C21');
      expect(b.kind, ServiceListingKind.stay);
      expect(b.state, BookingState.confirmed);
      expect(b.startDate, DateTime(2026, 10, 21));
      expect(b.endDate, DateTime(2026, 10, 23));
      expect(b.guestName, 'Sita Sharma');
      expect(b.travellers.map((t) => t.fullName), ['Sita Sharma', 'Mina Sharma']);
      expect(b.travellers.last.isChild, isTrue);
      expect(b.guestsText, '2 adults, 1 child');
      expect(b.total.amount, 9000);
      expect(b.paidOnline.amount, 2700);
      expect(b.balanceDue.amount, 6300);
      expect(b.paymentMode, BookingPaymentMode.deposit);
      expect(b.canCheckIn && b.canComplete && b.canCancel, isTrue);
      expect(b.vendorCancelRefund.amount, 2700);
      expect(bookingDatesText(b), 'Wed 21 Oct → Fri 23 Oct · 2 nights');
    });

    test('balance due is worked out when a server leaves it out', () {
      final json = bookingWire()..remove('balanceDue');
      json['balanceReceivedAmount'] = 1000;
      expect(readServiceBooking(json).balanceDue.amount, 9000 - 2700 - 1000);
    });

    test('a checked-in package reads as in progress', () {
      final b = booking(kind: 2, state: 3);
      expect(b.state.labelFor(b.kind), 'In progress');
      expect(b.isStay, isFalse);
    });
  });

  group('bookings list', () {
    testWidgets('today: arriving, checking out and in house', (tester) async {
      final repo = MockVendorBookingsRepository();
      _stubLists(repo);
      await pumpServiceScreen(tester, const VendorBookingsScreen(), bookings: repo);

      expect(find.text('Arriving today (1)'), findsOneWidget);
      expect(find.text('Checking out today (1)'), findsOneWidget);
      expect(find.text('In house (1)'), findsOneWidget);
      expect(find.text('Sita Sharma'), findsOneWidget);
      expect(find.text('Hari Gurung'), findsOneWidget);
      expect(find.text('Gita Rai'), findsOneWidget);
      expect(find.text('Collect Rs 6,300'), findsWidgets);
      expect(
        find.text('Rs 12,600 still to collect at the venue'),
        findsOneWidget,
      );
      verify(() => repo.getToday(serviceTestToday)).called(1);
      // Guest names only: nothing that looks like a phone or an email.
      expect(find.textContaining('@'), findsNothing);
      expect(find.textContaining('+977'), findsNothing);

      await tapAndSettle(
        tester,
        find.byKey(ServiceBookingTile.keyFor(bookingId)),
      );
      expect(find.text('booking page $bookingId'), findsOneWidget);
    });

    testWidgets('a travel agency reads trips, not rooms', (tester) async {
      final repo = MockVendorBookingsRepository();
      _stubLists(repo);
      await pumpServiceScreen(
        tester,
        const VendorBookingsScreen(),
        bookings: repo,
        category: ServiceCategory.travelAgency,
      );
      expect(find.text('Starting today (1)'), findsOneWidget);
      expect(find.text('Finishing today (1)'), findsOneWidget);
      expect(find.text('On trip now (1)'), findsOneWidget);
    });

    testWidgets('upcoming bookings are grouped by start date', (tester) async {
      final repo = MockVendorBookingsRepository();
      _stubLists(
        repo,
        upcoming: [
          booking(startDate: '2026-10-22', endDate: '2026-10-24'),
          booking(
            id: booking2Id,
            guestName: 'Hari Gurung',
            startDate: '2026-10-22',
            endDate: '2026-10-23',
          ),
          booking(
            id: booking3Id,
            guestName: 'Gita Rai',
            startDate: '2026-10-25',
            endDate: '2026-10-27',
          ),
        ],
      );
      await pumpServiceScreen(tester, const VendorBookingsScreen(), bookings: repo);
      await tapAndSettle(tester, find.byKey(VendorBookingsScreen.upcomingTabKey));
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Sun 25 Oct'), findsOneWidget);
      expect(find.text('Hari Gurung'), findsOneWidget);
      expect(find.text('Gita Rai'), findsOneWidget);
    });

    testWidgets('all bookings: search by number or guest name', (tester) async {
      final repo = MockVendorBookingsRepository();
      _stubLists(repo);
      await pumpServiceScreen(tester, const VendorBookingsScreen(), bookings: repo);
      await tapAndSettle(tester, find.byKey(VendorBookingsScreen.allTabKey));
      await tester.enterText(
        find.byKey(const Key('vendor-bookings-search')),
        'Sita',
      );
      await tester.pump(const Duration(milliseconds: 450));
      await settle(tester);
      verify(
        () => repo.listBookings(state: null, query: 'Sita', cursor: null),
      ).called(1);

      await tapAndSettle(
        tester,
        find.byKey(const Key('vendor-bookings-state-checkedIn')),
      );
      verify(
        () => repo.listBookings(
          state: BookingState.checkedIn,
          query: 'Sita',
          cursor: null,
        ),
      ).called(1);
    });

    testWidgets('says it is being set up while the endpoints are 404', (
      tester,
    ) async {
      final repo = MockVendorBookingsRepository();
      _stubLists(repo, failure: notDeployed);
      await pumpServiceScreen(tester, const VendorBookingsScreen(), bookings: repo);
      expect(find.byKey(ServiceSettingUpView.viewKey), findsOneWidget);
      expect(find.text('Bookings are being set up'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('booking detail', () {
    void stubOne(MockVendorBookingsRepository repo, ServiceBooking b) {
      when(() => repo.getBooking(b.id)).thenAnswer((_) async => ok(b));
    }

    testWidgets('shows the stay, the guests by name and the money', (
      tester,
    ) async {
      final repo = MockVendorBookingsRepository();
      stubOne(repo, booking());
      await pumpServiceScreen(
        tester,
        const VendorBookingDetailScreen(bookingId: bookingId),
        bookings: repo,
      );

      expect(find.text('Sita Sharma'), findsWidgets);
      expect(find.text('Hotel Yak & Yeti'), findsOneWidget);
      expect(find.text('Deluxe Double'), findsOneWidget);
      expect(find.text('21 Oct 2026, from 14:00'), findsOneWidget);
      expect(find.text('23 Oct 2026, by 12:00'), findsOneWidget);
      expect(find.text('2 adults, 1 child'), findsOneWidget);
      expect(find.text('Mina Sharma · child, 9'), findsOneWidget);
      expect(find.text('Late arrival'), findsOneWidget);
      expect(find.text('30% deposit online, rest at venue'), findsOneWidget);
      expect(find.text('Rs 9,000'), findsOneWidget);
      expect(find.text('Rs 2,700'), findsOneWidget);
      expect(find.text('Rs 6,300'), findsOneWidget);
      expect(find.textContaining('@'), findsNothing);
      expect(find.textContaining('+977'), findsNothing);
    });

    testWidgets('check in, then the server decides what comes next', (
      tester,
    ) async {
      final repo = MockVendorBookingsRepository();
      stubOne(repo, booking());
      when(() => repo.checkIn(bookingId)).thenAnswer(
        (_) async => ok(
          booking(
            state: 3,
            canCheckIn: false,
            canMarkNoShow: false,
          ),
        ),
      );
      await pumpServiceScreen(
        tester,
        const VendorBookingDetailScreen(bookingId: bookingId),
        bookings: repo,
      );

      await tapAndSettle(tester, find.byKey(VendorBookingDetailScreen.checkInKey));
      verify(() => repo.checkIn(bookingId)).called(1);
      expect(find.text('Checked in'), findsWidgets);
      expect(find.byKey(VendorBookingDetailScreen.checkInKey), findsNothing);
      expect(find.byKey(VendorBookingDetailScreen.noShowKey), findsNothing);
      expect(find.byKey(VendorBookingDetailScreen.completeKey), findsOneWidget);
    });

    testWidgets('mark completed and no-show', (tester) async {
      final repo = MockVendorBookingsRepository();
      stubOne(repo, booking());
      when(() => repo.markNoShow(bookingId)).thenAnswer(
        (_) async => ok(
          booking(
            state: 6,
            canCheckIn: false,
            canComplete: false,
            canMarkNoShow: false,
            canCancel: false,
            canMarkBalanceReceived: false,
          ),
        ),
      );
      await pumpServiceScreen(
        tester,
        const VendorBookingDetailScreen(bookingId: bookingId),
        bookings: repo,
      );
      await tapAndSettle(tester, find.byKey(VendorBookingDetailScreen.noShowKey));
      expect(find.text('Mark as no-show?'), findsOneWidget);
      await tapAndSettle(tester, find.byKey(ServiceConfirmDialogKeys.confirm));
      verify(() => repo.markNoShow(bookingId)).called(1);
      expect(find.text('No-show'), findsOneWidget);
      expect(
        find.text('Nothing to do on this booking right now.'),
        findsOneWidget,
      );
    });

    testWidgets('mark the whole balance received, or part of it', (
      tester,
    ) async {
      final repo = MockVendorBookingsRepository();
      stubOne(repo, booking());
      when(
        () => repo.markBalanceReceived(
          any(),
          amount: any(named: 'amount'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => ok(booking(balanceDue: 3300)));
      await pumpServiceScreen(
        tester,
        const VendorBookingDetailScreen(bookingId: bookingId),
        bookings: repo,
      );

      await tapAndSettle(tester, find.byKey(VendorBookingDetailScreen.balanceKey));
      expect(
        find.text(
          'Sita Sharma still owes Rs 6,300 at the venue. How much did you '
          'receive?',
        ),
        findsOneWidget,
      );
      // Prefilled with the whole balance: sent as "the full balance".
      await tapAndSettle(
        tester,
        find.byKey(VendorBookingDetailScreen.balanceConfirmKey),
      );
      verify(() => repo.markBalanceReceived(bookingId)).called(1);

      await tapAndSettle(tester, find.byKey(VendorBookingDetailScreen.balanceKey));
      await tester.enterText(
        find.byKey(VendorBookingDetailScreen.balanceAmountKey),
        '3000',
      );
      await tester.pump();
      await tapAndSettle(
        tester,
        find.byKey(VendorBookingDetailScreen.balanceConfirmKey),
      );
      verify(
        () => repo.markBalanceReceived(bookingId, amount: 3000),
      ).called(1);
    });

    testWidgets('more than the balance cannot be recorded', (tester) async {
      final repo = MockVendorBookingsRepository();
      stubOne(repo, booking());
      await pumpServiceScreen(
        tester,
        const VendorBookingDetailScreen(bookingId: bookingId),
        bookings: repo,
      );
      await tapAndSettle(tester, find.byKey(VendorBookingDetailScreen.balanceKey));
      await tester.enterText(
        find.byKey(VendorBookingDetailScreen.balanceAmountKey),
        '7000',
      );
      await tester.pump();
      final confirm = tester.widget<TextButton>(
        find.byKey(VendorBookingDetailScreen.balanceConfirmKey),
      );
      expect(confirm.onPressed, isNull);
      expect(find.text('Between 1 and Rs 6,300'), findsOneWidget);
    });

    testWidgets('cancel shows the full refund first, then asks why', (
      tester,
    ) async {
      final repo = MockVendorBookingsRepository();
      stubOne(repo, booking());
      when(() => repo.cancel(any(), any())).thenAnswer(
        (_) async => ok(
          readServiceBooking(
            bookingWire(
              state: 5,
              canCheckIn: false,
              canComplete: false,
              canMarkNoShow: false,
              canCancel: false,
              canMarkBalanceReceived: false,
            )
              ..['cancelledBy'] = 2
              ..['cancelReason'] = 'Overbooked'
              ..['refundAmount'] = 2700
              ..['refundState'] = 1,
          ),
        ),
      );
      await pumpServiceScreen(
        tester,
        const VendorBookingDetailScreen(bookingId: bookingId),
        bookings: repo,
      );

      await tapAndSettle(tester, find.byKey(VendorBookingDetailScreen.cancelKey));
      expect(
        find.text(
          'Sita Sharma gets a full refund of Rs 2,700 — everything paid '
          'online. No cancellation fee applies when you cancel.',
        ),
        findsOneWidget,
      );
      final confirm = tester.widget<TextButton>(
        find.byKey(VendorBookingDetailScreen.cancelConfirmKey),
      );
      expect(confirm.onPressed, isNull, reason: 'a reason is required');

      await tester.enterText(
        find.byKey(VendorBookingDetailScreen.cancelReasonKey),
        'Overbooked',
      );
      await tester.pump();
      await tapAndSettle(
        tester,
        find.byKey(VendorBookingDetailScreen.cancelConfirmKey),
      );
      verify(() => repo.cancel(bookingId, 'Overbooked')).called(1);
      expect(find.text('Cancelled by you: Overbooked'), findsOneWidget);
      expect(find.text('Refund pending'), findsOneWidget);
    });

    testWidgets('a pay-at-venue booking has nothing to refund', (tester) async {
      final repo = MockVendorBookingsRepository();
      stubOne(repo, booking(paidOnline: 0, balanceDue: 9000));
      await pumpServiceScreen(
        tester,
        const VendorBookingDetailScreen(bookingId: bookingId),
        bookings: repo,
      );
      await tapAndSettle(tester, find.byKey(VendorBookingDetailScreen.cancelKey));
      expect(
        find.text('Nothing was paid online, so there is nothing to refund.'),
        findsOneWidget,
      );
    });

    testWidgets('a travel package shows the trip and its travellers', (
      tester,
    ) async {
      final repo = MockVendorBookingsRepository();
      stubOne(
        repo,
        booking(kind: 2, startDate: '2026-11-02', endDate: '2026-11-08'),
      );
      await pumpServiceScreen(
        tester,
        const VendorBookingDetailScreen(bookingId: bookingId),
        bookings: repo,
        category: ServiceCategory.travelAgency,
      );
      expect(find.text('Trip details'), findsOneWidget);
      expect(find.text('2 Nov 2026'), findsOneWidget);
      expect(find.text('8 Nov 2026'), findsOneWidget);
      expect(find.text('Lakeside Chowk, Pokhara'), findsOneWidget);
      expect(find.text('Travellers'), findsWidgets);
      expect(find.text('Start trip'), findsOneWidget);
    });

    testWidgets('says it is being set up while the endpoint is 404', (
      tester,
    ) async {
      final repo = MockVendorBookingsRepository();
      when(
        () => repo.getBooking(bookingId),
      ).thenAnswer((_) async => left(notDeployed));
      await pumpServiceScreen(
        tester,
        const VendorBookingDetailScreen(bookingId: bookingId),
        bookings: repo,
      );
      expect(find.byKey(ServiceSettingUpView.viewKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a booking that is gone says so, with a retry', (tester) async {
      final repo = MockVendorBookingsRepository();
      when(() => repo.getBooking(bookingId)).thenAnswer(
        (_) async => left(
          const ServiceFailure(
            ServiceFailureKind.notFound,
            code: 'booking.not_found',
          ),
        ),
      );
      await pumpServiceScreen(
        tester,
        const VendorBookingDetailScreen(bookingId: bookingId),
        bookings: repo,
      );
      expect(find.byKey(ServiceSettingUpView.viewKey), findsNothing);
      expect(find.text('This booking is no longer available.'), findsOneWidget);
    });
  });
}
