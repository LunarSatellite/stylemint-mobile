import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/booking_checkout_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/booking_confirmed_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/package_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';

import 'services_fakes.dart';

const _packageLocation = '/services/travel/$packageId?travellers=2';

void main() {
  testWidgets('the package page shows itinerary, inclusions and seats left', (
    tester,
  ) async {
    await pumpServices(tester, location: _packageLocation);

    expect(find.byKey(const Key('package-day-1')), findsOneWidget);
    await reveal(tester, find.text('Permits'));
    expect(find.text('Guide'), findsOneWidget);
    await reveal(tester, find.text('Flights'));
    await reveal(tester, find.byKey(Key('package-seats-$departureId')));
    expect(
      tester.widget<Text>(find.byKey(Key('package-seats-$departureId'))).data,
      '5 seats left',
    );
    expect(
      tester
          .widget<Text>(find.byKey(Key('package-seats-$fullDepartureId')))
          .data,
      'Full',
    );
    expect(find.text('Choose a departure'), findsOneWidget);
  });

  testWidgets('more travellers than seats left is stopped before a quote', (
    tester,
  ) async {
    final repo = FakeBookingsRepository();
    await pumpServices(tester, location: _packageLocation, bookings: repo);

    await tapVisible(
      tester,
      find.byKey(PackageDetailScreen.departureKey(departureId)),
    );
    await reveal(tester, find.byKey(const Key('package-adults-plus')));
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const Key('package-adults-plus')));
    }
    await settle(tester);
    await tester.tap(find.byKey(PackageDetailScreen.bookKey));
    await settle(tester);

    expect(repo.packageQuotes, isEmpty);
    await reveal(tester, find.byKey(PackageDetailScreen.quoteErrorKey));
    expect(find.text('Only 5 seats are left on this departure.'), findsOneWidget);
  });

  testWidgets('departure + adults/children → quote → names → pay', (
    tester,
  ) async {
    final repo = FakeBookingsRepository();
    final launched = <Uri>[];
    await pumpServices(
      tester,
      location: _packageLocation,
      bookings: repo,
      launched: launched,
    );

    await tapVisible(
      tester,
      find.byKey(PackageDetailScreen.departureKey(departureId)),
    );
    await reveal(tester, find.byKey(const Key('package-children-plus')));
    await tester.tap(find.byKey(const Key('package-children-plus')));
    await settle(tester);
    await tester.tap(find.byKey(PackageDetailScreen.bookKey));
    await settle(tester);

    expect(repo.packageQuotes.single, {
      'departureId': departureId,
      'adults': 2,
      'children': 1,
    });
    expect(find.byType(BookingCheckoutScreen), findsOneWidget);
    expect(find.text('Departs Nov 2, 2026'), findsWidgets);

    // One name per traveller: two adults and a child.
    for (var i = 0; i < 3; i++) {
      await reveal(tester, find.byKey(BookingCheckoutScreen.travellerKey(i)));
    }
    expect(find.byKey(BookingCheckoutScreen.travellerKey(3)), findsNothing);
    await tester.enterText(
      find.byKey(BookingCheckoutScreen.travellerKey(1)),
      'Ram Sharma',
    );
    await tester.enterText(
      find.byKey(BookingCheckoutScreen.travellerKey(2)),
      'Mina Sharma',
    );
    await tester.enterText(
      find.byKey(BookingCheckoutScreen.travellerAgeKey(2)),
      '9',
    );

    await tapVisible(
      tester,
      find.byKey(BookingCheckoutScreen.modeKey(PaymentMode.deposit)),
    );
    expect(
      tester.widget<Text>(find.byKey(BookingCheckoutScreen.payNowKey)).data,
      'Rs 24,000',
    );
    await tester.tap(find.byKey(BookingCheckoutScreen.submitKey));
    await settle(tester);

    final created = repo.created.single;
    expect(created['kind'], ListingKind.package);
    expect(created['guestName'], 'Sita Sharma');
    final travellers = created['travellers']! as List<Traveller>;
    expect([for (final t in travellers) t.fullName], [
      'Sita Sharma',
      'Ram Sharma',
      'Mina Sharma',
    ]);
    expect([for (final t in travellers) t.type], [
      TravellerType.adult,
      TravellerType.adult,
      TravellerType.child,
    ]);
    expect(travellers.last.age, 9);
    expect(repo.payments, hasLength(1));
    expect(launched, hasLength(1));
    expect(find.byType(BookingConfirmedScreen), findsOneWidget);
  });

  testWidgets('every traveller needs a name', (tester) async {
    final repo = FakeBookingsRepository()
      ..nextPackageQuote = (a, c) => packageQuote(adults: 2, children: 0);
    await pumpServices(tester, location: _packageLocation, bookings: repo);

    await tapVisible(
      tester,
      find.byKey(PackageDetailScreen.departureKey(departureId)),
    );
    await tester.tap(find.byKey(PackageDetailScreen.bookKey));
    await settle(tester);
    await tapVisible(
      tester,
      find.byKey(BookingCheckoutScreen.modeKey(PaymentMode.fullPrepay)),
    );
    await tester.tap(find.byKey(BookingCheckoutScreen.submitKey));
    await settle(tester);

    expect(repo.created, isEmpty);
    await reveal(tester, find.text('Enter a full name'));
    expect(find.text('Enter a full name'), findsOneWidget);
  });

  testWidgets('a package with no dates says so', (tester) async {
    final repo = FakeBookingsRepository();
    final p = packageDetail();
    repo.package = PackageDetail(
      listingId: p.listingId,
      title: p.title,
      cancellationPolicy: p.cancellationPolicy,
    );
    await pumpServices(tester, location: _packageLocation, bookings: repo);
    await reveal(tester, find.byKey(const Key('package-no-departures')));
    expect(find.byKey(const Key('package-no-departures')), findsOneWidget);
  });

  testWidgets('a 404 for the package page reads as coming soon', (
    tester,
  ) async {
    final repo = FakeBookingsRepository()..failAll = comingSoon;
    await pumpServices(tester, location: _packageLocation, bookings: repo);
    expect(find.byKey(ServicesComingSoon.viewKey), findsOneWidget);
  });
}
