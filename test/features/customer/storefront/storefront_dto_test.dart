import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/data/models/public_brand_profile_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/domain/country_names.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/presentation/brand_story.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/data/models/storefront_collection_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/data/models/storefront_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/data/models/storefront_reel_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_collection.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_reel.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/data/models/creator_reel_stats_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/data/models/creator_shop_product_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/data/models/public_creator_profile_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/public_creator_profile.dart';

import 'storefront_test_support.dart';

void main() {
  group('PublicCreatorProfileDto', () {
    test('parses the contract fixture', () {
      final profile = PublicCreatorProfileDto.fromJson(
        creatorProfileJson(),
      ).toDomain(creatorId);

      expect(profile.accountId, creatorId);
      expect(profile.displayName, 'Sarah K');
      expect(profile.firstName, 'Sarah');
      expect(profile.handle, 'sarah_creates');
      expect(profile.coverImageUrl, 'https://cdn.stylemint.example/c.webp');
      expect(profile.location, 'Kathmandu, NP');
      expect(profile.styleTags, ['streetwear', 'thrift']);
      expect(profile.isVerified, isTrue);
      expect(profile.specializationSummary, 'Streetwear stylist');
      expect(
        profile.socialLinks.map((l) => (l.platform, l.url.toString())),
        [
          (
            CreatorSocialPlatform.instagram,
            'https://www.instagram.com/sarah.ig',
          ),
          (CreatorSocialPlatform.tiktok, 'https://www.tiktok.com/@sarah.tt'),
        ],
      );
    });

    test('missing optional fields read as absent', () {
      final profile = PublicCreatorProfileDto.fromJson(const {
        'displayName': '',
        'handle': '@aarav',
        'bio': null,
        'styleTags': null,
      }).toDomain(creatorId);

      expect(profile.accountId, creatorId);
      expect(profile.displayName, 'aarav');
      expect(profile.handle, 'aarav');
      expect(profile.avatarUrl, isNull);
      expect(profile.coverImageUrl, isNull);
      expect(profile.bio, isNull);
      expect(profile.location, isNull);
      expect(profile.styleTags, isEmpty);
      expect(profile.isVerified, isFalse);
      expect(profile.socialLinks, isEmpty);
    });

    test('style tags are de-duplicated ignoring case', () {
      final profile = PublicCreatorProfileDto.fromJson(const {
        'displayName': 'Sarah',
        'styleTags': ['Minimal', 'minimal', ' ', 'Y2K'],
      }).toDomain(creatorId);
      expect(profile.styleTags, ['Minimal', 'Y2K']);
    });

    test('social links accept only handles or https links on the platform', () {
      expect(
        CreatorSocialLink.from(
          CreatorSocialPlatform.youtube,
          'https://www.youtube.com/@sarah',
        )?.handle,
        'sarah',
      );
      expect(
        CreatorSocialLink.from(
          CreatorSocialPlatform.instagram,
          'https://evil.example/sarah',
        ),
        isNull,
      );
      expect(
        CreatorSocialLink.from(
          CreatorSocialPlatform.instagram,
          'http://instagram.com/sarah',
        ),
        isNull,
      );
      expect(
        CreatorSocialLink.from(CreatorSocialPlatform.facebook, 'bad handle!'),
        isNull,
      );
    });
  });

  group('CreatorReelStatsDto', () {
    test('parses the contract fixture', () {
      final stats = CreatorReelStatsDto.fromJson(reelStatsJson()).toDomain();
      expect(stats.publishedReelCount, 12);
      expect(stats.totalLikes, 348);
      expect(stats.totalViews, 91250);
    });

    test('missing totals are zero', () {
      final stats = CreatorReelStatsDto.fromJson(const {}).toDomain();
      expect(stats.publishedReelCount, 0);
      expect(stats.totalLikes, 0);
      expect(stats.totalViews, 0);
    });
  });

  group('CreatorShopProductDto', () {
    test('parses the contract fixture', () {
      final product = CreatorShopProductDto.fromJson(
        shopProductJson(),
      ).toDomain()!;
      expect(product.productId, '9c1e0000-0000-4000-8000-000000000020');
      expect(product.name, 'Hand-loomed dhaka scarf');
      expect(product.price.amount, 2450);
      expect(product.price.currency, 'NPR');
      expect(product.vendorAccountId, vendorId);
      expect(product.vendorDisplayName, 'Mint Goods');
      expect(product.reelCount, 3);
      expect(product.imageUrl, 'https://cdn.stylemint.example/scarf.jpg');
      expect(product.lastTaggedUtc, DateTime.utc(2026, 9, 15, 10, 12));
    });

    test('a product without a price is dropped', () {
      final json = shopProductJson()
        ..['priceAmount'] = null
        ..['priceCurrency'] = null;
      expect(CreatorShopProductDto.fromJson(json).toDomain(), isNull);
    });

    test('missing currency and image fall back', () {
      final json = shopProductJson()
        ..remove('priceCurrency')
        ..remove('primaryImageUrl')
        ..remove('lastTaggedUtc');
      final product = CreatorShopProductDto.fromJson(json).toDomain()!;
      expect(product.price.currency, 'NPR');
      expect(product.imageUrl, isNull);
      expect(product.lastTaggedUtc, isNull);
    });
  });

  group('StorefrontReelDto', () {
    test('parses a ReelDto and detects the AI disclosure', () {
      final reel = StorefrontReelDto.fromJson(reelJson()).toDomain()!;
      expect(reel.id, 'a41c0000-0000-4000-8000-000000000010');
      expect(reel.creatorAccountId, creatorId);
      expect(reel.creatorName, 'Sarah K');
      expect(reel.posterUrl, 'https://cdn.stylemint.example/t.jpg');
      expect(reel.likeCount, 12);
      expect(reel.viewCount, 900);
      expect(reel.taggedProductCount, 1);
      expect(reel.isSavedByMe, isNull);
      expect(reel.isAiGenerated, isTrue);
      expect(reel.hook, 'Monsoon layers');
    });

    test('likeCount falls back to its parts; missing fields are safe', () {
      final reel = StorefrontReelDto.fromJson(const {
        'id': 'r-2',
        'likesSnapshot': 4,
        'styleMintLikeCount': 3,
        'isSavedByMe': true,
      }).toDomain()!;
      expect(reel.likeCount, 7);
      expect(reel.caption, isNull);
      expect(reel.posterUrl, isNull);
      expect(reel.taggedProductCount, 0);
      expect(reel.isSavedByMe, isTrue);
      expect(reel.isAiGenerated, isFalse);
      expect(reel.createdUtc, isNull);
    });

    test('a reel without an id is dropped', () {
      expect(StorefrontReelDto.fromJson(const {}).toDomain(), isNull);
    });

    test('AI disclosure matches the backend rule', () {
      expect(captionIsAiGenerated('Look #aigenerated'), isTrue);
      expect(captionIsAiGenerated('#AIgenerated, new drop'), isTrue);
      expect(captionIsAiGenerated('#AIgeneratedArt'), isFalse);
      expect(captionIsAiGenerated('AIgenerated'), isFalse);
      expect(captionIsAiGenerated(null), isFalse);
      expect(
        captionHook('#StyleMint\nhttps://x.example Fresh fits #ootd'),
        'Fresh fits',
      );
    });
  });

  group('StorefrontCollectionDto', () {
    test('parses a page of cards', () {
      final page = StorefrontPageDto.fromJson(
        pagedJson([
          collectionCardJson(),
          collectionCardJson(kind: 'BrandCollection')..['slug'] = 'brand-edit',
        ], nextCursor: 'abc'),
        StorefrontCollectionDto.fromJson,
      ).toDomain((dto) => dto.toDomain());

      expect(page.nextCursor, 'abc');
      expect(page.hasMore, isTrue);
      expect(page.totalCount, 2);
      final look = page.items.first;
      expect(look.slug, 'monsoon-look');
      expect(look.title, 'Monsoon look');
      expect(look.kind, CollectionKind.look);
      expect(look.isLook, isTrue);
      expect(look.itemCount, 6);
      expect(look.previewImageUrls, hasLength(2));
      expect(page.items.last.kind, CollectionKind.brandCollection);
    });

    test('cards without a slug are dropped; missing fields are safe', () {
      final page = StorefrontPageDto.fromJson(
        pagedJson([
          const {'title': 'No slug'},
          const {'slug': 'bare', 'title': 'Bare'},
        ]),
        StorefrontCollectionDto.fromJson,
      ).toDomain((dto) => dto.toDomain());

      expect(page.items, hasLength(1));
      final bare = page.items.single;
      expect(bare.id, 'bare');
      expect(bare.kind, CollectionKind.editorial);
      expect(bare.coverImageUrl, isNull);
      expect(bare.itemCount, 0);
      expect(bare.previewImageUrls, isEmpty);
    });

    test('a body without items reads as an empty last page', () {
      final page = StorefrontPageDto.fromJson(
        const {},
        StorefrontCollectionDto.fromJson,
      ).toDomain((dto) => dto.toDomain());
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });

  group('PublicBrandProfileDto', () {
    test('parses the contract fixture', () {
      final brand = PublicBrandProfileDto.fromJson(
        brandProfileJson(),
      ).toDomain(vendorId);

      expect(brand.accountId, vendorId);
      expect(brand.name, 'Mint Goods');
      expect(brand.tagline, 'Hand-made in the hills');
      expect(brand.isVerified, isTrue);
      expect(brand.origin, 'Pokhara, Nepal');
      expect(brand.originLine, 'Pokhara, Nepal · Since 1998');
      expect(brand.returnPolicySummary, '30-day free returns');
      expect(brand.supportUri, Uri.parse('https://help.mint.example'));
      expect(brand.story, startsWith('Since 1998'));
    });

    test('missing optional fields read as absent', () {
      final brand = PublicBrandProfileDto.fromJson(const {
        'businessName': 'Mint Goods',
        'foundedYear': 1700,
        'supportUrl': 'http://help.mint.example',
      }).toDomain(vendorId);

      expect(brand.accountId, vendorId);
      expect(brand.logoUrl, isNull);
      expect(brand.coverImageUrl, isNull);
      expect(brand.tagline, isNull);
      expect(brand.story, isNull);
      expect(brand.foundedYear, isNull);
      expect(brand.originLine, isNull);
      expect(brand.isVerified, isFalse);
      expect(brand.supportUri, isNull);
    });

    test('description stands in for a missing story', () {
      final brand = PublicBrandProfileDto.fromJson(const {
        'businessName': 'Mint Goods',
        'description': 'Hand-made goods.',
        'originCountryCode': 'np',
      }).toDomain(vendorId);
      expect(brand.story, 'Hand-made goods.');
      expect(brand.originCountryCode, 'NP');
      expect(brand.originLine, 'Nepal');
    });

    test('country names fall back to the code', () {
      expect(countryName('np'), 'Nepal');
      expect(countryName('ZZ'), 'ZZ');
      expect(countryName('Nepal'), isNull);
      expect(countryName(null), isNull);
    });
  });

  group('brand story', () {
    const story =
        'Since 1998 we have woven dhaka by hand. Every piece is made in '
        'Pokhara.';

    test('pull quote is the first sentence and the body the rest', () {
      expect(brandPullQuote(story), 'Since 1998 we have woven dhaka by hand.');
      expect(brandStoryBody(story), 'Every piece is made in Pokhara.');
      expect(brandStoryBody('One sentence only.'), isNull);
    });

    test('a long first sentence is shortened and the body keeps it all', () {
      final long = List.filled(40, 'woven').join(' ');
      final quote = brandPullQuote(long);
      expect(quote.length, lessThanOrEqualTo(brandPullQuoteMaxLength + 1));
      expect(quote, endsWith('…'));
      expect(brandStoryBody(long), long);
    });
  });
}
