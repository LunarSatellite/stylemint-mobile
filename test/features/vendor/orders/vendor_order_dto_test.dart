import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_order_dto.dart';

void main() {
  test('maps the backend receiverName into the vendor order row', () {
    final order = VendorOrderDto.fromJson({
      'id': '65b5d2fb-7c09-4a3c-aebc-a97495fa91f1',
      'orderNumber': 'NK2026-00042',
      'state': 3,
      'subtotalAmount': 1250,
      'subtotalCurrency': 'NPR',
      'itemCount': 2,
      'receiverName': 'Asha Rai',
      'placedUtc': '2026-09-07T08:00:00Z',
    }).toDomain();

    expect(order.customerName, 'Asha Rai');
    expect(order.itemCount, 2);
  });
}
