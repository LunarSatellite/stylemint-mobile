import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_job_mapper.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_job.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// `CourierJobDto` exactly as the delivery-complete contract spells it.
Map<String, dynamic> contractJobJson({
  String status = 'PickedUp',
  Object? cashToCollect = const {'amount': 2500, 'currency': 'NPR'},
}) => <String, dynamic>{
  'hopId': 'hop-1',
  'packageId': 'pkg-1',
  'packageNumber': 'SM-D-00000013',
  'status': status,
  'assignedUtc': '2026-10-09T08:00:00Z',
  'pickedUpUtc': '2026-10-09T08:20:00Z',
  'deliveredUtc': null,
  'payout': {'amount': 120, 'currency': 'NPR'},
  'cashToCollect': cashToCollect,
  'items': [
    {'name': 'Rose-Gold Watch', 'quantity': 1, 'imageUrl': null},
    {'name': 'Gift box', 'quantity': 2, 'imageUrl': 'https://cdn/x.jpg'},
  ],
  'itemCount': 3,
  'declaredValue': {'amount': 8500, 'currency': 'NPR'},
  'notes': 'Ring the bell twice',
  'pickup': {
    'latitude': 27.6794,
    'longitude': 85.3288,
    'label': 'Shop name',
    'addressLine': 'Jhamsikhel, Lalitpur',
    'contactName': 'Shop owner',
    'contactPhone': '+977-9800000000',
  },
  'dropoff': {
    'latitude': 27.6890,
    'longitude': 85.3150,
    'label': 'Recipient name',
    'addressLine': 'Kupondole',
    'contactName': 'Recipient name',
    'contactPhone': null,
  },
  'distanceKm': 1.7,
};

void main() {
  group('CourierJobMapper.job', () {
    test('reads every field of the contract shape', () {
      final job = CourierJobMapper.job(contractJobJson());

      expect(job.hopId, 'hop-1');
      expect(job.packageId, 'pkg-1');
      expect(job.packageNumber, 'SM-D-00000013');
      expect(job.status, CourierJobStatus.pickedUp);
      expect(job.assignedUtc, DateTime.utc(2026, 10, 9, 8));
      expect(job.pickedUpUtc, DateTime.utc(2026, 10, 9, 8, 20));
      expect(job.deliveredUtc, isNull);
      expect(job.payout, const Money(amount: 120, currency: 'NPR'));
      expect(job.cashToCollect, const Money(amount: 2500, currency: 'NPR'));
      expect(job.declaredValue, const Money(amount: 8500, currency: 'NPR'));
      expect(job.itemCount, 3);
      expect(job.items.map((i) => i.name), ['Rose-Gold Watch', 'Gift box']);
      expect(job.items.last.quantity, 2);
      expect(job.items.last.imageUrl, 'https://cdn/x.jpg');
      expect(job.notes, 'Ring the bell twice');
      expect(job.pickup.point, const GeoPoint(27.6794, 85.3288));
      expect(job.pickup.label, 'Shop name');
      expect(job.pickup.contactPhone, '+977-9800000000');
      expect(job.dropoff.point, const GeoPoint(27.6890, 85.3150));
      expect(job.dropoff.contactPhone, isNull);
      expect(job.distanceKm, 1.7);
    });

    test('each contract status maps, and an unknown one is Assigned', () {
      CourierJobStatus of(String s) =>
          CourierJobMapper.job(contractJobJson(status: s)).status;

      expect(of('Assigned'), CourierJobStatus.assigned);
      expect(of('PickedUp'), CourierJobStatus.pickedUp);
      expect(of('AwaitingConfirmation'), CourierJobStatus.awaitingConfirmation);
      expect(of('Delivered'), CourierJobStatus.delivered);
      expect(of('Cancelled'), CourierJobStatus.cancelled);
      expect(of('awaiting_confirmation'), CourierJobStatus.awaitingConfirmation);
      // The earliest state: its action is the one the server refuses if wrong.
      expect(of('Teleported'), CourierJobStatus.assigned);
    });

    test('a prepaid order has no cash to collect, whether null or zero', () {
      expect(
        CourierJobMapper.job(contractJobJson(cashToCollect: null)).cashToCollect,
        isNull,
      );
      expect(
        CourierJobMapper.job(
          contractJobJson(cashToCollect: {'amount': 0, 'currency': 'NPR'}),
        ).cashToCollect,
        isNull,
      );
    });

    test('a 0,0 or missing point keeps the address but drops the pin', () {
      final stop = CourierJobMapper.stop({
        'latitude': 0,
        'longitude': 0,
        'addressLine': 'Somewhere',
      });
      expect(stop.point, isNull);
      expect(stop.addressLine, 'Somewhere');
      expect(CourierJobMapper.stop(null).point, isNull);
      expect(
        CourierJobMapper.stop({'latitude': '27.7', 'longitude': '85.3'}).point,
        const GeoPoint(27.7, 85.3),
      );
    });

    test('item count falls back to the sum of quantities', () {
      final json = contractJobJson()..remove('itemCount');
      expect(CourierJobMapper.job(json).itemCount, 3);
    });
  });

  group('CourierJobMapper.proof', () {
    test('reads DeliveryProofDto', () {
      final proof = CourierJobMapper.proof({
        'hopId': 'hop-1',
        'packageNumber': 'SM-D-00000013',
        'status': 'Pending',
        'qrPayload': 'https://stylemint.voyageritnepal.com/dc/tok_abc123',
        'code': '482913',
        'expiresUtc': '2026-10-09T09:00:00+00:00',
        'confirmedUtc': null,
      });
      expect(proof.status, DeliveryProofStatus.pending);
      expect(proof.qrPayload, endsWith('/dc/tok_abc123'));
      expect(proof.code, '482913');
      expect(proof.expiresUtc, DateTime.utc(2026, 10, 9, 9));
      expect(proof.confirmedUtc, isNull);
    });

    test('Confirmed and Expired map; anything else keeps polling', () {
      DeliveryProofStatus of(String s) =>
          CourierJobMapper.proof({'status': s}).status;
      expect(of('Confirmed'), DeliveryProofStatus.confirmed);
      expect(of('Expired'), DeliveryProofStatus.expired);
      expect(of('???'), DeliveryProofStatus.pending);
    });

    test('a timestamp without a zone is UTC, not local time', () {
      final proof = CourierJobMapper.proof({
        'expiresUtc': '2026-10-09T09:00:00',
      });
      expect(proof.expiresUtc, DateTime.utc(2026, 10, 9, 9));
    });

    test('expiry is by the server or by the clock', () {
      final expires = DateTime.utc(2026, 10, 9, 9);
      final proof = DeliveryProof(
        hopId: 'h',
        packageNumber: 'p',
        status: DeliveryProofStatus.pending,
        qrPayload: 'q',
        code: '123456',
        expiresUtc: expires,
      );
      expect(proof.isExpiredAt(expires.subtract(const Duration(seconds: 1))),
          isFalse);
      expect(proof.isExpiredAt(expires), isTrue);
      expect(
        proof.remainingAt(expires.subtract(const Duration(minutes: 2))),
        const Duration(minutes: 2),
      );
      expect(proof.remainingAt(expires.add(const Duration(hours: 1))),
          Duration.zero);
    });
  });
}
