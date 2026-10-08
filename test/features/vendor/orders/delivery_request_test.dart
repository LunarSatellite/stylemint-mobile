import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/delivery_request.dart';

void main() {
  group('DeliveryRequest.fromJson', () {
    test('reads the contract shape', () {
      final request = DeliveryRequest.fromJson({
        'packageId': 'pkg-1',
        'state': 'RidersInterested',
        'notifiedCount': 4,
        'openedUtc': '2026-10-08T10:00:00Z',
        'expiresUtc': '2026-10-08T10:15:00Z',
        'radiusKm': 5,
        'interested': [
          {
            'offerId': 'offer-1',
            'courierId': 'courier-1',
            'displayName': 'Ramesh K.',
            'avatarUrl': null,
            'tier': 'Pro',
            'rating': 4.8,
            'completedDeliveries': 12,
            'distanceKm': 1.4,
            'vehicle': 'Bike',
            'interestedUtc': '2026-10-08T10:02:00Z',
          },
        ],
        'assigned': null,
      });

      expect(request.state, DeliveryRequestState.ridersInterested);
      expect(request.notifiedCount, 4);
      expect(request.radiusKm, 5);
      expect(request.expiresUtc, DateTime.utc(2026, 10, 8, 10, 15));
      expect(request.assigned, isNull);

      final rider = request.interested.single;
      expect(rider.offerId, 'offer-1');
      expect(rider.displayName, 'Ramesh K.');
      expect(rider.tier, 'Pro');
      expect(rider.rating, 4.8);
      expect(rider.completedDeliveries, 12);
      expect(rider.distanceKm, 1.4);
      expect(rider.vehicle, 'Bike');
      expect(rider.avatarUrl, isNull);
    });

    test('reads an assignment with a masked phone', () {
      final request = DeliveryRequest.fromJson({
        'state': 'Assigned',
        'assigned': {
          'courierId': 'courier-1',
          'displayName': 'Ramesh K.',
          'phone': '98XXXXXX12',
        },
      });
      expect(request.state, DeliveryRequestState.assigned);
      expect(request.assigned?.displayName, 'Ramesh K.');
      expect(request.assigned?.phone, '98XXXXXX12');
    });

    test('every contract state string parses', () {
      const wires = {
        'Searching': DeliveryRequestState.searching,
        'RidersInterested': DeliveryRequestState.ridersInterested,
        'Assigned': DeliveryRequestState.assigned,
        'Expired': DeliveryRequestState.expired,
        'NoRiders': DeliveryRequestState.noRiders,
      };
      wires.forEach((wire, state) {
        expect(DeliveryRequestState.fromWire(wire), state, reason: wire);
      });
    });

    test('numeric states are tolerated, 1-based in contract order', () {
      expect(DeliveryRequestState.fromWire(1), DeliveryRequestState.searching);
      expect(DeliveryRequestState.fromWire(5), DeliveryRequestState.noRiders);
      expect(DeliveryRequestState.fromWire(9), isNull);
    });

    test('an unknown state falls back on what the payload carries', () {
      expect(
        DeliveryRequest.fromJson({'state': 'Mystery'}).state,
        DeliveryRequestState.searching,
      );
      expect(
        DeliveryRequest.fromJson({
          'state': 'Mystery',
          'interested': [
            {'offerId': 'o'},
          ],
        }).state,
        DeliveryRequestState.ridersInterested,
      );
      expect(
        DeliveryRequest.fromJson({
          'state': 'Mystery',
          'assigned': {'courierId': 'c'},
        }).state,
        DeliveryRequestState.assigned,
      );
    });

    test('tiers are worded for a vendor, numeric or string', () {
      String tierOf(Object? wire) =>
          InterestedRider.fromJson({'offerId': 'o', 'tier': wire}).tier;
      expect(tierOf('Neighbor'), 'Neighbour');
      expect(tierOf('Traveler'), 'Traveller');
      expect(tierOf('Pro'), 'Pro');
      expect(tierOf(1), 'Neighbour');
      expect(tierOf('Galactic'), 'Partner');
    });

    test('missing fields do not throw', () {
      final request = DeliveryRequest.fromJson(const {});
      expect(request.interested, isEmpty);
      expect(request.radiusKm, 5);
      expect(request.expiresUtc, isNull);
      expect(request.remainingAt(DateTime.now().toUtc()), isNull);
    });

    test('a rider with no offer id is dropped — it cannot be chosen', () {
      final request = DeliveryRequest.fromJson({
        'interested': [
          {'displayName': 'Nobody'},
          {'offerId': 'offer-2', 'displayName': 'Sita'},
        ],
      });
      expect(request.interested.map((r) => r.offerId), ['offer-2']);
    });
  });

  test('Assigned and Expired are settled; the rest are still moving', () {
    expect(DeliveryRequestState.assigned.isSettled, isTrue);
    expect(DeliveryRequestState.expired.isSettled, isTrue);
    expect(DeliveryRequestState.searching.isSettled, isFalse);
    expect(DeliveryRequestState.ridersInterested.isSettled, isFalse);
    expect(DeliveryRequestState.noRiders.isSettled, isFalse);
  });
}
