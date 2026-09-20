import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_zones.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

const MallStrings _strings = MallStrings.english;

/// 13:00 UTC is 18:45 in Kathmandu.
final DateTime _now = DateTime.utc(2026, 9, 15, 13);

Money _rs(double amount) => Money(amount: amount, currency: 'NPR');

HomeProduct _product({
  String id = 'p',
  double price = 1500,
  Money? was,
  double? rating,
  int reviewCount = 0,
  DateTime? saleEndsUtc,
  bool isLowStock = false,
}) => HomeProduct(
  id: id,
  name: 'Product $id',
  price: _rs(price),
  compareAtPrice: was,
  rating: rating,
  reviewCount: reviewCount,
  saleEndsUtc: saleEndsUtc,
  isLowStock: isLowStock,
  isInStock: true,
);

HomeProductsSection _products(List<HomeProduct> items) =>
    HomeProductsSection(id: 's', title: 'Block', items: items);

void main() {
  group('discountPercentOf', () {
    test('floors, so a discount is never overstated', () {
      expect(discountPercentOf(_product(price: 3499, was: _rs(4999))), 30);
      expect(discountPercentOf(_product(price: 66.67, was: _rs(100))), 33);
    });

    test('is null without a genuine saving in the same currency', () {
      expect(discountPercentOf(_product(price: 100)), isNull);
      expect(discountPercentOf(_product(price: 100, was: _rs(100))), isNull);
      expect(discountPercentOf(_product(price: 100, was: _rs(90))), isNull);
      expect(
        discountPercentOf(
          _product(
            price: 80,
            was: const Money(amount: 100, currency: 'USD'),
          ),
        ),
        isNull,
      );
    });

    test('is null when the saving rounds below one percent', () {
      expect(discountPercentOf(_product(price: 99.5, was: _rs(100))), isNull);
    });
  });

  group('isDropBlock', () {
    test('a real deadline is enough on its own', () {
      expect(isDropBlock([_product(saleEndsUtc: _now)]), isTrue);
    });

    test('so are two genuine discounts', () {
      expect(
        isDropBlock([
          _product(id: 'a', price: 100, was: _rs(200)),
          _product(id: 'b', price: 100, was: _rs(200)),
        ]),
        isTrue,
      );
    });

    test('one lonely discount, or none, stays a discovery rail', () {
      expect(
        isDropBlock([
          _product(id: 'a', price: 100, was: _rs(200)),
          _product(id: 'b'),
        ]),
        isFalse,
      );
      expect(isDropBlock([_product(), _product(id: 'b')]), isFalse);
      expect(isDropBlock(const []), isFalse);
    });
  });

  group('MallDealFacts', () {
    test('takes the best discount and the soonest deadline', () {
      final facts = MallDealFacts.from([
        _product(
          id: 'a',
          price: 150,
          was: _rs(200),
          saleEndsUtc: DateTime.utc(2026, 9, 20),
        ),
        _product(
          id: 'b',
          price: 100,
          was: _rs(200),
          saleEndsUtc: DateTime.utc(2026, 9, 17),
        ),
      ]);
      expect(facts.topDiscountPercent, 50);
      expect(facts.endsUtc, DateTime.utc(2026, 9, 17));
      expect(facts.isEmpty, isFalse);
    });

    test('claims nothing when the data carries nothing', () {
      final facts = MallDealFacts.from([_product()]);
      expect(facts.topDiscountPercent, isNull);
      expect(facts.endsUtc, isNull);
      expect(facts.isEmpty, isTrue);
    });
  });

  group('kathmanduDaysUntil', () {
    test('counts calendar days in Kathmandu, not UTC', () {
      // 19:00 UTC is 00:45 the next day in Kathmandu.
      expect(kathmanduDaysUntil(DateTime.utc(2026, 9, 15, 19), _now), 1);
      expect(kathmanduDaysUntil(DateTime.utc(2026, 9, 15, 17, 30), _now), 0);
      expect(kathmanduDaysUntil(DateTime.utc(2026, 9, 20, 10), _now), 5);
    });
  });

  group('zoneFor', () {
    test('maps every section kind onto a treatment', () {
      expect(
        zoneFor(
          const HomeCampaignsSection(
            id: 'hero',
            items: [HomeCampaign(id: 'c', title: 'T')],
          ),
        ),
        MallZone.cinematic,
      );
      expect(
        zoneFor(
          const HomeReelsSection(
            id: 'r',
            items: [HomeReel(id: 'r1', creatorName: 'A')],
          ),
        ),
        MallZone.cinematic,
      );
      expect(
        zoneFor(
          const HomeCollectionsSection(
            id: 'c',
            items: [HomeCollection(slug: 's', title: 'T')],
          ),
        ),
        MallZone.editorial,
      );
      expect(
        zoneFor(
          const HomeBrandsSection(
            id: 'b',
            items: [HomeBrand(vendorAccountId: 'v', name: 'B')],
          ),
        ),
        MallZone.editorial,
      );
      expect(
        zoneFor(
          const HomeCategoriesSection(
            id: 'cat',
            items: [HomeCategory(id: 'c', name: 'C')],
          ),
        ),
        MallZone.retail,
      );
      expect(
        zoneFor(
          const HomeCreatorsSection(
            id: 'cr',
            items: [HomeCreator(accountId: 'a', displayName: 'N')],
          ),
        ),
        MallZone.discovery,
      );
      expect(zoneFor(const HomeTrustSection(id: 't')), isNull);
    });

    test('a products block picks its own zone from its data', () {
      expect(zoneFor(_products([_product()])), MallZone.discovery);
      expect(
        zoneFor(_products([_product(saleEndsUtc: _now)])),
        MallZone.retail,
      );
    });
  });

  group('mallProductSignal', () {
    MallSignal? signal(HomeProduct product) =>
        mallProductSignal(product, now: _now, strings: _strings);

    test('a real deadline outranks everything else', () {
      final result = signal(
        _product(
          saleEndsUtc: DateTime.utc(2026, 9, 15, 17, 30),
          isLowStock: true,
          rating: 4.6,
          reviewCount: 12,
        ),
      );
      expect(result?.label, 'Ends today');
      expect(result?.tone, MallSignalTone.urgent);
    });

    test('reads the deadline in Kathmandu days', () {
      expect(
        signal(_product(saleEndsUtc: DateTime.utc(2026, 9, 15, 19)))?.label,
        'Ends tomorrow',
      );
      expect(
        signal(_product(saleEndsUtc: DateTime.utc(2026, 9, 20, 10)))?.label,
        'Ends in 5 days',
      );
    });

    test('a deadline past the horizon is not news, so it falls through', () {
      final result = signal(
        _product(
          saleEndsUtc: DateTime.utc(2026, 12),
          rating: 4.6,
          reviewCount: 12,
        ),
      );
      expect(result?.label, '12 reviews');
    });

    test('low stock never claims a count the API did not send', () {
      final result = signal(_product(isLowStock: true));
      expect(result?.label, 'Only a few left');
      expect(result?.tone, MallSignalTone.urgent);
      expect(result?.label, isNot(contains(RegExp(r'\d'))));
    });

    test('reviews need both a score and a count', () {
      expect(
        signal(_product(rating: 4.6, reviewCount: 12))?.label,
        '12 reviews',
      );
      expect(signal(_product(rating: 4.6))?.label, isNull);
      expect(signal(_product(reviewCount: 12))?.label, isNull);
    });

    test('says nothing when there is nothing to say', () {
      expect(signal(_product()), isNull);
    });
  });

  group('mallRailHasSignals', () {
    test('is true when any one card has something to say', () {
      expect(
        mallRailHasSignals(
          [_product(), _product(id: 'b', isLowStock: true)],
          now: _now,
          strings: _strings,
        ),
        isTrue,
      );
      expect(
        mallRailHasSignals(
          [_product(), _product(id: 'b')],
          now: _now,
          strings: _strings,
        ),
        isFalse,
      );
    });
  });

  group('mallSectionMeta', () {
    test('counts products and the best real discount', () {
      final meta = mallSectionMeta(
        _products([
          _product(id: 'a', price: 100, was: _rs(200)),
          _product(id: 'b'),
        ]),
        _strings,
      );
      expect(meta.map((s) => s.label), ['2 picks', 'Up to 50% off']);
    });

    test('omits the discount chip when nothing is discounted', () {
      final meta = mallSectionMeta(_products([_product()]), _strings);
      expect(meta.map((s) => s.label), ['1 pick']);
    });

    test('totals tagged products across a reel rail', () {
      final meta = mallSectionMeta(
        const HomeReelsSection(
          id: 'r',
          items: [
            HomeReel(id: '1', creatorName: 'A', taggedProductCount: 2),
            HomeReel(id: '2', creatorName: 'B', taggedProductCount: 3),
          ],
        ),
        _strings,
      );
      expect(meta.single.label, '5 products tagged');
    });

    test('counts only genuinely verified accounts', () {
      final meta = mallSectionMeta(
        const HomeCreatorsSection(
          id: 'cr',
          items: [
            HomeCreator(accountId: 'a', displayName: 'A', isVerified: true),
            HomeCreator(accountId: 'b', displayName: 'B'),
          ],
        ),
        _strings,
      );
      expect(meta.single.label, '1 verified');
    });

    test('totals collection pieces, and says nothing without counts', () {
      expect(
        mallSectionMeta(
          const HomeCollectionsSection(
            id: 'c',
            items: [
              HomeCollection(slug: 'a', title: 'A', itemCount: 8),
              HomeCollection(slug: 'b', title: 'B', itemCount: 4),
            ],
          ),
          _strings,
        ).single.label,
        '12 pieces',
      );
      expect(
        mallSectionMeta(
          const HomeCollectionsSection(
            id: 'c',
            items: [HomeCollection(slug: 'a', title: 'A')],
          ),
          _strings,
        ),
        isEmpty,
      );
    });

    test('a campaign stage and the trust strip claim nothing', () {
      expect(
        mallSectionMeta(
          const HomeCampaignsSection(
            id: 'hero',
            items: [HomeCampaign(id: 'c', title: 'T')],
          ),
          _strings,
        ),
        isEmpty,
      );
      expect(
        mallSectionMeta(const HomeTrustSection(id: 't'), _strings),
        isEmpty,
      );
    });
  });
}
