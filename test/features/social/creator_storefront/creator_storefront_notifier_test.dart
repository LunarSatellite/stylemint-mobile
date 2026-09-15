import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/presentation/notifiers/brand_storefront_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_follow_summary.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/presentation/creator_shop_view.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/presentation/notifiers/creator_storefront_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/presentation/screens/creator_profile_gate.dart';

import '../../customer/storefront/storefront_test_support.dart';

void main() {
  late FakeCreatorStorefrontRepository creators;
  late FakeStorefrontRepository storefront;
  late List<StorefrontFollowSummary> seeded;

  setUp(() {
    creators = FakeCreatorStorefrontRepository();
    storefront = FakeStorefrontRepository();
    seeded = [];
  });

  Future<CreatorStorefrontNotifier> load() async {
    final notifier = CreatorStorefrontNotifier(
      creators,
      storefront,
      accountId: creatorId,
      onFollowSummary: seeded.add,
    );
    await flushMicrotasks();
    return notifier;
  }

  group('CreatorStorefrontNotifier', () {
    test('loads profile, stats and followers from public routes', () async {
      storefront.follow = right(
        const StorefrontFollowSummary(
          followers: 1200,
          isFollowedByViewer: true,
        ),
      );
      final notifier = await load();

      final state = currentState(notifier) as CreatorStorefrontLoaded;
      expect(state.profile.displayName, 'Sarah K');
      expect(state.stats?.publishedReelCount, 12);
      expect(state.followers, 1200);
      expect(state.followedAtLoad, isTrue);
      expect(seeded.single.isFollowedByViewer, isTrue);
      expect(creators.calls, ['profile $creatorId', 'stats $creatorId']);
      expect(storefront.calls, ['follow $creatorId']);
    });

    test('stats and follower failures only hide those figures', () async {
      creators.stats = left(const NetworkExceptions.serverUnavailable());
      storefront.follow = left(const NetworkExceptions.auth());
      final notifier = await load();

      final state = currentState(notifier) as CreatorStorefrontLoaded;
      expect(state.stats, isNull);
      expect(state.followers, isNull);
      expect(seeded, isEmpty);
    });

    test('404 is not found', () async {
      creators.profile = left(const NetworkExceptions.notFound());
      final notifier = await load();
      expect(currentState(notifier), isA<CreatorStorefrontNotFound>());
      expect(seeded, isEmpty);
    });

    test('other failures can be retried', () async {
      creators.profile = left(const NetworkExceptions.noInternetConnection());
      final notifier = await load();
      expect(currentState(notifier), isA<CreatorStorefrontFailure>());

      creators.profile = right(sampleCreator);
      await notifier.load();
      expect(currentState(notifier), isA<CreatorStorefrontLoaded>());
    });

    test('follower count follows a toggle made after loading', () {
      const notFollowing = CreatorStorefrontLoaded(
        profile: sampleCreator,
        followers: 10,
      );
      expect(notFollowing.followersWhen(following: false), 10);
      expect(notFollowing.followersWhen(following: true), 11);

      const following = CreatorStorefrontLoaded(
        profile: sampleCreator,
        followers: 0,
        followedAtLoad: true,
      );
      expect(following.followersWhen(following: false), 0);
      expect(
        const CreatorStorefrontLoaded(
          profile: sampleCreator,
        ).followersWhen(following: true),
        isNull,
      );
    });
  });

  group('BrandStorefrontNotifier', () {
    late FakeBrandStorefrontRepository brands;

    setUp(() => brands = FakeBrandStorefrontRepository());

    Future<BrandStorefrontNotifier> loadBrand() async {
      final notifier = BrandStorefrontNotifier(
        brands,
        storefront,
        vendorAccountId: vendorId,
        onFollowSummary: seeded.add,
      );
      await flushMicrotasks();
      return notifier;
    }

    test('loads the brand and seeds follow state', () async {
      final notifier = await loadBrand();
      final state = currentState(notifier) as BrandStorefrontLoaded;
      expect(state.brand.name, 'Mint Goods');
      expect(seeded, hasLength(1));
    });

    test('404 is not found and seeds nothing', () async {
      brands.brand = left(const NetworkExceptions.notFound());
      final notifier = await loadBrand();
      expect(currentState(notifier), isA<BrandStorefrontNotFound>());
      expect(seeded, isEmpty);
    });

    test('other failures are failures', () async {
      brands.brand = left(const NetworkExceptions.serverUnavailable());
      final notifier = await loadBrand();
      expect(currentState(notifier), isA<BrandStorefrontFailure>());
    });
  });

  group('creator shop grouping', () {
    final products = [
      shopProduct('p1'),
      shopProduct(
        'p2',
        vendor: otherVendorId,
        vendorName: 'Loom',
        reelCount: 4,
      ),
      shopProduct('p3', reelCount: 2),
      shopProduct('p4', vendor: '', vendorName: 'Loose Label', reelCount: 4),
    ];

    test('brands are counted, most pieces first', () {
      final brands = creatorShopBrands(products);
      expect(brands.map((b) => (b.name, b.count)), [
        ('Mint Goods', 2),
        ('Loom', 1),
        ('Loose Label', 1),
      ]);
    });

    test('filters by brand and sorts by most loved, keeping ties stable', () {
      expect(
        creatorShopView(products, brandKey: vendorId).map((p) => p.productId),
        ['p1', 'p3'],
      );
      expect(
        creatorShopView(
          products,
          sort: CreatorShopSort.mostLoved,
        ).map((p) => p.productId),
        ['p2', 'p4', 'p3', 'p1'],
      );
    });
  });

  group('isOwnCreatorProfile', () {
    test('only the creator themselves gets the owner view', () {
      expect(
        isOwnCreatorProfile(viewerAccountId: null, accountId: creatorId),
        isFalse,
      );
      expect(
        isOwnCreatorProfile(viewerAccountId: 'someone', accountId: creatorId),
        isFalse,
      );
      expect(
        isOwnCreatorProfile(
          viewerAccountId: creatorId.toUpperCase(),
          accountId: creatorId,
        ),
        isTrue,
      );
      expect(
        isOwnCreatorProfile(viewerAccountId: 'me', accountId: ''),
        isTrue,
      );
    });
  });
}
