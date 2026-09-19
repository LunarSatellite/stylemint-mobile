import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_pickup.dart';

void main() {
  test('parses reverse pickup tracking and terminal receipt', () {
    final pickup = ReturnPickup.fromJson(<String, dynamic>{
      'id': 'pickup-1',
      'returnRequestId': 'return-1',
      'trackingNumber': 'SM-R-00000077',
      'state': 4,
      'originAddressLine': 'Buyer home, Kathmandu',
      'destinationAddressLine': 'Vendor warehouse, Lalitpur',
      'requestedUtc': '2026-09-17T10:00:00Z',
      'pickedUpUtc': '2026-09-17T11:00:00Z',
      'receivedUtc': '2026-09-17T12:00:00Z',
    });

    expect(pickup.trackingNumber, 'SM-R-00000077');
    expect(pickup.status, ReturnPickupStatus.receivedByVendor);
    expect(pickup.status.label, 'Received by seller');
    expect(pickup.pickedUpUtc, isNotNull);
    expect(pickup.receivedUtc, isNotNull);
  });

  test('unknown state fails safely to requested', () {
    final pickup = ReturnPickup.fromJson(<String, dynamic>{
      'state': 999,
      'requestedUtc': '2026-09-17T10:00:00Z',
    });
    expect(pickup.status, ReturnPickupStatus.requested);
  });
}
