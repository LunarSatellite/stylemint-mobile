import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_delivery_json.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/domain/entities/rider_rating.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/delivery_request.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/rider_profile_for_vendor.dart';

/// The rider-rating contract's payloads, read tolerantly: the backend ships
/// after the app, so every missing field must leave the screens a null to
/// hide on rather than an exception.
void main() {
  group('RiderRatingTag', () {
    test('reads the contract strings, any case, and words them', () {
      expect(RiderRatingTag.fromWire('OnTime'), RiderRatingTag.onTime);
      expect(RiderRatingTag.fromWire('on_time'), RiderRatingTag.onTime);
      expect(
        RiderRatingTag.fromWire('WrongLocation')?.label,
        'Went to the wrong place',
      );
      expect(RiderRatingTag.fromWire('Teleported'), isNull);
      expect(RiderRatingTag.fromWire(null), isNull);
    });

    test('a list drops unknown and repeated tags', () {
      expect(
        RiderRatingTag.listFrom(['Friendly', 'Nope', 'friendly', 'Late']),
        [RiderRatingTag.friendly, RiderRatingTag.late],
      );
      expect(RiderRatingTag.listFrom('Friendly'), isEmpty);
    });

    test('4–5 stars offer praise, 1–3 offer problems', () {
      expect(RiderRatingTag.forStars(5).every((t) => t.positive), isTrue);
      expect(RiderRatingTag.forStars(4), hasLength(5));
      expect(RiderRatingTag.forStars(3).every((t) => !t.positive), isTrue);
      expect(
        RiderRatingTag.forStars(1).map((t) => t.label),
        contains('Parcel damaged'),
      );
    });
  });

  group('RiderRating', () {
    test('a full RiderRatingDto', () {
      final rating = RiderRating.fromJson({
        'subOrderId': 'sub-1',
        'courierId': 'c-1',
        'riderName': 'Ramesh K.',
        'raterRole': 'Buyer',
        'stars': 5,
        'tags': ['OnTime', 'Friendly'],
        'comment': 'Quick and polite',
        'createdUtc': '2026-10-08T10:00:00Z',
        'updatedUtc': '2026-10-08T10:05:00Z',
        'editableUntilUtc': '2026-10-15T10:00:00Z',
      })!;
      expect(rating.stars, 5);
      expect(rating.raterRole, RiderRaterRole.buyer);
      expect(rating.tags, [RiderRatingTag.onTime, RiderRatingTag.friendly]);
      expect(rating.comment, 'Quick and polite');
      expect(rating.isEditableAt(DateTime.utc(2026, 10, 14)), isTrue);
      expect(rating.isEditableAt(DateTime.utc(2026, 10, 16)), isFalse);
    });

    test('missing fields are null; no valid stars is no rating', () {
      final bare = RiderRating.fromJson({'stars': '3'})!;
      expect(bare.stars, 3);
      expect(bare.tags, isEmpty);
      expect(bare.comment, isNull);
      expect(bare.editableUntilUtc, isNull);
      expect(bare.isEditableAt(DateTime.now().toUtc()), isTrue);

      expect(RiderRating.fromJson({'stars': 0}), isNull);
      expect(RiderRating.fromJson({'stars': 6}), isNull);
      expect(RiderRating.fromJson({}), isNull);
      expect(RiderRating.fromJson('nope'), isNull);
    });
  });

  group('RiderRatingEligibility', () {
    test('a backend without ratings is null, so nothing is drawn', () {
      expect(
        RiderRatingEligibility.fromJson({'packageNumber': 'SM-D-1'}),
        isNull,
      );
      expect(RiderRatingEligibility.fromJson(null), isNull);
    });

    test('can rate, not yet rated', () {
      final e = RiderRatingEligibility.fromJson({
        'courierId': 'c-1',
        'canRateRider': true,
        'riderRating': null,
      })!;
      expect(e.canRateRider, isTrue);
      expect(e.rating, isNull);
      expect(e.isShown, isTrue);
    });

    test('rated, window closed: still shown, read-only', () {
      final e = RiderRatingEligibility.fromJson({
        'canRateRider': false,
        'riderRating': {
          'stars': 2,
          'tags': ['Late'],
        },
      })!;
      expect(e.canRateRider, isFalse);
      expect(e.rating?.stars, 2);
      expect(e.rating?.tags, [RiderRatingTag.late]);
      expect(e.isShown, isTrue);
    });

    test('not eligible and nothing given is not shown', () {
      expect(
        RiderRatingEligibility.fromJson({'canRateRider': false})?.isShown,
        isFalse,
      );
    });
  });

  group('RiderRatingSummary / CourierRatingOverview', () {
    test("the rider's own summary, with recent reviews", () {
      final overview = CourierRatingOverview.fromJson({
        'average': 4.7,
        'count': 23,
        'breakdown': {'5': 18, '4': 3, '3': 1, '2': 1, '1': 0},
        'topTags': [
          {'tag': 'OnTime', 'count': 12},
          {'tag': 'Unknown', 'count': 4},
        ],
        'recent': [
          {
            'stars': 5,
            'tags': ['Friendly'],
            'comment': null,
            'raterRole': 'Buyer',
            'ageDays': 2,
          },
        ],
      })!;
      expect(overview.summary.average, 4.7);
      expect(overview.summary.count, 23);
      expect(overview.summary.breakdown[5], 18);
      expect(overview.summary.largestBucket, 18);
      expect(overview.summary.topTags.single.tag, RiderRatingTag.onTime);
      expect(overview.recent.single.ageLabel, '2 days ago');
      expect(overview.recent.single.raterRole, RiderRaterRole.buyer);
    });

    test('under three ratings the average is null: "New rider"', () {
      final summary = RiderRatingSummary.fromJson({
        'average': null,
        'count': 2,
      })!;
      expect(summary.isNew, isTrue);
      expect(summary.breakdown, isEmpty);
      expect(summary.topTags, isEmpty);
    });

    test('age labels', () {
      expect(const RiderReview(stars: 4, ageDays: 0).ageLabel, 'Today');
      expect(const RiderReview(stars: 4, ageDays: 1).ageLabel, 'Yesterday');
      expect(const RiderReview(stars: 4, ageDays: 3).ageLabel, '3 days ago');
      expect(const RiderReview(stars: 4).ageLabel, isNull);
    });
  });

  group('InterestedRider (partner list)', () {
    test('ratingCount and verified are read', () {
      final rider = InterestedRider.fromJson({
        'offerId': 'o-1',
        'courierId': 'c-1',
        'displayName': 'Ramesh K.',
        'rating': 4.7,
        'ratingCount': 23,
        'verified': true,
        'completedDeliveries': 57,
        'distanceKm': 1.4,
        'vehicle': 'Scooter',
      });
      expect(rider.rating, 4.7);
      expect(rider.ratingCount, 23);
      expect(rider.verified, isTrue);
      expect(rider.isNew, isFalse);
      expect(rider.vehicle, 'Scooter');
    });

    test('an old backend: no count, no tick, no rating is "new"', () {
      final rider = InterestedRider.fromJson({
        'offerId': 'o-1',
        'rating': null,
      });
      expect(rider.rating, isNull);
      expect(rider.isNew, isTrue);
      expect(rider.ratingCount, isNull);
      expect(rider.verified, isNull);
      expect(InterestedRider.fromJson({'offerId': 'o', 'rating': 0}).isNew, isTrue);
    });
  });

  group('RiderProfileForVendor', () {
    test('the full details payload', () {
      final profile = RiderProfileForVendor.fromJson({
        'courierId': 'c-1',
        'offerId': 'o-1',
        'displayName': 'Ramesh K.',
        'avatarUrl': null,
        'verified': true,
        'memberSinceUtc': '2025-03-02T00:00:00Z',
        'tier': 'Pro',
        'vehicle': {'type': 'OnFoot', 'plateLast4': null},
        'homeArea': 'Lalitpur',
        'distanceKm': 1.4,
        'rating': {
          'average': 4.7,
          'count': 23,
          'breakdown': {'5': 18, '4': 3, '3': 1, '2': 1, '1': 0},
          'topTags': [
            {'tag': 'OnTime', 'count': 12},
          ],
        },
        'completedDeliveries': 57,
        'onTimeRate': 0.94,
        'cancellationRate': 0.02,
        'recentReviews': [
          for (var i = 0; i < 7; i++)
            {
              'stars': 5,
              'tags': ['CarefulWithParcel'],
              'comment': 'Great',
              'ageDays': i,
            },
        ],
        'state': 'Interested',
      });
      expect(profile.verified, isTrue);
      expect(profile.tier, 'Pro');
      expect(profile.vehicle, 'On foot');
      expect(profile.plateLast4, isNull);
      expect(profile.homeArea, 'Lalitpur');
      expect(profile.rating?.average, 4.7);
      expect(profile.onTimeRate, 0.94);
      expect(profile.recentReviews, hasLength(5), reason: 'capped at five');
      expect(profile.state, RiderOfferState.interested);
      expect(profile.isFallback, isFalse);
    });

    test('a bare payload leaves everything optional null', () {
      final profile = RiderProfileForVendor.fromJson({'courierId': 'c-1'});
      expect(profile.displayName, 'StyleMint rider');
      expect(profile.rating, isNull);
      expect(profile.completedDeliveries, isNull);
      expect(profile.onTimeRate, isNull);
      expect(profile.recentReviews, isEmpty);
      expect(profile.state, isNull);
    });

    test('withdrawn and not-selected riders are gone', () {
      expect(RiderOfferState.fromWire('Withdrawn')?.isGone, isTrue);
      expect(RiderOfferState.fromWire('NotSelected')?.isGone, isTrue);
      expect(RiderOfferState.fromWire('Assigned')?.isGone, isFalse);
    });
  });

  group('order payloads', () {
    test("buyer delivery block carries the rider's rating fields", () {
      final delivery = OrderDeliveryJson.fromOrder({
        'subOrders': [
          {
            'id': 'sub-1',
            'delivery': {
              'packageNumber': 'SM-D-1',
              'status': 'Delivered',
              'riderName': 'Ramesh',
              'courierId': 'c-1',
              'canRateRider': true,
              'riderRating': null,
            },
          },
        ],
      })!;
      expect(delivery.subOrderId, 'sub-1');
      expect(delivery.riderRating?.canRateRider, isTrue);
      expect(delivery.riderRating?.courierId, 'c-1');
      // And survives the buyer's own confirmation overlay.
      expect(delivery.asConfirmed().riderRating?.canRateRider, isTrue);
    });

    test('buyer delivery block without them has no rating', () {
      final delivery = OrderDeliveryJson.parse({
        'packageNumber': 'SM-D-1',
        'status': 'Delivered',
      });
      expect(delivery?.riderRating, isNull);
    });

    test('vendor sub-order detail: top level, nested, or absent', () {
      VendorOrderDetailDto dto(Map<String, dynamic> extra) =>
          VendorOrderDetailDto.fromJson({'id': 'sub-1', 'state': 9, ...extra});

      expect(
        dto({
          'canRateRider': true,
          'courierId': 'c-1',
        }).toDomain().riderRating?.canRateRider,
        isTrue,
      );
      expect(
        dto({
          'delivery': {
            'canRateRider': false,
            'riderRating': {'stars': 4, 'tags': <String>[]},
          },
        }).toDomain().riderRating?.rating?.stars,
        4,
      );
      expect(dto({}).toDomain().riderRating, isNull);
    });
  });
}
