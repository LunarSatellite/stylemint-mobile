import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_invoice_dto.dart';

void main() {
  test('maps every rendered order-invoice field from the backend contract', () {
    final invoice = OrderInvoiceDto.fromJson(const {
      'invoiceNumber': 'INV-NK2026-00001',
      'orderNumber': 'NK2026-00001',
      'issuedUtc': '2026-09-08T08:00:00Z',
      'placedUtc': '2026-09-07T08:00:00Z',
      'shipTo': {
        'receiverName': 'Sumendra Pandey',
        'addressLine1': 'Thamel',
        'city': 'Kathmandu',
        'state': 'Bagmati',
        'zipCode': '44600',
      },
      'paymentMethod': 3,
      'paymentStatus': 'Paid',
      'subtotalAmount': 1000,
      'shippingTotalAmount': 100,
      'grandTotalAmount': 1100,
      'currency': 'NPR',
      'items': [
        {
          'productTitleSnapshot': 'Wireless Keyboard',
          'variantLabelSnapshot': 'Black',
          'quantity': 2,
          'unitPriceAmount': 500,
          'lineSubtotalAmount': 1000,
        },
      ],
    }).toDomain();

    expect(invoice.invoiceNumber, 'INV-NK2026-00001');
    expect(invoice.paymentMethod, 'eSewa');
    expect(invoice.paymentStatus, 'Paid');
    expect(invoice.shippingAddress, 'Thamel, Kathmandu, Bagmati, 44600');
    expect(invoice.items.single.lineSubtotal.amount, 1000);
  });
}
