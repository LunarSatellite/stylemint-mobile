import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_order_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/repositories/vendor_orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/vendor_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _MockVendorOrdersRepository extends Mock
    implements VendorOrdersRepository {}

Map<String, dynamic> _row(int state) => {
  'id': 'sub-$state',
  'orderNumber': 'NK2026-00042',
  'state': state,
  'subtotalAmount': 1250,
  'subtotalCurrency': 'NPR',
};

VendorOrder _order(int state) => VendorOrder(
  id: 'sub-1',
  orderNumber: 'NK2026-00042',
  itemCount: 1,
  total: const Money(amount: 1250, currency: 'NPR'),
  status: vendorOrderStatusFromState(state),
  stateCode: state,
);

void main() {
  group('SubOrderState parsing', () {
    test('maps the seller steps 12–14 with their labels', () {
      final accepted = VendorOrderDto.fromJson(_row(12)).toDomain();
      final packed = VendorOrderDto.fromJson(_row(13)).toDomain();
      final handedOver = VendorOrderDto.fromJson(_row(14)).toDomain();

      expect(accepted.status, VendorOrderStatus.accepted);
      expect(accepted.status.label, 'Accepted');
      expect(accepted.stateCode, 12);
      expect(packed.status, VendorOrderStatus.packed);
      expect(packed.status.label, 'Packed');
      expect(handedOver.status, VendorOrderStatus.handedOver);
      expect(handedOver.status.label, 'Handed over');
    });

    test('the detail DTO uses the same mapping', () {
      final order = VendorOrderDetailDto.fromJson({
        ..._row(13),
        'acceptedUtc': '2026-09-15T10:02:11+00:00',
        'packedUtc': '2026-09-15T11:00:00+00:00',
        'handedOverUtc': null,
        'lines': const <dynamic>[],
      }).toDomain();

      expect(order.status, VendorOrderStatus.packed);
      expect(order.stateCode, 13);
    });

    test('unknown ints fall back to Pending instead of throwing', () {
      final order = VendorOrderDto.fromJson(_row(99)).toDomain();
      expect(order.status, VendorOrderStatus.pending);
      expect(vendorActionsForState(99), isEmpty);
    });

    test('legacy states keep their buckets', () {
      expect(vendorOrderStatusFromState(2), VendorOrderStatus.confirmed);
      expect(vendorOrderStatusFromState(3), VendorOrderStatus.processing);
      expect(vendorOrderStatusFromState(10), VendorOrderStatus.shipped);
      expect(VendorOrderStatus.accepted.isPreShipment, isTrue);
      expect(VendorOrderStatus.packed.isPreShipment, isTrue);
      expect(VendorOrderStatus.packed.isToShip, isTrue);
      expect(VendorOrderStatus.handedOver.isInTransit, isTrue);
    });
  });

  group('vendorActionsForState', () {
    test('offers the contract transitions per state', () {
      const accept = [VendorOrderAction.accept, VendorOrderAction.reject];
      expect(vendorActionsForState(SubOrderStateCode.paid), accept);
      expect(
        vendorActionsForState(SubOrderStateCode.awaitingFulfillment),
        accept,
      );
      expect(vendorActionsForState(SubOrderStateCode.accepted), [
        VendorOrderAction.markPacked,
      ]);
      expect(vendorActionsForState(SubOrderStateCode.packed), [
        VendorOrderAction.handOver,
        VendorOrderAction.readyToShip,
      ]);
      for (final state in [
        SubOrderStateCode.handedOver,
        SubOrderStateCode.shipped,
        SubOrderStateCode.inTransit,
        SubOrderStateCode.outForDelivery,
      ]) {
        expect(vendorActionsForState(state), [
          VendorOrderAction.markDelivered,
        ]);
      }
      for (final state in [
        SubOrderStateCode.pending,
        SubOrderStateCode.readyToShip,
        SubOrderStateCode.awaitingTracking,
        SubOrderStateCode.delivered,
        SubOrderStateCode.cancelled,
        SubOrderStateCode.returned,
      ]) {
        expect(vendorActionsForState(state), isEmpty);
      }
    });

    test('reject reason codes match the contract', () {
      expect(VendorRejectionReason.values.map((r) => r.code), [
        1,
        2,
        3,
        4,
        5,
        6,
      ]);
      expect(VendorRejectionReason.other.requiresNote, isTrue);
      expect(VendorRejectionReason.outOfStock.requiresNote, isFalse);
    });
  });

  group('VendorOrderDetailNotifier seller steps', () {
    late _MockVendorOrdersRepository repository;
    late VendorOrderDetailNotifier notifier;

    setUpAll(() => registerFallbackValue(VendorRejectionReason.other));

    setUp(() async {
      repository = _MockVendorOrdersRepository();
      when(
        () => repository.getOrderDetail('sub-1'),
      ).thenAnswer((_) async => right(_order(3)));
      notifier = VendorOrderDetailNotifier(repository);
      await notifier.loadOrder('sub-1');
    });

    test(
      'accept goes through actionInProgress to the refreshed order',
      () async {
        when(
          () => repository.acceptOrder('sub-1'),
        ).thenAnswer((_) async => right(_order(12)));
        final states = <OrderDetailState>[];
        final remove = notifier.addListener(states.add, fireImmediately: false);

        await notifier.accept();
        remove();

        expect(states, [
          OrderDetailState.actionInProgress(_order(3)),
          OrderDetailState.loadSuccess(_order(12)),
        ]);
      },
    );

    test('reject passes the reason and note', () async {
      when(
        () => repository.rejectOrder(
          'sub-1',
          reason: any(named: 'reason'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => right(_order(8)));

      await notifier.reject(
        reason: VendorRejectionReason.other,
        note: 'Sold out this morning',
      );

      verify(
        () => repository.rejectOrder(
          'sub-1',
          reason: VendorRejectionReason.other,
          note: 'Sold out this morning',
        ),
      ).called(1);
      expect(notifier.state, OrderDetailState.loadSuccess(_order(8)));
    });

    test('a failure is actionFailure and the next action still runs', () async {
      when(() => repository.markPacked('sub-1')).thenAnswer(
        (_) async => left(
          const NetworkExceptions.validation(code: 'state.invalid_transition'),
        ),
      );

      await notifier.markPacked();
      expect(
        notifier.state,
        OrderDetailState.actionFailure(
          _order(3),
          const NetworkExceptions.validation(code: 'state.invalid_transition'),
        ),
      );

      when(
        () => repository.acceptOrder('sub-1'),
      ).thenAnswer((_) async => right(_order(12)));
      await notifier.accept();
      expect(notifier.state, OrderDetailState.loadSuccess(_order(12)));
    });

    test('hand over passes carrier, tracking number and note', () async {
      when(
        () => repository.handOver(
          'sub-1',
          carrier: any(named: 'carrier'),
          trackingNumber: any(named: 'trackingNumber'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => right(_order(14)));

      await notifier.handOver(
        carrier: 'Pathao',
        trackingNumber: 'PTH-99812',
        note: 'Given to rider Ram at the gate',
      );

      verify(
        () => repository.handOver(
          'sub-1',
          carrier: 'Pathao',
          trackingNumber: 'PTH-99812',
          note: 'Given to rider Ram at the gate',
        ),
      ).called(1);
    });
  });
}
