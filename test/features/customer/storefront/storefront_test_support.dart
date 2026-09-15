import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/domain/entities/public_brand_profile.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/domain/repositories/brand_storefront_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_catalog_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_collection.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_follow_summary.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_page.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/repositories/storefront_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/creator_reel_stats.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/creator_shop_product.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/public_creator_profile.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/repositories/creator_storefront_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

// ── Ids ─────────────────────────────────────────────────────────────────────

const String creatorId = '7c1e0000-0000-4000-8000-000000000001';
const String vendorId = '0d7a0000-0000-4000-8000-000000000002';
const String otherVendorId = '0d7a0000-0000-4000-8000-000000000003';

/// Lets queued futures (notifier loads) complete.
Future<void> flushMicrotasks() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

// ── Contract JSON (docs/mall/*.md) ──────────────────────────────────────────

Map<String, dynamic> creatorProfileJson() => {
  'accountId': creatorId,
  'displayName': 'Sarah K',
  'handle': 'sarah_creates',
  'avatarUrl': 'https://cdn.stylemint.example/a.png',
  'coverImageUrl': 'https://cdn.stylemint.example/c.webp',
  'bio': 'Thrift + streetwear',
  'location': 'Kathmandu, NP',
  'styleTags': ['streetwear', 'thrift'],
  'isVerified': true,
  'specializationSummary': 'Streetwear stylist',
  'socialHandles': {
    'instagram': 'sarah.ig',
    'tiktok': 'sarah.tt',
    'youtube': null,
    'facebook': null,
  },
};

Map<String, dynamic> reelStatsJson() => {
  'creatorAccountId': creatorId,
  'publishedReelCount': 12,
  'totalStyleMintLikes': 348,
  'totalViewsSnapshot': 91250,
};

Map<String, dynamic> reelJson({
  String id = 'a41c0000-0000-4000-8000-000000000010',
  String? caption = 'Monsoon layers\n#StyleMint #AIgenerated',
}) => {
  'id': id,
  'creatorAccountId': creatorId,
  'sourcePlatform': 1,
  'sourceUrl': 'https://www.instagram.com/reel/abc',
  'externalId': 'abc',
  'durationSeconds': 14,
  'caption': caption,
  'thumbnailCdnUrl': 'https://cdn.stylemint.example/t.jpg',
  'state': 3,
  'viewsSnapshot': 900,
  'likesSnapshot': 10,
  'styleMintLikeCount': 2,
  'likeCount': 12,
  'saveCount': 18,
  'shareCount': 42,
  'isLikedByMe': null,
  'isSavedByMe': null,
  'createdUtc': '2026-09-15T10:12:00+00:00',
  'creatorDisplayName': 'Sarah K',
  'creatorAvatarUrl': null,
  'taggedProducts': [
    {
      'id': 't-1',
      'productId': '9c1e0000-0000-4000-8000-000000000020',
      'appearAtSeconds': 2.5,
      'disappearAtSeconds': null,
    },
  ],
};

Map<String, dynamic> shopProductJson() => {
  'productId': '9c1e0000-0000-4000-8000-000000000020',
  'name': 'Hand-loomed dhaka scarf',
  'primaryImageUrl': 'https://cdn.stylemint.example/scarf.jpg',
  'priceAmount': 2450.00,
  'priceCurrency': 'NPR',
  'vendorAccountId': vendorId,
  'vendorDisplayName': 'Mint Goods',
  'reelCount': 3,
  'lastTaggedUtc': '2026-09-15T10:12:00+00:00',
};

Map<String, dynamic> collectionCardJson({Object kind = 4}) => {
  'id': '0b6e0000-0000-4000-8000-000000000030',
  'slug': 'monsoon-look',
  'title': 'Monsoon look',
  'subtitle': 'Rain-ready layers',
  'coverImageUrl': 'https://cdn.stylemint.app/c/monsoon.jpg',
  'kind': kind,
  'owner': {
    'kind': 2,
    'accountId': creatorId,
    'displayName': null,
    'avatarUrl': null,
  },
  'itemCount': 6,
  'previewImageUrls': [
    'https://cdn.stylemint.app/p/1.jpg',
    'https://cdn.stylemint.app/p/2.jpg',
  ],
  'startsUtc': null,
  'endsUtc': null,
};

Map<String, dynamic> pagedJson(
  List<Map<String, dynamic>> items, {
  String? nextCursor,
}) => {
  'items': items,
  'totalCount': items.length,
  'nextCursor': nextCursor,
  'previousCursor': null,
  'pageSize': 12,
  'hasMore': nextCursor != null,
};

Map<String, dynamic> brandProfileJson() => {
  'id': '1111',
  'accountId': vendorId,
  'businessName': 'Mint Goods',
  'businessType': 3,
  'logoUrl': 'https://cdn.stylemint.example/logo.png',
  'coverImageUrl': 'https://cdn.stylemint.example/cover.webp',
  'description': 'Hand-made goods.',
  'websiteUrl': 'https://mint.example',
  'tagline': 'Hand-made in the hills',
  'brandStory':
      'Since 1998 we have woven dhaka by hand. Every piece is made '
      'in Pokhara.',
  'originCity': 'Pokhara',
  'originCountryCode': 'NP',
  'foundedYear': 1998,
  'isVerified': true,
  'verifiedUtc': '2026-09-15T08:00:00+00:00',
  'returnPolicySummary': '30-day free returns',
  'supportUrl': 'https://help.mint.example',
  'status': 3,
  'approvalUtc': '2026-09-01T00:00:00+00:00',
  'commissionRangeMin': null,
  'commissionRangeMax': null,
};

// ── Entities for widget tests (no image URLs, so nothing hits the network) ──

const PublicCreatorProfile sampleCreator = PublicCreatorProfile(
  accountId: creatorId,
  displayName: 'Sarah K',
  handle: 'sarah_creates',
  bio: 'Thrift + streetwear from the lanes of Thamel.',
  location: 'Kathmandu, NP',
  styleTags: ['streetwear', 'thrift', 'Y2K revival'],
  isVerified: true,
  specializationSummary: 'Streetwear stylist',
);

const CreatorReelStats sampleStats = CreatorReelStats(
  publishedReelCount: 12,
  totalLikes: 348,
  totalViews: 91250,
);

const StorefrontReel aiReel = StorefrontReel(
  id: 'reel-ai',
  creatorAccountId: creatorId,
  creatorName: 'Sarah K',
  caption: 'Weekend thrift haul\n#StyleMint #AIgenerated',
  likeCount: 1200,
  taggedProductCount: 2,
);

const StorefrontReel humanReel = StorefrontReel(
  id: 'reel-human',
  creatorAccountId: creatorId,
  creatorName: 'Sarah K',
  caption: 'Rainy day layers #StyleMint',
  likeCount: 5,
);

CreatorShopProduct shopProduct(
  String id, {
  String vendor = vendorId,
  String vendorName = 'Mint Goods',
  int reelCount = 1,
  double price = 2450,
}) => CreatorShopProduct(
  productId: id,
  name: 'Piece $id',
  price: Money(amount: price, currency: 'NPR'),
  vendorAccountId: vendor,
  vendorDisplayName: vendorName,
  reelCount: reelCount,
);

StorefrontCollection sampleCollection(
  String slug, {
  CollectionKind kind = CollectionKind.creatorCollection,
}) => StorefrontCollection(
  id: slug,
  slug: slug,
  title: 'Edit $slug',
  kind: kind,
  itemCount: 6,
);

const PublicBrandProfile sampleBrand = PublicBrandProfile(
  accountId: vendorId,
  name: 'Mint Goods',
  tagline: 'Hand-made in the hills',
  brandStory:
      'Since 1998 we have woven dhaka by hand. Every piece is made in '
      'Pokhara by the same families.',
  originCity: 'Kathmandu',
  originCountryCode: 'NP',
  foundedYear: 2019,
  isVerified: true,
  returnPolicySummary: '30-day free returns on unworn pieces',
  supportUrl: 'https://help.mint.example/contact',
);

CatalogProduct catalogProduct(String id, {double price = 1800}) =>
    CatalogProduct(
      id: id,
      name: 'Product $id',
      price: Money(amount: price, currency: 'NPR'),
      vendorAccountId: vendorId,
      vendorDisplayName: 'Mint Goods',
    );

StorefrontPage<T> page<T>(List<T> items, {String? next}) =>
    StorefrontPage<T>(items: items, nextCursor: next, totalCount: items.length);

// ── Fakes ───────────────────────────────────────────────────────────────────

class FakeCreatorStorefrontRepository implements CreatorStorefrontRepository {
  Either<NetworkExceptions, PublicCreatorProfile> profile = right(
    sampleCreator,
  );
  Either<NetworkExceptions, CreatorReelStats> stats = right(sampleStats);
  Either<NetworkExceptions, StorefrontPage<CreatorShopProduct>> shop = right(
    page(const []),
  );
  final List<String> calls = [];

  @override
  Future<Either<NetworkExceptions, PublicCreatorProfile>> getProfile(
    String accountId,
  ) async {
    calls.add('profile $accountId');
    return profile;
  }

  @override
  Future<Either<NetworkExceptions, CreatorReelStats>> getReelStats(
    String accountId,
  ) async {
    calls.add('stats $accountId');
    return stats;
  }

  @override
  Future<Either<NetworkExceptions, StorefrontPage<CreatorShopProduct>>> getShop(
    String accountId, {
    String? cursor,
    int pageSize = 24,
  }) async {
    calls.add('shop $accountId');
    return shop;
  }
}

class FakeStorefrontRepository implements StorefrontRepository {
  final Map<
    CreatorReelSort,
    Either<NetworkExceptions, StorefrontPage<StorefrontReel>>
  >
  creatorReels = {};
  Either<NetworkExceptions, StorefrontPage<StorefrontReel>> vendorReels = right(
    page(const []),
  );
  final Map<
    CollectionKind,
    Either<NetworkExceptions, StorefrontPage<StorefrontCollection>>
  >
  collections = {};
  Either<NetworkExceptions, StorefrontFollowSummary> follow = right(
    const StorefrontFollowSummary(followers: 1200, isFollowedByViewer: false),
  );
  final List<String> calls = [];

  @override
  Future<Either<NetworkExceptions, StorefrontPage<StorefrontReel>>>
  getCreatorReels(
    String creatorAccountId, {
    required CreatorReelSort sort,
    String? cursor,
    int pageSize = 12,
  }) async {
    calls.add('creatorReels ${sort.wire}');
    return creatorReels[sort] ?? right(page(const []));
  }

  @override
  Future<Either<NetworkExceptions, StorefrontPage<StorefrontReel>>>
  getVendorReels(
    String vendorAccountId, {
    String? cursor,
    int pageSize = 12,
  }) async {
    calls.add('vendorReels');
    return vendorReels;
  }

  @override
  Future<Either<NetworkExceptions, StorefrontPage<StorefrontCollection>>>
  getCollections({
    required StorefrontOwnerKind ownerKind,
    required String ownerAccountId,
    required CollectionKind kind,
    String? cursor,
    int pageSize = 20,
  }) async {
    calls.add('collections ${ownerKind.name} ${kind.name}');
    return collections[kind] ?? right(page(const []));
  }

  @override
  Future<Either<NetworkExceptions, StorefrontFollowSummary>> getFollowSummary(
    String accountId,
  ) async {
    calls.add('follow $accountId');
    return follow;
  }
}

class FakeBrandStorefrontRepository implements BrandStorefrontRepository {
  Either<NetworkExceptions, PublicBrandProfile> brand = right(sampleBrand);

  @override
  Future<Either<NetworkExceptions, PublicBrandProfile>> getBrand(
    String vendorAccountId,
  ) async => brand;
}

class FakeMallCatalogRepository implements MallCatalogRepository {
  Either<NetworkExceptions, CatalogPage<CatalogProduct>> Function(
    ProductListingQuery query,
  )
  products = (_) => right(const CatalogPage(items: []));
  final List<ProductListingQuery> queries = [];

  @override
  Future<Either<NetworkExceptions, CatalogPage<CatalogProduct>>> getProducts(
    ProductListingQuery query, {
    String? cursor,
    int pageSize = 20,
  }) async {
    queries.add(query);
    return products(query);
  }

  @override
  Future<Either<NetworkExceptions, CollectionDetail>> getCollection(
    String slug, {
    String? cursor,
    int pageSize = 20,
  }) async => left(const NetworkExceptions.notFound());
}

class FakeExternalActions implements StorefrontExternalActions {
  final List<String> shared = [];
  final List<Uri> opened = [];

  @override
  Future<void> share({required String text, required String subject}) async {
    shared.add(text);
  }

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

/// The current state of [notifier], read through a listener.
S currentState<S>(StateNotifier<S> notifier) {
  late S value;
  notifier.addListener((state) => value = state)();
  return value;
}
