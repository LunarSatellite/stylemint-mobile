import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_job_mapper.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_job_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_delivery.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/order_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/screens/vendor_order_detail_screen.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import 'courier/courier_job_mapper_test.dart' show contractJobJson;

const _money = Money(amount: 1, currency: 'NPR');

OrderDetail _order(OrderTrackStatus status, {bool awaiting = false}) =>
    OrderDetail(
      id: 'o-1',
      orderNumber: 'NK-1',
      status: status,
      placedAt: DateTime.utc(2026, 10, 9),
      estimatedDelivery: DateTime.utc(2026, 10, 10),
      items: const [],
      subtotal: _money,
      shipping: _money,
      tax: _money,
      total: _money,
      shippingAddress: '',
      paymentMethod: 'eSewa',
      canCancel: false,
      canReturn: false,
      delivery: OrderDelivery(
        packageNumber: 'SM-D-1',
        status: awaiting ? 'AwaitingConfirmation' : 'PickedUp',
        awaitingConfirmation: awaiting,
      ),
    );

VendorOrder _vendor(VendorOrderStatus status) => VendorOrder(
  id: 's-1',
  orderNumber: 'NK-1',
  itemCount: 1,
  total: _money,
  status: status,
);

void main() {
  test('buyer order: 5 s at the door, 10 s on the way, none when done', () {
    expect(
      OrderDetailScreen.pollIntervalFor(
        _order(OrderTrackStatus.outForDelivery, awaiting: true),
      ),
      const Duration(seconds: 5),
    );
    for (final moving in [
      OrderTrackStatus.preparingForShipping,
      OrderTrackStatus.inTransit,
      OrderTrackStatus.outForDelivery,
    ]) {
      expect(
        OrderDetailScreen.pollIntervalFor(_order(moving)),
        const Duration(seconds: 10),
        reason: '$moving',
      );
    }
    expect(
      OrderDetailScreen.pollIntervalFor(_order(OrderTrackStatus.delivered)),
      isNull,
    );
    expect(
      OrderDetailScreen.pollIntervalFor(_order(OrderTrackStatus.cancelled)),
      isNull,
    );
    expect(OrderDetailScreen.pollIntervalFor(null), isNull);
  });

  test('vendor sub-order: 10 s while shipped or with the rider', () {
    for (final status in [
      VendorOrderStatus.shipped,
      VendorOrderStatus.handedOver,
    ]) {
      expect(
        VendorOrderDetailScreen.pollIntervalFor(_vendor(status)),
        const Duration(seconds: 10),
        reason: '$status',
      );
    }
    for (final status in [
      VendorOrderStatus.pending,
      VendorOrderStatus.packed,
      VendorOrderStatus.delivered,
      VendorOrderStatus.cancelled,
    ]) {
      expect(
        VendorOrderDetailScreen.pollIntervalFor(_vendor(status)),
        isNull,
        reason: '$status',
      );
    }
  });

  test('rider job: 10 s until delivered or cancelled', () {
    Duration? every(String status) => CourierJobScreen.pollIntervalFor(
      CourierJobMapper.job(contractJobJson(status: status)),
    );
    expect(every('Assigned'), const Duration(seconds: 10));
    expect(every('PickedUp'), const Duration(seconds: 10));
    expect(every('AwaitingConfirmation'), const Duration(seconds: 10));
    expect(every('Delivered'), isNull);
    expect(every('Cancelled'), isNull);
  });
}
