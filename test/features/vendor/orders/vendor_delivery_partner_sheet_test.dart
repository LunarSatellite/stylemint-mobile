import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/device/delivery_push.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/delivery_request.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/repositories/vendor_orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/delivery_partner_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_delivery_partner_sheet.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';

import '../../orders_test_harness.dart';

/// The three delivery-request calls answered from fields; everything else on
/// the repository is unused here and left to the mock.
class _FakeRepo extends Mock implements VendorOrdersRepository {
  Either<NetworkExceptions, DeliveryRequest?> current = right(null);
  Either<NetworkExceptions, DeliveryRequest>? opened;
  Either<NetworkExceptions, DeliveryRequest>? selection;

  int currentCalls = 0;
  int openCalls = 0;
  final List<String> selected = [];

  @override
  Future<Either<NetworkExceptions, DeliveryRequest?>> currentDeliveryRequest(
    String orderId,
  ) async {
    currentCalls++;
    return current;
  }

  @override
  Future<Either<NetworkExceptions, DeliveryRequest>> openDeliveryRequest(
    String orderId,
  ) async {
    openCalls++;
    return opened ?? right(_request(DeliveryRequestState.searching));
  }

  @override
  Future<Either<NetworkExceptions, DeliveryRequest>> selectDeliveryPartner(
    String orderId,
    String offerId,
  ) async {
    selected.add(offerId);
    return selection ?? right(_assignedRequest());
  }
}

InterestedRider _rider({
  String offerId = 'offer-1',
  String name = 'Ramesh K.',
}) => InterestedRider(
  offerId: offerId,
  courierId: 'courier-$offerId',
  displayName: name,
  tier: 'Pro',
  rating: 4.8,
  completedDeliveries: 12,
  distanceKm: 1.4,
  vehicle: 'Bike',
  interestedUtc: DateTime.now().toUtc().subtract(
    const Duration(minutes: 2, seconds: 5),
  ),
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
  openedUtc: DateTime.now().toUtc().subtract(const Duration(seconds: 28)),
  expiresUtc: DateTime.now().toUtc().add(
    const Duration(minutes: 14, seconds: 32),
  ),
  assigned: assigned,
);

DeliveryRequest _assignedRequest() => _request(
  DeliveryRequestState.assigned,
  assigned: const AssignedRider(
    courierId: 'courier-offer-1',
    displayName: 'Ramesh K.',
    phone: '98XXXXXX12',
  ),
);

void main() {
  group('DeliveryPartnerNotifier', () {
    testWidgets('no request yet is "not requested", not an error', (
      tester,
    ) async {
      final repo = _FakeRepo();
      final notifier = DeliveryPartnerNotifier(repo, 'sub-1');
      await tester.pump();

      expect(notifier.state, isA<DeliveryPartnerNotRequested>());
      expect(notifier.isPolling, isFalse);
      notifier.dispose();
    });

    testWidgets('a failed read is a failure, not "no riders"', (tester) async {
      final repo = _FakeRepo()
        ..current = left(const NetworkExceptions.serverUnavailable());
      final notifier = DeliveryPartnerNotifier(repo, 'sub-1');
      await tester.pump();

      expect(notifier.state, isA<DeliveryPartnerFailed>());
      expect(notifier.isPolling, isFalse);

      // Retry re-runs the read that failed.
      repo.current = right(_request(DeliveryRequestState.searching));
      await notifier.retry();
      expect(notifier.state, isA<DeliveryPartnerLive>());
      notifier.dispose();
    });

    testWidgets('polls every 5 s while open and stops once assigned', (
      tester,
    ) async {
      final repo = _FakeRepo()
        ..current = right(_request(DeliveryRequestState.searching));
      final notifier = DeliveryPartnerNotifier(repo, 'sub-1');
      await tester.pump();
      expect(repo.currentCalls, 1);
      expect(notifier.isPolling, isTrue);

      await tester.pump(const Duration(seconds: 5));
      expect(repo.currentCalls, 2);

      repo.current = right(
        _request(DeliveryRequestState.ridersInterested, interested: [_rider()]),
      );
      await tester.pump(const Duration(seconds: 5));
      expect(repo.currentCalls, 3);
      final live = notifier.state as DeliveryPartnerLive;
      expect(live.request.interested, hasLength(1));

      repo.current = right(_assignedRequest());
      await tester.pump(const Duration(seconds: 5));
      expect(repo.currentCalls, 4);
      expect(notifier.isPolling, isFalse);

      await tester.pump(const Duration(seconds: 30));
      expect(repo.currentCalls, 4, reason: 'no polling after Assigned');
      notifier.dispose();
    });

    testWidgets('polling stops on Expired too', (tester) async {
      final repo = _FakeRepo()
        ..current = right(_request(DeliveryRequestState.expired));
      final notifier = DeliveryPartnerNotifier(repo, 'sub-1');
      await tester.pump();
      expect(notifier.isPolling, isFalse);
      await tester.pump(const Duration(seconds: 20));
      expect(repo.currentCalls, 1);
      notifier.dispose();
    });

    testWidgets('choosing assigns and stops polling', (tester) async {
      final repo = _FakeRepo()
        ..current = right(
          _request(
            DeliveryRequestState.ridersInterested,
            interested: [_rider()],
          ),
        );
      final notifier = DeliveryPartnerNotifier(repo, 'sub-1');
      await tester.pump();

      final failure = await notifier.choose('offer-1');
      expect(failure, isNull);
      expect(repo.selected, ['offer-1']);
      final live = notifier.state as DeliveryPartnerLive;
      expect(live.request.state, DeliveryRequestState.assigned);
      expect(notifier.isPolling, isFalse);
      notifier.dispose();
    });

    testWidgets('a refused choice comes back as a failure, list intact', (
      tester,
    ) async {
      final repo = _FakeRepo()
        ..current = right(
          _request(
            DeliveryRequestState.ridersInterested,
            interested: [_rider()],
          ),
        )
        ..selection = left(
          const NetworkExceptions.validation(
            code: 'delivery.offer_withdrawn',
            message: 'That rider withdrew.',
          ),
        );
      final notifier = DeliveryPartnerNotifier(repo, 'sub-1');
      await tester.pump();

      final failure = await notifier.choose('offer-1');
      expect(failure, isNotNull);
      final live = notifier.state as DeliveryPartnerLive;
      expect(live.choosing, isFalse);
      expect(live.request.state, DeliveryRequestState.ridersInterested);
      await tester.pump();
      notifier.dispose();
    });

    testWidgets('disposing stops the poll (sheet closed)', (tester) async {
      final repo = _FakeRepo()
        ..current = right(_request(DeliveryRequestState.searching));
      final notifier = DeliveryPartnerNotifier(repo, 'sub-1');
      await tester.pump();
      expect(notifier.isPolling, isTrue);

      notifier.dispose();
      await tester.pump(const Duration(seconds: 20));
      expect(repo.currentCalls, 1);
    });
  });

  group('VendorDeliveryPartnerSheet', () {
    late _FakeRepo repo;
    late DeliveryPushBus bus;

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
      // The initial read.
      await tester.pump();
      await tester.pump();
    }

    DeliveryPartnerNotifier notifierOf(WidgetTester tester) =>
        ProviderScope.containerOf(
          tester.element(find.byType(VendorDeliveryPartnerSheet)),
        ).read(deliveryPartnerNotifierProvider('sub-1').notifier);

    setUp(() => repo = _FakeRepo());

    testWidgets('nothing requested yet offers "Find a delivery partner"', (
      tester,
    ) async {
      await pumpSheet(tester);

      expect(find.byKey(VendorDeliveryPartnerSheet.findKey), findsOneWidget);
      expect(find.textContaining("Couldn't reach"), findsNothing);

      await tester.tap(find.byKey(VendorDeliveryPartnerSheet.findKey));
      await tester.pump();
      await tester.pump();

      expect(repo.openCalls, 1);
      expect(find.textContaining('Notified 4 riders within 5 km'), findsOne);
    });

    testWidgets('searching shows who was notified and the time left', (
      tester,
    ) async {
      repo.current = right(_request(DeliveryRequestState.searching));
      await pumpSheet(tester);

      expect(find.text('Waiting for riders…'), findsOneWidget);
      expect(
        find.textContaining('Notified 4 riders within 5 km · open for 14:'),
        findsOneWidget,
      );
      expect(find.byKey(VendorDeliveryPartnerSheet.ownCourierKey), findsOne);
    });

    testWidgets('interested riders are listed with what a vendor needs', (
      tester,
    ) async {
      repo.current = right(
        _request(
          DeliveryRequestState.ridersInterested,
          interested: [
            _rider(),
            _rider(offerId: 'offer-2', name: 'Sita Gurung'),
          ],
        ),
      );
      await pumpSheet(tester);

      expect(find.text('2 interested'), findsOneWidget);
      expect(find.text('Ramesh K.'), findsOneWidget);
      expect(find.text('Pro'), findsNWidgets(2));
      expect(find.textContaining('★ 4.8'), findsNWidgets(2));
      expect(find.textContaining('12 deliveries'), findsNWidgets(2));
      expect(
        find.textContaining('1.4 km away · Bike · interested 2m ago'),
        findsNWidgets(2),
      );
      expect(find.byKey(VendorDeliveryPartnerSheet.chooseKey('offer-1')), findsOne);
      expect(find.byKey(VendorDeliveryPartnerSheet.chooseKey('offer-2')), findsOne);
      expectNoLayoutErrors(tester);
    });

    testWidgets('choose → confirm → the assigned rider is shown', (
      tester,
    ) async {
      repo.current = right(
        _request(
          DeliveryRequestState.ridersInterested,
          interested: [_rider()],
        ),
      );
      await pumpSheet(tester);

      final choose = find.byKey(VendorDeliveryPartnerSheet.chooseKey('offer-1'));
      await tester.ensureVisible(choose);
      await tester.tap(choose);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Choose Ramesh K.?'), findsOneWidget);
      await tester.tap(find.byKey(VendorDeliveryPartnerSheet.confirmChooseKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(repo.selected, ['offer-1']);
      expect(find.text('Assigned · on the way to collect'), findsOneWidget);
      expect(find.text('98XXXXXX12'), findsOneWidget);
      expect(find.byKey(VendorDeliveryPartnerSheet.handedOverKey), findsOne);
      // An assigned parcel is not handed to someone else from here.
      expect(find.byKey(VendorDeliveryPartnerSheet.ownCourierKey), findsNothing);

      // And the poll stopped with it.
      expect(notifierOf(tester).isPolling, isFalse);
      final callsAfterAssign = repo.currentCalls;
      await tester.pump(const Duration(seconds: 20));
      expect(repo.currentCalls, callsAfterAssign);
    });

    testWidgets('expired offers "Ask again", which re-opens the request', (
      tester,
    ) async {
      repo.current = right(_request(DeliveryRequestState.expired));
      await pumpSheet(tester);

      expect(find.text('Nobody was chosen in time'), findsOneWidget);
      await tester.tap(find.byKey(VendorDeliveryPartnerSheet.askAgainKey));
      await tester.pump();
      await tester.pump();

      expect(repo.openCalls, 1);
      expect(find.text('Waiting for riders…'), findsOneWidget);
    });

    testWidgets('no riders explains, offers Try again and the own courier', (
      tester,
    ) async {
      repo.current = right(_request(DeliveryRequestState.noRiders));
      await pumpSheet(tester);

      expect(find.text('No rider is within 5 km right now'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Use your own courier'), findsOneWidget);
      expect(find.textContaining("Couldn't reach"), findsNothing);
    });

    testWidgets('a real error says so and retries — not the no-rider text', (
      tester,
    ) async {
      repo.current = left(const NetworkExceptions.serverUnavailable());
      await pumpSheet(tester);

      expect(find.textContaining("Couldn't reach delivery partners"), findsOne);
      expect(find.textContaining('No rider is within'), findsNothing);
      expect(find.byKey(VendorDeliveryPartnerSheet.findKey), findsNothing);

      repo.current = right(_request(DeliveryRequestState.searching));
      await tester.tap(find.byKey(VendorDeliveryPartnerSheet.retryKey));
      await tester.pump();
      await tester.pump();

      expect(repo.currentCalls, 2);
      expect(find.text('Waiting for riders…'), findsOneWidget);
    });

    testWidgets('a delivery.interest push refreshes at once', (tester) async {
      repo.current = right(_request(DeliveryRequestState.searching));
      await pumpSheet(tester);
      expect(repo.currentCalls, 1);

      repo.current = right(
        _request(
          DeliveryRequestState.ridersInterested,
          interested: [_rider()],
        ),
      );
      bus.publish(
        const DeliveryPushEvent(
          type: DeliveryPushType.interest,
          subOrderId: 'sub-1',
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(repo.currentCalls, 2, reason: 'well before the 5 s poll');
      expect(find.text('Ramesh K.'), findsOneWidget);

      // Another order's push is not this sheet's business.
      bus.publish(
        const DeliveryPushEvent(
          type: DeliveryPushType.interest,
          subOrderId: 'sub-other',
        ),
      );
      await tester.pump();
      expect(repo.currentCalls, 2);
    });

    testWidgets('the own-courier fallback pops with that outcome', (
      tester,
    ) async {
      setPhoneView(tester);
      repo.current = right(_request(DeliveryRequestState.searching));
      bus = DeliveryPushBus();
      addTearDown(bus.dispose);
      VendorPartnerSheetOutcome? outcome;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vendorOrdersRepositoryProvider.overrideWithValue(repo),
            deliveryPushBusProvider.overrideWithValue(bus),
          ],
          child: ordersTestApp(
            Builder(
              builder: (context) => TextButton(
                onPressed: () async => outcome =
                    await showVendorDeliveryPartnerSheet(
                      context,
                      subOrderId: 'sub-1',
                    ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final own = find.byKey(VendorDeliveryPartnerSheet.ownCourierKey);
      await tester.ensureVisible(own);
      await tester.tap(own);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(outcome, isA<VendorPartnerUseOwnCourier>());
      expect(find.byType(VendorDeliveryPartnerSheet), findsNothing);
    });

    testWidgets('no overflow at 320dp with text ×1.3', (tester) async {
      repo.current = right(
        _request(
          DeliveryRequestState.ridersInterested,
          interested: [_rider(name: 'Ramchandra Bahadur Shrestha')],
        ),
      );
      await pumpSheet(tester, width: 320, textScale: 1.3);
      expectNoLayoutErrors(tester);
    });
  });
}
