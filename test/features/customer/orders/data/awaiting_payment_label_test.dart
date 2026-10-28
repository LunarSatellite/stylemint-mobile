import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_payment_state.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/tracked_order_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_status_badge.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

// An online payment is not an order until it is paid: the server holds it at
// Placed (state 1) and only releases it to the seller once the payment
// clears. The buyer's list and detail must say so rather than "Preparing for
// Shipping" or "Confirmed".

const _esewa = 3;
const _card = 1;
const _payPal = 2;
const _cod = 4;

TrackedOrder _listed({required int state, int? paymentMethod}) =>
    TrackedOrderDto.fromJson({
      'id': 'order-1',
      'orderNumber': 'NK2026-08001',
      'grandTotalAmount': 2500,
      'grandTotalCurrency': 'NPR',
      'placedUtc': '2026-10-28T09:00:00Z',
      'itemCount': 1,
      'state': state,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
    }).toDomain();

Map<String, dynamic> _sub({required int state}) => {
  'id': 'sub-1',
  'state': state,
  'subtotalAmount': 2500,
  'subtotalCurrency': 'NPR',
  'lines': [
    {
      'id': 'line-1',
      'productVariantId': 'variant-1',
      'productTitleSnapshot': 'Kurta',
      'quantity': 1,
      'unitPriceAmount': 2500,
    },
  ],
};

void main() {
  group('orders list', () {
    test('an unpaid eSewa order reads Awaiting payment', () {
      final order = _listed(state: 1, paymentMethod: _esewa);
      expect(order.status, OrderTrackStatus.awaitingPayment);
      expect(order.status.label, 'Awaiting payment');
    });

    test('card and PayPal orders waiting on payment read the same', () {
      for (final method in [_card, _payPal]) {
        expect(
          _listed(state: 1, paymentMethod: method).status,
          OrderTrackStatus.awaitingPayment,
        );
      }
    });

    test('a placed Cash on Delivery order is simply placed', () {
      expect(
        _listed(state: 1, paymentMethod: _cod).status,
        OrderTrackStatus.preparingForShipping,
      );
    });

    test('an older server that sends no method labels as before', () {
      expect(
        _listed(state: 1).status,
        OrderTrackStatus.preparingForShipping,
      );
    });

    test('once paid it moves on', () {
      expect(
        _listed(state: 2, paymentMethod: _esewa).status,
        OrderTrackStatus.preparingForShipping,
      );
      expect(
        _listed(state: 5, paymentMethod: _esewa).status,
        OrderTrackStatus.cancelled,
      );
    });

    testWidgets('the list row badge says Awaiting payment', (tester) async {
      final order = _listed(state: 1, paymentMethod: _esewa);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: OrderStatusBadge(status: order.status, dense: true),
          ),
        ),
      );
      expect(find.text('Awaiting payment'), findsOneWidget);
      expect(find.text('Preparing for Shipping'), findsNothing);
      expect(find.byIcon(Icons.hourglass_bottom_rounded), findsOneWidget);
    });
  });

  group('order detail', () {
    test('an unpaid eSewa order and its items read Awaiting payment', () {
      final order = OrderDetailDto.fromJson({
        'id': 'order-1',
        'orderNumber': 'NK2026-08001',
        'state': 1,
        'placedUtc': '2026-10-28T09:00:00Z',
        'paymentMethod': _esewa,
        'subOrders': [_sub(state: 1)],
      }).toDomain();

      expect(order.status, OrderTrackStatus.awaitingPayment);
      expect(order.items.single.status, 'Awaiting payment');
      expect(order.paymentMethod, 'eSewa');
      // Still the buyer's to cancel.
      expect(order.canCancel, isTrue);
    });

    test('a placed Cash on Delivery order keeps its usual labels', () {
      final order = OrderDetailDto.fromJson({
        'id': 'order-1',
        'orderNumber': 'NK2026-08001',
        'state': 1,
        'placedUtc': '2026-10-28T09:00:00Z',
        'paymentMethod': _cod,
        'subOrders': [_sub(state: 1)],
      }).toDomain();

      expect(order.status, OrderTrackStatus.preparingForShipping);
      expect(order.items.single.status, 'Confirmed');
    });

    test('a paid eSewa order is no longer awaiting payment', () {
      final order = OrderDetailDto.fromJson({
        'id': 'order-1',
        'orderNumber': 'NK2026-08001',
        'state': 2,
        'placedUtc': '2026-10-28T09:00:00Z',
        'paymentMethod': _esewa,
        'subOrders': [_sub(state: 2)],
      }).toDomain();

      expect(order.status, OrderTrackStatus.preparingForShipping);
    });
  });

  test('only Cash on Delivery is paid at the door', () {
    expect(OrderPaymentState.isOnline(_cod), isFalse);
    for (final method in [_card, _payPal, _esewa]) {
      expect(OrderPaymentState.isOnline(method), isTrue);
    }
    expect(
      OrderPaymentState.awaitsPayment(state: 2, paymentMethod: _esewa),
      isFalse,
    );
  });
}
