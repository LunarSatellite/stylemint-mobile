import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/customer_return_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/repositories/delivery_confirmation_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/customer_return.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_pickup.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_reason_category.dart';

void main() {
  group('ReturnPickup (return pickup contract)', () {
    test('reads stage, mode, rider, attempts, fare and the flags', () {
      final pickup = ReturnPickup.fromJson({
        'id': 'p-1',
        'returnRequestId': 'ret-1',
        'trackingNumber': 'SM-R-00000042',
        'state': 2,
        'stage': 'AwaitingBuyerConfirmation',
        'mode': 'Rider',
        'packageId': 'pkg-1',
        'requestedUtc': '2026-10-28T08:00:00Z',
        'requestExpiresUtc': '2026-10-28T08:15:00Z',
        'rider': {
          'displayName': 'Ramesh K.',
          'rating': 4.8,
          'vehicle': 'Bike',
        },
        'attempts': {'failed': 1, 'max': 3, 'lastFailureCode': 'BuyerUnreachable'},
        'collectionPhotoUrls': ['https://cdn/a.jpg'],
        'fare': {
          'payer': 'Buyer',
          'amount': {'amount': 150, 'currency': 'NPR'},
          'upTo': {'amount': 185, 'currency': 'NPR'},
          'isFinal': false,
        },
        'canCancel': true,
        'canRetry': false,
      });

      expect(pickup.stage, ReturnPickupStage.awaitingBuyerConfirmation);
      expect(pickup.isRider, isTrue);
      expect(pickup.rider?.displayName, 'Ramesh K.');
      expect(pickup.rider?.rating, 4.8);
      expect(pickup.failedAttempts, 1);
      expect(pickup.lastFailureCode, 'BuyerUnreachable');
      expect(pickup.collectionPhotoUrls, ['https://cdn/a.jpg']);
      expect(pickup.fare?.payer, ReturnFarePayer.buyer);
      expect(pickup.fare?.amount?.amount, 150);
      expect(pickup.fare?.upTo?.amount, 185);
      expect(pickup.canCancel, isTrue);
      expect(pickup.blocksSellerCompletion, isTrue);
    });

    test('an old payload without any new field parses as before', () {
      final pickup = ReturnPickup.fromJson({
        'id': 'p-1',
        'returnRequestId': 'ret-1',
        'trackingNumber': 'SM-R-00000077',
        'state': 3,
        'originAddressLine': 'Buyer home',
        'destinationAddressLine': 'Shop',
        'requestedUtc': '2026-09-17T10:00:00Z',
      });

      expect(pickup.status, ReturnPickupStatus.pickedUp);
      expect(pickup.stage, isNull);
      expect(pickup.mode, ReturnPickupMode.unknown);
      expect(pickup.rider, isNull);
      expect(pickup.fare, isNull);
      expect(pickup.canCancel, isFalse);
      expect(pickup.canRetry, isFalse);
      expect(pickup.blocksSellerCompletion, isFalse);
    });

    test('unknown strings fall back safely', () {
      final pickup = ReturnPickup.fromJson({
        'stage': 'TeleportedHome',
        'mode': 'Drone',
        'fare': {'payer': 'Someone'},
      });
      expect(pickup.stage, ReturnPickupStage.unknown);
      expect(pickup.mode, ReturnPickupMode.unknown);
      expect(pickup.fare?.payer, ReturnFarePayer.unknown);
      expect(pickup.blocksSellerCompletion, isFalse);
    });
  });

  group('CustomerReturnDto (return pickup fields)', () {
    test('category, payer, stage and the refund breakdown', () {
      final r = CustomerReturnDto.fromJson({
        'id': 'ret-1',
        'submittedUtc': '2026-10-28T08:00:00Z',
        'state': 2,
        'reasonCategory': 'ChangedMind',
        'pickupFarePayer': 'Buyer',
        'pickupStage': 'Collected',
        'refundBreakdown': {
          'itemTotal': {'amount': 2500, 'currency': 'NPR'},
          'pickupFareDeducted': {'amount': 150, 'currency': 'NPR'},
          'refundAmount': {'amount': 2350, 'currency': 'NPR'},
        },
      }).toDomain();

      expect(r.reasonCategory, ReturnReasonCategory.changedMind);
      expect(r.pickupFarePayer, ReturnFarePayer.buyer);
      expect(r.pickupStage, ReturnPickupStage.collected);
      expect(r.refundBreakdown?.refundAmount.amount, 2350);
      expect(r.refundBreakdown?.pickupFareDeducted.amount, 150);
    });

    test('Cancelled (5) is its own state', () {
      final r = CustomerReturnDto.fromJson({
        'id': 'ret-1',
        'submittedUtc': '2026-10-28T08:00:00Z',
        'state': 5,
      }).toDomain();
      expect(r.status, ReturnRequestStatus.cancelled);
    });

    test('an old return has none of them', () {
      final r = CustomerReturnDto.fromJson({
        'id': 'ret-1',
        'submittedUtc': '2026-10-28T08:00:00Z',
        'state': 2,
        'reason': 'Too small',
      }).toDomain();
      expect(r.reasonCategory, isNull);
      expect(r.pickupFarePayer, ReturnFarePayer.unknown);
      expect(r.pickupStage, isNull);
      expect(r.refundBreakdown, isNull);
    });
  });

  test('categories: wire names, the buyer-pays rule, unknown values', () {
    expect(ReturnReasonCategory.choices.map((c) => c.wire), [
      'Damaged',
      'WrongItem',
      'Defective',
      'NotAsDescribed',
      'ChangedMind',
    ]);
    expect(
      ReturnReasonCategory.choices.where((c) => c.buyerPaysPickup),
      [ReturnReasonCategory.changedMind],
    );
    expect(ReturnReasonCategory.fromWire('Lost'), ReturnReasonCategory.unspecified);
    expect(ReturnReasonCategory.fromWire(null), isNull);
  });

  test('pickup quote', () {
    final quote = ReturnPickupQuote.fromJson({
      'estimate': {'amount': 150, 'currency': 'NPR'},
      'upTo': {'amount': 185, 'currency': 'NPR'},
      'itemTotal': {'amount': 2500, 'currency': 'NPR'},
      'refundIfChangedMind': {'amount': 2315, 'currency': 'NPR'},
      'method': 'road',
      'distanceKm': 7.4,
    });
    expect(quote.estimate.amount, 150);
    expect(quote.upTo.amount, 185);
    expect(quote.refundIfChangedMind?.amount, 2315);
    expect(quote.distanceKm, 7.4);
  });

  test('confirm response carries the purpose and the return', () {
    final confirmation =
        DeliveryConfirmationRepositoryImpl.confirmationFromJson({
          'orderId': 'o',
          'subOrderId': 's',
          'packageNumber': 'SM-R-00000042',
          'status': 'Collected',
          'purpose': 'ReturnPickup',
          'returnRequestId': 'ret-1',
        });
    expect(confirmation.purpose, 'ReturnPickup');
    expect(confirmation.returnRequestId, 'ret-1');
    expect(confirmation.status, 'Collected');
  });
}
