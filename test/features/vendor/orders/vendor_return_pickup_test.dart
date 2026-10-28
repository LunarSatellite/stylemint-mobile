import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/device/delivery_push.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_delivery.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_pickup.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/delivery_confirmation_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/return_handover_confirm.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_return_request_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/delivery_request.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_return_request.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/repositories/vendor_orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_delivery_partner_sheet.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_return_card.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_return_pickup_panel.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';

import '../../orders_test_harness.dart';

/// The return-pickup calls answered from fields. Any sub-order (forward)
/// delivery call is a bug here and fails the test through the mock.
class _FakeRepo extends Mock implements VendorOrdersRepository {
  Either<NetworkExceptions, DeliveryRequest?> current = right(null);
  final List<String> opened = [];
  final List<(String, String)> selected = [];

  @override
  Future<Either<NetworkExceptions, DeliveryRequest?>>
  currentReturnPickupRequest(String returnRequestId) async => current;

  @override
  Future<Either<NetworkExceptions, DeliveryRequest>> openReturnPickupRequest(
    String returnRequestId, {
    bool allowVerifiedNonPro = false,
  }) async {
    opened.add(returnRequestId);
    return right(_request(DeliveryRequestState.searching));
  }

  @override
  Future<Either<NetworkExceptions, DeliveryRequest>> selectReturnPickupRider(
    String returnRequestId,
    String offerId,
  ) async {
    selected.add((returnRequestId, offerId));
    return right(
      _request(
        DeliveryRequestState.assigned,
        assigned: const AssignedRider(
          courierId: 'c-1',
          displayName: 'Ramesh K.',
        ),
      ),
    );
  }
}

class _MockConfirmRepo extends Mock implements DeliveryConfirmationRepository {}

DeliveryRequest _request(
  DeliveryRequestState state, {
  List<InterestedRider> interested = const [],
  AssignedRider? assigned,
}) => DeliveryRequest(
  packageId: 'pkg-r',
  state: state,
  notifiedCount: 3,
  radiusKm: 5,
  interested: interested,
  expiresUtc: DateTime.now().toUtc().add(const Duration(minutes: 12)),
  assigned: assigned,
  kind: DeliveryRequestKind.returnPickup,
  returnRequestId: 'ret-1',
);

const _rider = InterestedRider(
  offerId: 'offer-1',
  courierId: 'c-1',
  displayName: 'Ramesh K.',
  tier: 'Traveller',
  rating: 4.8,
  completedDeliveries: 12,
  distanceKm: 1.4,
);

ReturnPickup _pickup(Map<String, dynamic> extra) => ReturnPickup.fromJson({
  'id': 'p-1',
  'returnRequestId': 'ret-1',
  'trackingNumber': 'SM-R-00000042',
  'state': 1,
  'requestedUtc': '2026-10-28T08:00:00Z',
  ...extra,
});

VendorReturnRequest _approved({String? pickupStage}) => VendorReturnRequest(
  id: 'ret-1',
  orderId: 'o-1',
  orderNumber: 'NK2026-00042',
  subOrderId: 's-1',
  subOrderLineId: 'l-1',
  productTitleSnapshot: 'Linen shirt',
  quantity: 1,
  reason: 'Damaged',
  state: VendorReturnRequestState.approved,
  submittedUtc: DateTime.utc(2026, 10, 27),
  reasonCategory: 'Damaged',
  pickupStage: pickupStage,
);

void main() {
  group('data', () {
    test('DeliveryRequest reads kind, return id and the offer fare', () {
      final request = DeliveryRequest.fromJson({
        'packageId': 'pkg',
        'state': 'RidersInterested',
        'kind': 'Return',
        'returnRequestId': 'ret-1',
        'interested': [
          {
            'offerId': 'o1',
            'courierId': 'c1',
            'displayName': 'Sita',
            'fare': {'amount': 150, 'currency': 'NPR'},
          },
        ],
      });
      expect(request.kind, DeliveryRequestKind.returnPickup);
      expect(request.returnRequestId, 'ret-1');
      expect(request.interested.single.fare?.amount, 150);
    });

    test('an old DeliveryRequest without the new fields is a delivery', () {
      final request = DeliveryRequest.fromJson({
        'packageId': 'pkg',
        'state': 'Searching',
      });
      expect(request.kind, DeliveryRequestKind.delivery);
      expect(request.returnRequestId, isNull);
    });

    test('vendor return: Cancelled (5) and the new strings parse; old rows '
        'still parse', () {
      final cancelled = VendorReturnRequestDto.fromJson({
        'id': 'r',
        'orderId': 'o',
        'subOrderId': 's',
        'subOrderLineId': 'l',
        'state': 5,
        'submittedUtc': '2026-10-28T08:00:00Z',
        'reasonCategory': 'ChangedMind',
        'pickupFarePayer': 'Buyer',
        'pickupStage': 'RiderAssigned',
      }).toDomain();
      expect(cancelled.state, VendorReturnRequestState.cancelled);
      expect(cancelled.reasonCategory, 'ChangedMind');
      expect(cancelled.pickupStage, 'RiderAssigned');
      expect(cancelled.pickupAware, isTrue);

      final old = VendorReturnRequestDto.fromJson({
        'id': 'r',
        'orderId': 'o',
        'subOrderId': 's',
        'subOrderLineId': 'l',
        'state': 2,
        'submittedUtc': '2026-10-28T08:00:00Z',
      }).toDomain();
      expect(old.state, VendorReturnRequestState.approved);
      expect(old.reasonCategory, isNull);
      expect(old.pickupStage, isNull);
      expect(old.pickupAware, isFalse);
    });

    test('completion waits for the rider only on a rider return', () {
      expect(
        _pickup({'mode': 'Rider', 'stage': 'Collected'}).blocksSellerCompletion,
        isTrue,
      );
      expect(
        _pickup({
          'mode': 'Rider',
          'stage': 'ReceivedBySeller',
        }).blocksSellerCompletion,
        isFalse,
      );
      expect(_pickup({'mode': 'Legacy'}).blocksSellerCompletion, isFalse);
      expect(_pickup({}).blocksSellerCompletion, isFalse);
      expect(
        VendorReturnPickupScope.lockedByListStage('SearchingRider'),
        isTrue,
      );
      expect(VendorReturnPickupScope.lockedByListStage(null), isFalse);
      expect(VendorReturnPickupScope.lockedByListStage('Brand-new'), isFalse);
    });
  });

  group('return rider sheet', () {
    late _FakeRepo repo;

    Future<void> pumpSheet(WidgetTester tester) async {
      setPhoneView(tester);
      final bus = DeliveryPushBus();
      addTearDown(bus.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vendorOrdersRepositoryProvider.overrideWithValue(repo),
            deliveryPushBusProvider.overrideWithValue(bus),
          ],
          child: ordersTestApp(
            const VendorDeliveryPartnerSheet.returnPickup(
              returnRequestId: 'ret-1',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    setUp(() => repo = _FakeRepo());

    testWidgets('the seller picks an interested rider for the return', (
      tester,
    ) async {
      repo.current = right(
        _request(DeliveryRequestState.ridersInterested, interested: [_rider]),
      );
      await pumpSheet(tester);

      expect(find.text('Find a rider for this return'), findsOneWidget);
      // No own courier for the buyer's parcel.
      expect(find.byKey(VendorDeliveryPartnerSheet.ownCourierKey), findsNothing);

      final choose = find.byKey(VendorDeliveryPartnerSheet.chooseKey('offer-1'));
      await tester.ensureVisible(choose);
      await tester.tap(choose);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(VendorDeliveryPartnerSheet.confirmChooseKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(repo.selected, [('ret-1', 'offer-1')]);
      expect(find.text('Assigned · on the way to collect'), findsOneWidget);
      // The seller confirms with the rider's code later, not a handover tap.
      expect(find.byKey(VendorDeliveryPartnerSheet.handedOverKey), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('no riders: Try again re-opens the return request', (
      tester,
    ) async {
      repo.current = right(_request(DeliveryRequestState.noRiders));
      await pumpSheet(tester);

      expect(find.text('No rider is within 5 km right now'), findsOneWidget);
      expect(find.text('Use your own courier'), findsNothing);

      await tester.tap(find.byKey(VendorDeliveryPartnerSheet.askAgainKey));
      await tester.pump();
      await tester.pump();

      expect(repo.opened, ['ret-1']);
      expect(find.text('Waiting for riders…'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('nothing requested yet (Legacy) offers "Find a rider"', (
      tester,
    ) async {
      await pumpSheet(tester);

      expect(find.text('Find a rider'), findsOneWidget);
      await tester.tap(find.byKey(VendorDeliveryPartnerSheet.findKey));
      await tester.pump();
      await tester.pump();
      expect(repo.opened, ['ret-1']);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('return pickup panel', () {
    late List<bool> opened;

    Future<void> pumpPanel(WidgetTester tester, ReturnPickup pickup) async {
      setPhoneView(tester);
      opened = [];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vendorOrdersRepositoryProvider.overrideWithValue(_FakeRepo()),
            deliveryConfirmationRepositoryProvider.overrideWithValue(
              _MockConfirmRepo(),
            ),
          ],
          child: ordersTestApp(
            VendorReturnPickupPanel(
              returnRequestId: 'ret-1',
              pickup: pickup,
              openSheet: (context, {required returnRequestId, reopen = false}) async {
                opened.add(reopen);
              },
            ),
          ),
        ),
      );
    }

    testWidgets('Legacy: "Find a rider" asks riders at once', (tester) async {
      await pumpPanel(tester, _pickup({'mode': 'Legacy'}));

      expect(find.text('No rider asked yet'), findsOneWidget);
      expect(find.text('Find a rider'), findsOneWidget);
      await tester.tap(find.byKey(VendorReturnPickupPanel.actionKey));
      await tester.pump();
      expect(opened, [true]);
    });

    testWidgets('NoRiders: "Try again"', (tester) async {
      await pumpPanel(
        tester,
        _pickup({'mode': 'Rider', 'stage': 'NoRiders', 'state': 5}),
      );

      expect(find.text('No rider yet'), findsOneWidget);
      await tester.tap(find.byKey(VendorReturnPickupPanel.actionKey));
      await tester.pump();
      expect(opened, [true]);
    });

    testWidgets('riders interested: "Choose a rider" opens the list', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        _pickup({'mode': 'Rider', 'stage': 'RidersInterested'}),
      );

      expect(find.text('Choose a rider'), findsOneWidget);
      await tester.tap(find.byKey(VendorReturnPickupPanel.actionKey));
      await tester.pump();
      expect(opened, [false]);
    });

    testWidgets("rider at the shop: scan the rider's code", (tester) async {
      await pumpPanel(
        tester,
        _pickup({
          'mode': 'Rider',
          'stage': 'AwaitingSellerConfirmation',
          'state': 3,
          'rider': {'displayName': 'Ramesh K.', 'rating': 4.8},
        }),
      );

      expect(find.byKey(ReturnHandoverConfirm.scanKey), findsOneWidget);
      expect(find.byKey(VendorReturnPickupPanel.actionKey), findsNothing);
      expect(find.textContaining('Ramesh K. · ★ 4.8'), findsOneWidget);
    });
  });

  group('return card', () {
    Future<void> pumpCard(WidgetTester tester, {required bool locked}) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            child: VendorReturnCard(
              request: _approved(pickupStage: 'Collected'),
              busy: false,
              onApprove: () {},
              onReject: () {},
              onComplete: () {},
              completeLocked: locked,
            ),
          ),
        ),
      );
    }

    FilledButton completeButton(WidgetTester tester) => tester.widget(
      find.ancestor(
        of: find.text('Received · complete & refund'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );

    testWidgets('Mark received waits until the rider hands it over', (
      tester,
    ) async {
      await pumpCard(tester, locked: true);
      expect(completeButton(tester).onPressed, isNull);
      expect(find.text(VendorReturnCard.completeLockedText), findsOneWidget);
      // The category is shown as the reason.
      expect(find.text('Damaged'), findsOneWidget);
    });

    testWidgets('once received it can be completed', (tester) async {
      await pumpCard(tester, locked: false);
      expect(completeButton(tester).onPressed, isNotNull);
      expect(find.text(VendorReturnCard.completeLockedText), findsNothing);
    });
  });

  test('handover messages are plain and role-specific', () {
    expect(
      returnHandoverMessage(const DeliveryConfirmNotRecipient(), seller: true),
      contains('your shop'),
    );
    expect(
      returnHandoverMessage(const DeliveryConfirmExpired(), seller: false),
      contains('new one'),
    );
  });
}
