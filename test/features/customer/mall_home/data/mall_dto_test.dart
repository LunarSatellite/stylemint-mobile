import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/models/catalog_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/models/home_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';

import '../mall_test_support.dart';

void main() {
  group('GET api/v1/public/home', () {
    test('parses every section kind in server order', () {
      final home = HomeResponseDto.fromJson(
        loadMallFixture('home_full.json'),
      ).toDomain();

      expect(home.personalized, isTrue);
      expect(home.greetingFirstName, 'Sumendra');
      expect(home.generatedUtc, DateTime.utc(2026, 9, 15, 12));
      expect(home.sections.map((s) => s.id), [
        'hero',
        'picked-for-you',
        'shoppable-reels',
        'deals',
        'categories',
        'brands',
        'creators',
        'collections',
        'trust',
      ]);
      expect(home.sections.map((s) => s.runtimeType), [
        HomeCampaignsSection,
        HomeProductsSection,
        HomeReelsSection,
        HomeProductsSection,
        HomeCategoriesSection,
        HomeBrandsSection,
        HomeCreatorsSection,
        HomeCollectionsSection,
        HomeTrustSection,
      ]);
    });

    test('skips unknown kinds, malformed rails and malformed cards', () {
      final home = HomeResponseDto.fromJson(
        loadMallFixture('home_full.json'),
      ).toDomain();

      expect(home.sections.any((s) => s.id == 'live-now'), isFalse);
      expect(home.sections.any((s) => s.id == 'broken'), isFalse);
      final picked = home.sections[1] as HomeProductsSection;
      expect(picked.items.map((p) => p.id), ['5d0c', '7a21']);
    });

    test('maps campaign cards and CTA kinds sent as names or numbers', () {
      final home = HomeResponseDto.fromJson(
        loadMallFixture('home_full.json'),
      ).toDomain();
      final campaign =
          (home.sections.first as HomeCampaignsSection).items.single;

      expect(campaign.title, 'Dubai Evening Edit');
      expect(campaign.heroReelId, isNull);
      expect(
        campaign.heroImageUrl,
        'https://cdn.stylemint.app/campaigns/dubai.jpg',
      );
      expect(campaign.ctas.map((c) => c.targetKind), [
        HomeCtaTargetKind.collection,
        HomeCtaTargetKind.reels,
        HomeCtaTargetKind.url,
      ]);
      expect(campaign.ctas.first.targetValue, 'dubai-evening-edit');
    });

    test('maps product, reel, creator, brand and collection cards', () {
      final sections = HomeResponseDto.fromJson(
        loadMallFixture('home_full.json'),
      ).toDomain().sections;

      final picked = sections[1] as HomeProductsSection;
      final pen = picked.items.first;
      expect(pen.price, rs(250));
      expect(pen.compareAtPrice, rs(300));
      expect(pen.rating, 4.6);
      expect(pen.isNew, isTrue);
      expect(pen.saleEndsUtc, DateTime.utc(2026, 9, 20, 18, 15));
      final tote = picked.items.last;
      expect(tote.rating, isNull);
      expect(tote.compareAtPrice, isNull);
      expect(tote.isLowStock, isTrue);
      expect(picked.reason, 'Because you follow Stylemint Nepal');
      expect(picked.seeAll?.target, HomeSeeAllTarget.productList);
      expect(picked.seeAll?.params, {'sort': 'bestselling'});

      final reel = (sections[2] as HomeReelsSection).items.single;
      expect(reel.isAiGenerated, isTrue);
      expect(reel.hook, 'Write your secrets in style');
      expect(reel.taggedProductCount, 1);

      final deals = sections[3] as HomeProductsSection;
      expect(deals.seeAll?.params, {'onSale': 'true', 'pageSize': '20'});

      final category = (sections[4] as HomeCategoriesSection).items.single;
      expect(category.slug, 'fashion');

      final brand = (sections[5] as HomeBrandsSection).items.single;
      expect(brand.isVerified, isTrue);
      expect(brand.logoUrl, isNull);

      final creator = (sections[6] as HomeCreatorsSection).items.single;
      expect(creator.styleTags, ['Minimal']);
      expect(creator.followerCount, 120);
      expect(
        (sections[6] as HomeCreatorsSection).seeAll?.target,
        HomeSeeAllTarget.creators,
      );

      final collection = (sections[7] as HomeCollectionsSection).items.single;
      expect(collection.kind, CollectionKind.editorial);
      expect(collection.itemCount, 8);
      expect(collection.previewImageUrls, hasLength(1));
    });

    test('anonymous page with missing optional fields', () {
      final home = HomeResponseDto.fromJson(
        loadMallFixture('home_minimal.json'),
      ).toDomain();

      expect(home.personalized, isFalse);
      expect(home.greetingFirstName, isNull);
      expect(home.generatedUtc, isNull);
      expect(home.sections.map((s) => s.id), ['new-arrivals', 'trust']);
      final rail = home.sections.first as HomeProductsSection;
      expect(rail.title, isNull);
      expect(rail.eyebrow, isNull);
      expect(rail.seeAll, isNull);
      final tee = rail.items.single;
      expect(tee.brandName, isNull);
      expect(tee.imageUrl, isNull);
      expect(tee.rating, isNull);
      expect(tee.compareAtPrice, isNull);
      expect(tee.isNew, isFalse);
      expect(home.sections.last, isA<HomeTrustSection>());
    });

    test('a body without a sections list reads as an empty page', () {
      final home = HomeResponseDto.fromJson(const {
        'sections': 'oops',
      }).toDomain();
      expect(home.sections, isEmpty);
    });
  });

  group('Catalog product card', () {
    test('maps a page of ProductDto cards', () {
      final page = CatalogProductPageDto.fromJson(
        loadMallFixture('products_page.json'),
      ).toDomain();

      expect(page.items.map((p) => p.id), ['5d0c', '7a21']);
      expect(page.nextCursor, 'cC5iZXN0c2VsbGluZ3w5fDEyfDVkMGM');
      expect(page.totalCount, 134);

      final shirt = page.items.first;
      expect(shirt.price, rs(2499));
      expect(shirt.compareAtPrice, rs(2999));
      expect(shirt.imageUrl, 'https://cdn.stylemint.app/p/cover.jpg');
      expect(shirt.rating, 4.5);
      expect(shirt.vendorDisplayName, 'Mint Goods');
      expect(shirt.isLowStock, isTrue, reason: '4 units left in the sale');

      final tote = page.items.last;
      expect(tote.price, rs(1200), reason: 'the default variant');
      expect(tote.compareAtPrice, isNull);
      expect(tote.rating, isNull, reason: 'no reviews');
      expect(tote.isOutOfStock, isTrue);
      expect(tote.isLowStock, isFalse);
      expect(tote.imageUrl, 'https://cdn.stylemint.app/p/a.jpg');
    });

    test('no next cursor once the server says there is no more', () {
      final page = CatalogProductPageDto.fromJson(const {
        'items': <Object>[],
        'nextCursor': 'stale',
        'hasMore': false,
      }).toDomain();
      expect(page.nextCursor, isNull);
      expect(page.hasMore, isFalse);
    });
  });

  group('GET v1/public/collections/{slug}', () {
    test('maps a look with pinned pieces and a next page', () {
      final detail = CollectionDetailDto.fromJson(
        loadMallFixture('collection_look.json'),
      ).toDomain();

      expect(detail.kind, CollectionKind.look);
      expect(detail.isLook, isTrue);
      expect(detail.title, 'Monsoon look');
      expect(detail.ownerDisplayName, isNull);
      expect(detail.itemCount, 6);
      expect(detail.items.nextCursor, isNotNull);
      expect(detail.items.items.map((i) => i.product.id), [
        '5d0c',
        '7a21',
        'e9b0',
      ]);

      final shell = detail.items.items[0];
      expect(shell.hasPosition, isTrue);
      expect(shell.positionX, 0.3125);
      expect(shell.positionY, 0.75);
      expect(shell.note, 'The hero piece');
      expect(shell.product.price, rs(4999));

      expect(detail.items.items[1].hasPosition, isFalse, reason: 'x only');
      final umbrella = detail.items.items[2];
      expect((umbrella.positionX, umbrella.positionY), (1.0, 0.0));
    });
  });

  group('the option contract on a public product card', () {
    Map<String, dynamic> catalogCard(Map<String, Object?> extra) => {
      'id': '5d0c',
      'name': 'Linen shirt',
      'variants': [
        {'isDefault': true, 'priceAmount': 2499, 'priceCurrency': 'NPR'},
      ],
      ...extra,
    };

    Map<String, dynamic> homeCard(Map<String, Object?> extra) => {
      'id': 'h-1',
      'name': 'Linen shirt',
      'price': {'amount': 2499, 'currency': 'NPR'},
      ...extra,
    };

    test('a cleared card carries both fields through to the entity', () {
      final card = CatalogProductDto.fromJson(
        catalogCard({
          'requiresOptionSelection': false,
          'defaultVariantId': '0f8b2c1e-1111-4a2b-9c3d-4e5f60718293',
          'isInStock': true,
        }),
      ).toDomain()!;

      expect(card.requiresOptionSelection, isFalse);
      expect(card.defaultVariantId, '0f8b2c1e-1111-4a2b-9c3d-4e5f60718293');
      expect(card.isInStock, isTrue);

      final home = HomeProductCardDto.fromJson(
        homeCard({
          'requiresOptionSelection': false,
          'defaultVariantId': '0f8b2c1e-1111-4a2b-9c3d-4e5f60718293',
          'isInStock': true,
        }),
      ).toDomain()!;
      expect(home.requiresOptionSelection, isFalse);
      expect(home.defaultVariantId, '0f8b2c1e-1111-4a2b-9c3d-4e5f60718293');
      expect(home.isInStock, isTrue);
    });

    test('a card that needs a choice says so', () {
      final card = CatalogProductDto.fromJson(
        catalogCard({
          'requiresOptionSelection': true,
          'defaultVariantId': '0f8b2c1e-1111-4a2b-9c3d-4e5f60718293',
        }),
      ).toDomain()!;
      expect(card.requiresOptionSelection, isTrue);
      expect(
        card.defaultVariantId,
        isNotNull,
        reason: 'the server still names its pick; the client must not use it',
      );
    });

    test('the deployed server sends neither field: a choice is required', () {
      final card = CatalogProductDto.fromJson(catalogCard({})).toDomain()!;
      expect(card.requiresOptionSelection, isTrue);
      expect(card.defaultVariantId, isNull);
      expect(card.isInStock, isFalse);

      final home = HomeProductCardDto.fromJson(homeCard({})).toDomain()!;
      expect(home.requiresOptionSelection, isTrue);
      expect(home.defaultVariantId, isNull);
      expect(home.isInStock, isFalse);
    });

    test('anything but a plain false reads as requiring a choice', () {
      for (final wire in <Object?>[null, 'maybe', 0, 1, <String>[], {}]) {
        final card = CatalogProductDto.fromJson(
          catalogCard({'requiresOptionSelection': wire}),
        ).toDomain()!;
        expect(
          card.requiresOptionSelection,
          isTrue,
          reason: 'requiresOptionSelection: $wire must not clear the card',
        );
      }
    });

    test('a stringified boolean is still read', () {
      expect(
        CatalogProductDto.fromJson(
          catalogCard({
            'requiresOptionSelection': 'false',
            'defaultVariantId': 'v-1',
          }),
        ).toDomain()!.requiresOptionSelection,
        isFalse,
      );
      expect(
        CatalogProductDto.fromJson(
          catalogCard({'requiresOptionSelection': 'TRUE'}),
        ).toDomain()!.requiresOptionSelection,
        isTrue,
      );
    });

    test('a blank or all-zero default variant id is no variant at all', () {
      for (final wire in <Object?>[
        '',
        '   ',
        '00000000-0000-0000-0000-000000000000',
        42,
      ]) {
        final card = CatalogProductDto.fromJson(
          catalogCard({
            'requiresOptionSelection': false,
            'defaultVariantId': wire,
          }),
        ).toDomain()!;
        expect(card.defaultVariantId, isNull, reason: 'defaultVariantId $wire');
      }
    });

    test('a malformed card still renders: nothing here throws', () {
      expect(
        () => CatalogProductDto.fromJson(
          catalogCard({
            'requiresOptionSelection': {'nested': true},
            'defaultVariantId': {'nested': 'id'},
          }),
        ).toDomain(),
        returnsNormally,
      );
    });
  });
}
