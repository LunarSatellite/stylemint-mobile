import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/customer_return_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/customer_return.dart';

/// The `CustomerReturnRequestDto` example from docs/mall/orders-contract.md §4.
const Map<String, dynamic> contractReturnJson = {
  'id': 'c1f2',
  'orderId': 'a91d',
  'orderNumber': 'NK2026-00321',
  'subOrderId': '5b8c',
  'subOrderLineId': '9e77',
  'product': {
    'productVariantId': 'd4e5',
    'title': 'Linen Shirt',
    'variantLabel': 'M / Blue',
    'thumbnailUrl': 'https://cdn.example.com/shirt.jpg',
    'unitPriceAmount': 1200.0,
    'unitPriceCurrency': 'NPR',
  },
  'quantity': 1,
  'reason': 'Too small',
  'photoUrls': ['https://cdn.example.com/r1.jpg'],
  'state': 3,
  'submittedUtc': '2026-09-13T13:00:00+00:00',
  'resolvedUtc': '2026-09-15T09:00:00+00:00',
  'rejectionNote': 'Item shows signs of wear',
  'timeline': [
    {'state': 1, 'occurredUtc': '2026-09-13T13:00:00+00:00'},
    {'state': 3, 'occurredUtc': '2026-09-15T09:00:00+00:00'},
  ],
  'refundStatus': null,
};

void main() {
  group('CustomerReturnDto', () {
    test('parses the contract example', () {
      final r = CustomerReturnDto.fromJson(contractReturnJson).toDomain();

      expect(r.id, 'c1f2');
      expect(r.orderId, 'a91d');
      expect(r.orderNumber, 'NK2026-00321');
      expect(r.subOrderId, '5b8c');
      expect(r.subOrderLineId, '9e77');
      expect(r.product.productVariantId, 'd4e5');
      expect(r.product.title, 'Linen Shirt');
      expect(r.product.variantLabel, 'M / Blue');
      expect(r.product.thumbnailUrl, 'https://cdn.example.com/shirt.jpg');
      expect(r.product.unitPrice.amount, 1200);
      expect(r.product.unitPrice.currency, 'NPR');
      expect(r.quantity, 1);
      expect(r.reason, 'Too small');
      expect(r.photoUrls, ['https://cdn.example.com/r1.jpg']);
      expect(r.status, ReturnRequestStatus.rejected);
      expect(r.submittedUtc, DateTime.utc(2026, 9, 13, 13));
      expect(r.resolvedUtc, DateTime.utc(2026, 9, 15, 9));
      expect(r.rejectionNote, 'Item shows signs of wear');
      expect(r.timeline.map((e) => e.status), [
        ReturnRequestStatus.submitted,
        ReturnRequestStatus.rejected,
      ]);
      expect(r.refundStatus, isNull);
    });

    test('whole-number amounts and a null approval time parse', () {
      final r = CustomerReturnDto.fromJson({
        ...contractReturnJson,
        'product': {
          ...contractReturnJson['product'] as Map<String, dynamic>,
          'unitPriceAmount': 1200,
        },
        'state': 4,
        'timeline': [
          {'state': 1, 'occurredUtc': '2026-09-13T13:00:00Z'},
          {'state': 2, 'occurredUtc': null},
          {'state': 4, 'occurredUtc': '2026-09-15T09:00:00Z'},
        ],
      }).toDomain();

      expect(r.product.unitPrice.amount, 1200);
      expect(r.status, ReturnRequestStatus.completed);
      expect(r.timeline[1].occurredUtc, isNull);
    });

    test('higher-price replacement exposes verified payment status', () {
      final r = CustomerReturnDto.fromJson({
        'id': 'exchange-1',
        'submittedUtc': '2026-09-17T10:00:00Z',
        'state': 4,
        'resolution': 2,
        'replacementUnitPriceAmount': 1600,
        'replacementUnitPriceCurrency': 'NPR',
        'replacementPriceDifferenceAmount': 400,
        'replacementState': 7,
        'replacementPaymentStatus': 'Failed',
      }).toDomain();

      expect(r.resolution, CustomerReturnResolution.replacement);
      expect(
        r.replacementState,
        CustomerReplacementState.awaitingBalancePayment,
      );
      expect(r.replacementPaymentStatus, 'Failed');
      expect(r.replacementPriceDifferenceAmount, 400);
    });

    test('unknown return state ints never throw', () {
      final r = CustomerReturnDto.fromJson({
        'id': 'x',
        'submittedUtc': '2026-09-13T13:00:00Z',
        'state': 12,
        'timeline': [
          {'state': 99},
        ],
      }).toDomain();

      expect(r.status, ReturnRequestStatus.unknown);
      expect(r.timeline.single.status, ReturnRequestStatus.unknown);
      expect(r.photoUrls, isEmpty);
      expect(r.product.thumbnailUrl, isNull);
    });
  });
}
