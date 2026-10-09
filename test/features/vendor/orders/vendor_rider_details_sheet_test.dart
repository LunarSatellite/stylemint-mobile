import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/device/delivery_push.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/delivery_request.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/rider_profile_for_vendor.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/repositories/vendor_orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_delivery_partner_sheet.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_rider_details_sheet.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';

import '../../orders_test_harness.dart';

/// The delivery-request calls and the rider details, answered from fields.
class _FakeRepo extends Mock implements VendorOrdersRepository {
  Either<NetworkExceptions, DeliveryRequest?> current = right(null);
  Either<NetworkExceptions, RiderProfileForVendor?> profile = right(null);
  Either<NetworkExceptions, DeliveryRequest>? selection;

  int currentCalls = 0;
  final List<String> selected = [];
  final List<String> profilesRead = [];

  @override
  Future<Either<NetworkExceptions, DeliveryRequest?>> currentDeliveryRequest(
    String orderId,
  ) async {
    currentCalls++;
    return current;
  }

  @override
  Future<Either<NetworkExceptions, DeliveryRequest>> selectDeliveryPartner(
    String orderId,
    String offerId,
  ) async {
    selected.add(offerId);
    return selection ??
        right(
          _request(
            DeliveryRequestState.assigned,
            assigned: const AssignedRider(
              courierId: 'courier-1',
              displayName: 'Ramesh K.',
            ),
          ),
        );
  }

  @override
  Future<Either<NetworkExceptions, RiderProfileForVendor?>> riderProfile(
    String orderId,
    String courierId,
  ) async {
    profilesRead.add(courierId);
    return profile;
  }
}

InterestedRider _rider({
  String offerId = 'offer-1',
  String courierId = 'courier-1',
  String name = 'Ramesh K.',
  double? rating = 4.8,
  int? ratingCount = 23,
  bool? verified = true,
}) => InterestedRider(
  offerId: offerId,
  courierId: courierId,
  displayName: name,
  tier: 'Pro',
  rating: rating,
  ratingCount: ratingCount,
  verified: verified,
  completedDeliveries: 12,
  distanceKm: 1.4,
  vehicle: 'Bike',
  interestedUtc: DateTime.now().toUtc().subtract(const Duration(minutes: 2)),
);

DeliveryRequest _request(
  DeliveryRequestState state, {
  List<InterestedRider> interested = const [],
  AssignedRider? assigned,
}) => DeliveryRequest(
  packageId: 'pkg-1',
  state: state,
  notifiedCount: 4,
  radiusKm: 5,
  interested: interested,
  expiresUtc: DateTime.now().toUtc().add(const Duration(minutes: 14)),
  assigned: assigned,
);

RiderProfileForVendor _profile({String state = 'Interested'}) =>
    RiderProfileForVendor.fromJson({
      'courierId': 'courier-1',
      'offerId': 'offer-1',
      'displayName': 'Ramesh K.',
      'verified': true,
      'memberSinceUtc': '2025-03-02T00:00:00Z',
      'tier': 'Pro',
      'vehicle': {'type': 'Scooter', 'plateLast4': '4321'},
      'homeArea': 'Lalitpur',
      'distanceKm': 1.4,
      'rating': {
        'average': 4.7,
        'count': 23,
        'breakdown': {'5': 18, '4': 3, '3': 1, '2': 1, '1': 0},
        'topTags': [
          {'tag': 'OnTime', 'count': 12},
        ],
      },
      'completedDeliveries': 57,
      'onTimeRate': 0.94,
      'cancellationRate': 0.02,
      'recentReviews': [
        {
          'stars': 5,
          'tags': ['CarefulWithParcel'],
          'comment': 'Handled it like glass',
          'ageDays': 3,
        },
      ],
      'state': state,
    });

void main() {
  late _FakeRepo repo;
  late DeliveryPushBus bus;

  setUp(() => repo = _FakeRepo());

  Future<void> pumpSheet(
    WidgetTester tester, {
    double width = 390,
    double textScale = 1,
  }) async {
    setPhoneView(tester, width: width);
    bus = DeliveryPushBus();
    addTearDown(bus.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vendorOrdersRepositoryProvider.overrideWithValue(repo),
          deliveryPushBusProvider.overrideWithValue(bus),
        ],
        child: ordersTestApp(
          const VendorDeliveryPartnerSheet(subOrderId: 'sub-1'),
          textScale: textScale,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> openDetails(WidgetTester tester, {String offerId = 'offer-1'}) async {
    final row = find.byKey(VendorDeliveryPartnerSheet.detailsKey(offerId));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  FilledButton chooseButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.byKey(VendorRiderDetailsSheet.chooseKey),
  );

  group('partner rows', () {
    testWidgets('avatar, name, tick, ★ with count, deliveries, distance', (
      tester,
    ) async {
      repo.current = right(
        _request(
          DeliveryRequestState.ridersInterested,
          interested: [_rider()],
        ),
      );
      await pumpSheet(tester);

      expect(find.text('Ramesh K.'), findsOneWidget);
      expect(find.byType(RiderVerifiedTick), findsOneWidget);
      expect(find.text('★ 4.8 (23) · 12 deliveries'), findsOneWidget);
      expect(find.textContaining('1.4 km away · Bike'), findsOneWidget);
    });

    testWidgets('"New rider" when the rating is null, no tick unless said', (
      tester,
    ) async {
      repo.current = right(
        _request(
          DeliveryRequestState.ridersInterested,
          interested: [
            _rider(rating: null, ratingCount: null, verified: null),
          ],
        ),
      );
      await pumpSheet(tester);

      expect(find.text('New rider · 12 deliveries'), findsOneWidget);
      expect(find.textContaining('★'), findsNothing);
      expect(find.byType(RiderVerifiedTick), findsNothing);
    });
  });

  group('rider details', () {
    testWidgets('tap row → details → Choose this rider → select', (
      tester,
    ) async {
      repo
        ..current = right(
          _request(
            DeliveryRequestState.ridersInterested,
            interested: [_rider()],
          ),
        )
        ..profile = right(_profile());
      await pumpSheet(tester);
      await openDetails(tester);

      expect(repo.profilesRead, ['courier-1']);
      expect(find.byType(VendorRiderDetailsSheet), findsOneWidget);
      expect(find.text('Member since Mar 2025'), findsOneWidget);
      expect(find.text('Scooter · plate ••4321'), findsOneWidget);
      expect(find.text('Lalitpur'), findsOneWidget);
      expect(find.text('4.7'), findsOneWidget);
      expect(find.text('23 ratings'), findsOneWidget);
      expect(find.text('On time · 12'), findsOneWidget);
      expect(find.text('57'), findsOneWidget);
      expect(find.text('94%'), findsOneWidget);
      expect(find.text('2%'), findsOneWidget);
      expect(find.text('Handled it like glass'), findsOneWidget);
      expect(find.text('3 days ago'), findsOneWidget);
      expect(chooseButton(tester).onPressed, isNotNull);
      expectNoLayoutErrors(tester);

      await tester.tap(find.byKey(VendorRiderDetailsSheet.chooseKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The partner sheet's own confirmation, then the same select call.
      expect(find.byType(VendorRiderDetailsSheet), findsNothing);
      expect(find.text('Choose Ramesh K.?'), findsOneWidget);
      await tester.tap(find.byKey(VendorDeliveryPartnerSheet.confirmChooseKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(repo.selected, ['offer-1']);
      expect(find.text('Assigned · on the way to collect'), findsOneWidget);
    });

    testWidgets('Back closes the details and chooses nobody', (tester) async {
      repo.current = right(
        _request(
          DeliveryRequestState.ridersInterested,
          interested: [_rider()],
        ),
      );
      await pumpSheet(tester);
      await openDetails(tester);

      await tester.tap(find.byKey(VendorRiderDetailsSheet.backKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(VendorRiderDetailsSheet), findsNothing);
      expect(find.text('Choose Ramesh K.?'), findsNothing);
      expect(repo.selected, isEmpty);
    });

    testWidgets('details not served yet: the row\'s own fields, still choosable', (
      tester,
    ) async {
      repo
        ..current = right(
          _request(
            DeliveryRequestState.ridersInterested,
            interested: [_rider()],
          ),
        )
        ..profile = right(null);
      await pumpSheet(tester);
      await openDetails(tester);

      final details = find.byType(VendorRiderDetailsSheet);
      expect(
        find.descendant(of: details, matching: find.text('Ramesh K.')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: details,
          matching: find.text('★ 4.8 · 23 ratings'),
        ),
        findsOneWidget,
      );
      expect(find.text('1.4 km away'), findsOneWidget);
      expect(find.text('Bike'), findsOneWidget);
      expect(find.byKey(VendorRiderDetailsSheet.goneKey), findsNothing);
      expect(chooseButton(tester).onPressed, isNotNull);
    });

    testWidgets('withdrawn rider: says so and choosing is disabled', (
      tester,
    ) async {
      repo
        ..current = right(
          _request(
            DeliveryRequestState.ridersInterested,
            interested: [_rider()],
          ),
        )
        ..profile = right(_profile(state: 'Withdrawn'));
      await pumpSheet(tester);
      await openDetails(tester);

      expect(find.byKey(VendorRiderDetailsSheet.goneKey), findsOneWidget);
      expect(
        find.textContaining('no longer available for this parcel'),
        findsOneWidget,
      );
      expect(chooseButton(tester).onPressed, isNull);
    });

    testWidgets('rider_profile.not_available (404): unavailable', (
      tester,
    ) async {
      repo
        ..current = right(
          _request(
            DeliveryRequestState.ridersInterested,
            interested: [_rider()],
          ),
        )
        ..profile = left(
          const NetworkExceptions.validation(
            code: 'rider_profile.not_available',
          ),
        );
      await pumpSheet(tester);
      await openDetails(tester);

      expect(find.byKey(VendorRiderDetailsSheet.goneKey), findsOneWidget);
      expect(chooseButton(tester).onPressed, isNull);
      // Not offered as a retryable error.
      expect(find.byKey(VendorRiderDetailsSheet.retryKey), findsNothing);
    });

    testWidgets('the poll drops the rider: the open sheet follows', (
      tester,
    ) async {
      repo
        ..current = right(
          _request(
            DeliveryRequestState.ridersInterested,
            interested: [_rider()],
          ),
        )
        ..profile = right(_profile());
      await pumpSheet(tester);
      await openDetails(tester);
      expect(chooseButton(tester).onPressed, isNotNull);

      // They withdrew; the next 5 s poll no longer lists them.
      repo.current = right(_request(DeliveryRequestState.searching));
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(find.byKey(VendorRiderDetailsSheet.goneKey), findsOneWidget);
      expect(chooseButton(tester).onPressed, isNull);
    });

    testWidgets('a failed read keeps the basics and offers a retry', (
      tester,
    ) async {
      repo
        ..current = right(
          _request(
            DeliveryRequestState.ridersInterested,
            interested: [_rider()],
          ),
        )
        ..profile = left(const NetworkExceptions.serverUnavailable());
      await pumpSheet(tester);
      await openDetails(tester);

      expect(find.byKey(VendorRiderDetailsSheet.retryKey), findsOneWidget);
      expect(chooseButton(tester).onPressed, isNotNull);

      repo.profile = right(_profile());
      await tester.tap(find.byKey(VendorRiderDetailsSheet.retryKey));
      await tester.pump();
      await tester.pump();
      expect(find.text('Lalitpur'), findsOneWidget);
    });

    testWidgets('no overflow at 320dp with text ×1.3', (tester) async {
      repo
        ..current = right(
          _request(
            DeliveryRequestState.ridersInterested,
            interested: [_rider(name: 'Ramchandra Bahadur Shrestha')],
          ),
        )
        ..profile = right(_profile());
      await pumpSheet(tester, width: 320, textScale: 1.3);
      await openDetails(tester);
      expectNoLayoutErrors(tester);
    });
  });
}
