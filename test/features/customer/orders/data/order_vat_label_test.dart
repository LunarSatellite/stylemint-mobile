import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_invoice_dto.dart';

/// Catalogue prices include VAT, so on an order placed today the tax line is
/// the VAT inside the total ("Includes VAT"). An older order was charged VAT
/// on top, and there the line is one the total adds. The backend says which
/// with `taxIncluded`; these hold that the app reads it, and that a response
/// without it keeps the wording every screen used before.
void main() {
  Map<String, dynamic> detail([Map<String, dynamic> extra = const {}]) => {
    'id': 'order-1',
    'orderNumber': 'NK2026-00015',
    'state': 2,
    'placedUtc': '2026-09-20T00:00:00Z',
    'subtotalAmount': 1000,
    'taxTotalAmount': 130,
    'grandTotalAmount': 1130,
    ...extra,
  };

  Map<String, dynamic> invoice([Map<String, dynamic> extra = const {}]) => {
    'invoiceNumber': 'INV-NK2026-00015',
    'orderNumber': 'NK2026-00015',
    'issuedUtc': '2026-09-20T00:00:00Z',
    'placedUtc': '2026-09-20T00:00:00Z',
    'subtotalAmount': 1000,
    'taxTotalAmount': 130,
    'grandTotalAmount': 1130,
    'currency': 'NPR',
    ...extra,
  };

  test('an order charged VAT on top says so', () {
    expect(
      OrderDetailDto.fromJson(
        detail({'taxIncluded': false}),
      ).toDomain().taxIncluded,
      isFalse,
    );
    final legacy = OrderInvoiceDto.fromJson(
      invoice({'taxIncluded': false}),
    ).toDomain();
    expect(legacy.taxIncluded, isFalse);
    expect(legacy.toOrderDetail().taxIncluded, isFalse);
  });

  test(
    'VAT inside the price, and a response without the flag, read as included',
    () {
      expect(
        OrderDetailDto.fromJson(
          detail({'taxIncluded': true}),
        ).toDomain().taxIncluded,
        isTrue,
      );
      expect(OrderDetailDto.fromJson(detail()).toDomain().taxIncluded, isTrue);
      expect(
        OrderInvoiceDto.fromJson(invoice()).toDomain().taxIncluded,
        isTrue,
      );
    },
  );

  test('copyWith keeps it', () {
    final order = OrderDetailDto.fromJson(
      detail({'taxIncluded': false}),
    ).toDomain();
    expect(order.copyWith(canReturn: true).taxIncluded, isFalse);
  });
}
