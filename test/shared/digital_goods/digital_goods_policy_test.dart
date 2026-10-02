import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/models/catalog_dto.dart';
import 'package:stylemint_mobile_frontend/shared/data/product_kind_json.dart';
import 'package:stylemint_mobile_frontend/shared/digital_goods/digital_goods_policy.dart';

void main() {
  group('DigitalGoodsPolicy.forPlatform', () {
    test('Android may not offer digital goods, and says which store', () {
      final policy = DigitalGoodsPolicy.forPlatform(TargetPlatform.android);

      expect(policy.canOfferDigitalGoods, isFalse);
      expect(policy.rule, StoreBillingRule.googlePlay);
    });

    test('iOS is the seam, still allowed today', () {
      // The App Store has the same rule and this app ships to TestFlight, so
      // this test is the one that changes when the owner switches iOS off.
      final policy = DigitalGoodsPolicy.forPlatform(TargetPlatform.iOS);

      expect(policy.canOfferDigitalGoods, isTrue);
    });

    test('non-store platforms are allowed', () {
      for (final platform in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        expect(
          DigitalGoodsPolicy.forPlatform(platform).canOfferDigitalGoods,
          isTrue,
          reason: '$platform',
        );
      }
    });
  });

  group('blocksPurchaseOf', () {
    const blocked = DigitalGoodsPolicy.blockedBy(StoreBillingRule.googlePlay);
    const allowed = DigitalGoodsPolicy.allowed();

    test('blocks Digital (2) and Subscription (4) only', () {
      expect(blocked.blocksPurchaseOf(ProductKinds.digital), isTrue);
      expect(blocked.blocksPurchaseOf(ProductKinds.subscription), isTrue);

      expect(blocked.blocksPurchaseOf(ProductKinds.physical), isFalse);
      expect(blocked.blocksPurchaseOf(ProductKinds.service), isFalse);
      expect(blocked.blocksPurchaseOf(ProductKinds.bundle), isFalse);
    });

    test('an unstated kind stays purchasable', () {
      // A server that sends no kind must not empty the catalogue, and "null"
      // must never be read as "physical" either — see isDigitalProductKind.
      expect(blocked.blocksPurchaseOf(null), isFalse);
      expect(isDigitalProductKind(null), isFalse);
    });

    test('a kind this build does not know stays purchasable', () {
      expect(blocked.blocksPurchaseOf(99), isFalse);
    });

    test('nothing is blocked while digital goods are allowed', () {
      for (final kind in [null, 1, 2, 3, 4, 5, 99]) {
        expect(allowed.blocksPurchaseOf(kind), isFalse, reason: '$kind');
      }
    });
  });

  group('readProductKind', () {
    test('reads the enum as a number or as its name', () {
      expect(readProductKind(2), ProductKinds.digital);
      expect(readProductKind(4.0), ProductKinds.subscription);
      expect(readProductKind('4'), ProductKinds.subscription);
      expect(readProductKind('Digital'), ProductKinds.digital);
      expect(readProductKind(' subscription '), ProductKinds.subscription);
    });

    test('returns null rather than guessing a kind', () {
      expect(readProductKind(null), isNull);
      expect(readProductKind(''), isNull);
      expect(readProductKind('Hologram'), isNull);
      expect(readProductKind(const {}), isNull);
    });
  });

  group('resolveProductKind', () {
    test('a product with any digital variant is digital', () {
      expect(
        resolveProductKind([ProductKinds.physical, ProductKinds.digital]),
        ProductKinds.digital,
      );
    });

    test('falls back to the first stated kind', () {
      expect(
        resolveProductKind([null, ProductKinds.service]),
        ProductKinds.service,
      );
    });

    test('null when no variant stated one', () {
      expect(resolveProductKind(const [null, null]), isNull);
      expect(resolveProductKind(const []), isNull);
    });
  });

  group('CatalogProductDto carries the kind off its variants', () {
    Map<String, dynamic> cardJson(Object? kind) => {
      'id': 'p1',
      'name': 'Lightroom preset pack',
      'variants': [
        {
          'isDefault': true,
          'priceAmount': 900,
          'priceCurrency': 'NPR',
          'quantityOnHand': 10,
          if (kind != null) 'productKind': kind,
        },
      ],
    };

    test('a digital card reports kind 2', () {
      final product = CatalogProductDto.fromJson(cardJson(2)).toDomain();

      expect(product!.productKind, ProductKinds.digital);
    });

    test('a card with no kind reports null, not physical', () {
      final product = CatalogProductDto.fromJson(cardJson(null)).toDomain();

      expect(product!.productKind, isNull);
    });

    test('the variant still parses when the kind is nonsense', () {
      final product = CatalogProductDto.fromJson(
        cardJson('not-a-kind'),
      ).toDomain();

      // The price came off the same variant, so a thrown kind would have
      // dropped the whole card.
      expect(product, isNotNull);
      expect(product!.productKind, isNull);
      expect(product.price.amount, 900);
    });
  });
}
