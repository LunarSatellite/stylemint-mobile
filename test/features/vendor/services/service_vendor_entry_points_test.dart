import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/vendor/profile/data/models/vendor_profile_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/domain/bank_lead.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/data/vendor_bookings_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/domain/service_booking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/home/service_vendor_today_card.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_category.dart';
import 'package:stylemint_mobile_frontend/features/vendor/shared/widgets/vendor_more_menu_sheet.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import 'service_fixtures.dart';

void _stubBookings(MockVendorBookingsRepository repo) {
  when(() => repo.getToday(any())).thenAnswer(
    (_) async => ok(
      BookingsTodayBoard(
        arrivals: [booking(), booking(id: booking2Id)],
        leaving: [booking(id: booking3Id, state: 3)],
        inHouse: const [],
      ),
    ),
  );
  when(() => repo.getSummary()).thenAnswer(
    (_) async => ok(
      const BookingsSummary(
        upcoming: 4,
        inHouse: 0,
        pendingPayment: 0,
        balanceToCollect: Money(amount: 12600, currency: 'NPR'),
      ),
    ),
  );
}

void _stubBank(MockBankLeadsRepository repo, {bool deployed = true}) {
  when(() => repo.getProfile()).thenAnswer(
    (_) async => deployed
        ? ok(
            const BankVendorSummary(
              businessName: 'Himalayan Bank',
              newLeads: 4,
              upcomingAppointments: 6,
            ),
          )
        : left(notDeployed),
  );
  when(
    () => repo.listAppointments(from: any(named: 'from'), to: any(named: 'to')),
  ).thenAnswer(
    (_) async => deployed
        ? ok([appointment(), appointment(id: appointment2Id, status: 2)])
        : left(notDeployed),
  );
}

void main() {
  setUpAll(registerServiceFallbacks);

  test('the vendor profile carries the service category', () {
    final dto = VendorProfileDto.fromJson({
      'id': 'p1',
      'accountId': 'a1',
      'businessName': 'Himalayan Bank',
      'businessType': 3,
      'status': 2,
      'serviceCategory': 3,
      'serviceLicenceNumber': 'NRB-A-012',
    });
    final profile = dto.toDomain();
    expect(ServiceCategory.fromWire(profile.serviceCategory), ServiceCategory.bank);
    expect(profile.serviceLicenceNumber, 'NRB-A-012');

    final before = VendorProfileDto.fromJson({'id': 'p2', 'accountId': 'a2'});
    expect(
      ServiceCategory.fromWire(before.toDomain().serviceCategory),
      ServiceCategory.none,
      reason: 'a server without the field: a product seller',
    );
    expect(ServiceCategory.fromWire('TravelAgency'), ServiceCategory.travelAgency);
    expect(ServiceCategory.fromWire(42), ServiceCategory.none);
  });

  group('dashboard today card', () {
    testWidgets('a product seller sees nothing new', (tester) async {
      await pumpServiceScreen(
        tester,
        const Scaffold(body: ServiceVendorTodayCard()),
        category: ServiceCategory.none,
      );
      expect(find.byKey(ServiceVendorTodayCard.cardKey), findsNothing);
    });

    testWidgets('a hotel sees today\'s arrivals and check-outs', (
      tester,
    ) async {
      final repo = MockVendorBookingsRepository();
      _stubBookings(repo);
      await pumpServiceScreen(
        tester,
        const Scaffold(body: ServiceVendorTodayCard()),
        bookings: repo,
      );
      expect(find.text('Today at your property'), findsOneWidget);
      expect(
        find.text('2 arriving today · 1 checking out today · 0 in house'),
        findsOneWidget,
      );
      expect(find.text('4 upcoming'), findsOneWidget);
      expect(find.text('Rs 12,600 to collect at the venue'), findsOneWidget);

      await tapAndSettle(tester, find.byKey(ServiceVendorTodayCard.primaryKey));
      expect(find.text('page /vendor/bookings'), findsOneWidget);
    });

    testWidgets('a travel agency opens availability from the card', (
      tester,
    ) async {
      final repo = MockVendorBookingsRepository();
      _stubBookings(repo);
      await pumpServiceScreen(
        tester,
        const Scaffold(body: ServiceVendorTodayCard()),
        bookings: repo,
        category: ServiceCategory.travelAgency,
      );
      expect(find.text('Today\'s trips'), findsOneWidget);
      await tapAndSettle(
        tester,
        find.byKey(ServiceVendorTodayCard.secondaryKey),
      );
      expect(find.text('page /vendor/availability'), findsOneWidget);
    });

    testWidgets('a bank sees new leads and today\'s branch visits', (
      tester,
    ) async {
      final repo = MockBankLeadsRepository();
      _stubBank(repo);
      await pumpServiceScreen(
        tester,
        const Scaffold(body: ServiceVendorTodayCard()),
        bank: repo,
        category: ServiceCategory.bank,
      );
      expect(find.text('Today at your bank'), findsOneWidget);
      expect(
        find.text('4 new leads · 6 upcoming appointments'),
        findsOneWidget,
      );
      expect(find.text('1 branch visit today'), findsOneWidget);
      await tapAndSettle(tester, find.byKey(ServiceVendorTodayCard.primaryKey));
      expect(find.text('page /vendor/bank/leads'), findsOneWidget);
    });

    testWidgets('before the deploy the bank card says it is being set up', (
      tester,
    ) async {
      final repo = MockBankLeadsRepository();
      _stubBank(repo, deployed: false);
      await pumpServiceScreen(
        tester,
        const Scaffold(body: ServiceVendorTodayCard()),
        bank: repo,
        category: ServiceCategory.bank,
      );
      expect(
        find.text('Leads and appointments are being set up.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('More menu', () {
    Future<void> openMenu(WidgetTester tester, ServiceCategory c) async {
      await pumpServiceScreen(
        tester,
        Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showVendorMoreMenu(context, ref),
              child: const Text('open menu'),
            ),
          ),
        ),
        category: c,
      );
      await tapAndSettle(tester, find.text('open menu'));
    }

    testWidgets('a bank gets Leads and Branch appointments', (tester) async {
      await openMenu(tester, ServiceCategory.bank);
      expect(find.text('Leads'), findsOneWidget);
      expect(find.text('Branch appointments'), findsOneWidget);
      expect(find.text('Bookings'), findsNothing);
      await tapAndSettle(tester, find.text('Leads'));
      expect(find.text('page /vendor/bank/leads'), findsOneWidget);
    });

    testWidgets('a hotel gets Bookings and Rooms available', (tester) async {
      await openMenu(tester, ServiceCategory.hotel);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Rooms available'), findsOneWidget);
      expect(find.text('Leads'), findsNothing);
    });

    testWidgets('a product seller\'s menu is unchanged', (tester) async {
      await openMenu(tester, ServiceCategory.none);
      expect(find.text('Bookings'), findsNothing);
      expect(find.text('Leads'), findsNothing);
      expect(find.text('Rooms available'), findsNothing);
      expect(find.text('EMI plans'), findsOneWidget);
    });
  });
}
