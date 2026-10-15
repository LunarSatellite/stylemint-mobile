import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/cancelled_order_views.dart';

// A seller cancelling (rejecting) their part of an order must read as exactly
// that on the buyer's side — never as "Preparing for Shipping".

Map<String, dynamic> _sub({
  required String id,
  required int state,
  int? cancelledBy,
  int? reason,
  String? note,
  String? refund,
  String title = 'Kurta',
  double subtotal = 300,
}) => {
  'id': id,
  'state': state,
  'cancelledBy': cancelledBy,
  'vendorRejectionReasonCode': reason,
  'cancellationNote': note,
  'refundStatus': refund,
  'subtotalAmount': subtotal,
  'subtotalCurrency': 'NPR',
  'lines': [
    {
      'id': 'line-$id',
      'productVariantId': 'variant-$id',
      'productTitleSnapshot': title,
      'quantity': 1,
      'unitPriceAmount': subtotal,
    },
  ],
};

OrderDetail _order({
  required int state,
  required List<Map<String, dynamic>> subs,
}) => OrderDetailDto.fromJson({
  'id': 'order-1',
  'orderNumber': 'NK2026-07001',
  'state': state,
  'placedUtc': '2026-10-01T09:00:00Z',
  'paymentMethod': 1,
  'subOrders': subs,
}).toDomain();

void main() {
  group('order detail mapping', () {
    test(
      'every part cancelled by its seller reads as Cancelled by the seller',
      () {
        // Even if the order row has not caught up (state 2 = Paid).
        final order = _order(
          state: 2,
          subs: [
            _sub(
              id: 'a',
              state: 8,
              cancelledBy: 1,
              reason: 1,
              refund: 'Pending',
            ),
          ],
        );

        expect(order.status, OrderTrackStatus.cancelled);
        expect(order.cancelledBySellers, isTrue);
        expect(order.canCancel, isFalse);
        final part = order.cancelledParts.single;
        expect(part.headline, 'Cancelled by the seller');
        expect(part.reason, 'Out of stock');
        expect(part.refund, CancelledPartRefund.pending);
        expect(order.items.single.status, 'Cancelled by the seller');
      },
    );

    test('mixed order keeps the live part on its own status', () {
      final order = _order(
        state: 2,
        subs: [
          _sub(
            id: 'a',
            state: 8,
            cancelledBy: 1,
            reason: 6,
            note: 'Shop closed for a festival',
            refund: 'Completed',
          ),
          _sub(id: 'b', state: 13, title: 'Shawl'),
        ],
      );

      expect(order.status, OrderTrackStatus.preparingForShipping);
      expect(order.cancelledParts, hasLength(1));
      expect(
        order.cancelledParts.single.reason,
        'Other — Shop closed for a festival',
      );
      expect(order.cancelledParts.single.refund, CancelledPartRefund.completed);
      final byName = {for (final i in order.items) i.productName: i.status};
      expect(byName['Kurta'], 'Cancelled by the seller');
      expect(byName['Shawl'], 'Packed');
    });

    test('mixed order whose live part is delivered reads as delivered', () {
      final order = _order(
        state: 3,
        subs: [
          _sub(id: 'a', state: 8, cancelledBy: 1, reason: 1, refund: 'Pending'),
          _sub(id: 'b', state: 7, title: 'Shawl'),
        ],
      );

      expect(order.status, OrderTrackStatus.delivered);
    });

    test('a buyer cancel is not attributed to the seller', () {
      final order = _order(
        state: 5,
        subs: [
          _sub(id: 'a', state: 8, cancelledBy: 2, refund: 'NotCharged'),
        ],
      );

      expect(order.cancelledParts.single.headline, 'Cancelled');
      expect(order.cancelledBySellers, isFalse);
      expect(order.items.single.status, 'Cancelled');
    });
  });

  group('CancelledPartsCard', () {
    Future<void> pump(WidgetTester tester, List<CancelledOrderPart> parts) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: CancelledPartsCard(parts: parts)),
          ),
        );

    testWidgets('shows who cancelled, why, and the refund', (tester) async {
      final order = _order(
        state: 2,
        subs: [
          _sub(id: 'a', state: 8, cancelledBy: 1, reason: 1, refund: 'Pending'),
          _sub(id: 'b', state: 13, title: 'Shawl'),
        ],
      );
      await pump(tester, order.cancelledParts);

      expect(find.text('Cancelled by the seller'), findsOneWidget);
      expect(find.text('Kurta'), findsOneWidget);
      expect(find.text('Reason: Out of stock'), findsOneWidget);
      expect(find.textContaining('Refund processing'), findsOneWidget);
      expect(find.textContaining('Shipping'), findsNothing);
      expect(find.textContaining('Shawl'), findsNothing);
    });

    testWidgets('cash on delivery says nothing was charged', (tester) async {
      final order = _order(
        state: 2,
        subs: [
          _sub(
            id: 'a',
            state: 8,
            cancelledBy: 1,
            reason: 1,
            refund: 'NotCharged',
          ),
          _sub(id: 'b', state: 3),
        ],
      );
      await pump(tester, order.cancelledParts);

      expect(find.text('You were not charged'), findsOneWidget);
    });

    testWidgets('draws nothing when nothing was cancelled', (tester) async {
      await pump(tester, const []);
      expect(find.byKey(const Key('cancelled-parts-card')), findsNothing);
    });
  });
}
