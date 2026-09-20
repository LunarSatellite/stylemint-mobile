import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/replacement_shipment.dart';

void main() {
  test('parses replacement shipment tracking and outbound state', () {
    final shipment = ReplacementShipment.fromJson({
      'id': 'shipment-1',
      'returnRequestId': 'return-1',
      'replacementVariantId': 'variant-2',
      'trackingNumber': 'SM-X-00000042',
      'state': 2,
      'quantity': 1,
      'originAddressLine': 'Vendor warehouse',
      'destinationAddressLine': 'Buyer address',
      'readyUtc': '2026-09-17T10:00:00Z',
      'shippedUtc': '2026-09-17T11:00:00Z',
    });

    expect(shipment.trackingNumber, 'SM-X-00000042');
    expect(shipment.status, ReplacementShipmentStatus.shipped);
    expect(shipment.status.label, 'Replacement on the way');
    expect(shipment.destinationAddressLine, 'Buyer address');
  });

  test('unknown state safely remains ready to ship', () {
    final shipment = ReplacementShipment.fromJson({
      'readyUtc': '2026-09-17T10:00:00Z',
      'state': 99,
    });

    expect(shipment.status, ReplacementShipmentStatus.readyToShip);
  });
}
