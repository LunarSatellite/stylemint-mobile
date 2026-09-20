import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/order_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

Money _npr(double a) => Money(amount: a, currency: 'NPR');

/// Delivered, so the "Rate Your Items" section renders. Its row put an
/// unflexed "Write a Review" button beside the product name, which squeezed
/// the name to zero width and overflowed the row by 64px at 320dp x 1.3.
final _order = OrderDetail(
  id: 'order-id',
  orderNumber: 'NK2026-00015',
  status: OrderTrackStatus.delivered,
  placedAt: DateTime.utc(2026, 9, 11),
  estimatedDelivery: DateTime.utc(2026, 9, 14),
  items: [
    OrderDetailItem(
      id: 'i1',
      subOrderId: 'sub-1',
      productId: 'prod-1',
      productName: 'Hand-loomed pashmina overcoat',
      imageUrl: 'https://example.test/coat.jpg',
      variantName: 'L / Charcoal',
      qty: 12,
      unitPrice: _npr(62250),
      status: 'Delivered',
    ),
  ],
  subtotal: _npr(124500),
  shipping: _npr(1200),
  tax: _npr(16185),
  total: _npr(141885),
  shippingAddress: 'Kathmandu, Nepal',
  paymentMethod: 'eSewa',
  trackingNumber: 'SM-D-00000001',
  canCancel: false,
  canReturn: true,
);

void main() {
  testWidgets(
    'OrderDetailScreen does not overflow at 320dp with text at 1.3x',
    (tester) async {
      final repository = _MockOrdersRepository();
      when(
        () => repository.getOrderDetail('NK2026-00015'),
      ).thenAnswer((_) async => right(_order));
      when(
        () => repository.getOrderTimeline(any()),
      ).thenAnswer((_) async => left(const NetworkExceptions.notFound()));
      when(
        () => repository.getOrderCarePlan(any()),
      ).thenAnswer((_) async => left(const NetworkExceptions.notFound()));
      when(
        () => repository.getWarrantyEligibility(any()),
      ).thenAnswer((_) async => left(const NetworkExceptions.notFound()));

      await tester.binding.setSurfaceSize(const Size(320, 2600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(320, 2600),
                textScaler: TextScaler.linear(1.3),
              ),
              child: OrderDetailScreen(orderId: 'NK2026-00015'),
            ),
          ),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(tester.takeException(), isNull);
      // The item being reviewed must still be on screen, not squeezed out.
      expect(find.text('Rate Your Items'), findsOneWidget);
      expect(
        find.textContaining('Hand-loomed pashmina overcoat'),
        findsWidgets,
      );
    },
  );
}
