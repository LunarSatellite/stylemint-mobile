import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_navigation.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_view_mappers.dart';

String? pushed(MallDestination? destination) =>
    destination is MallPush ? destination.location : null;

void main() {
  group('ProductListingQuery', () {
    test('round-trips the listing query parameters', () {
      const params = {
        'sort': 'price_asc',
        'categorySlug': 'fashion',
        'vendorAccountId': 'v-1',
        'minPrice': '500',
        'maxPrice': '2999.5',
        'inStock': 'true',
        'onSale': 'true',
        'minRating': '4',
        'q': 'linen',
      };
      final query = ProductListingQuery.fromQueryParameters(params);
      expect(query.sort, ProductSort.priceAsc);
      expect(query.activeFilterCount, 4);
      expect(query.toQueryParameters(), params);
      expect(ProductListingQuery.fromQueryParameters(params), query);
    });

    test('ignores bad values and falls back to newest', () {
      final query = ProductListingQuery.fromQueryParameters(const {
        'sort': 'cheapest',
        'minPrice': '-4',
        'onSale': 'yes',
        'title': 'Deals',
      });
      expect(query, const ProductListingQuery());
    });

    test('clearing filters keeps scope and sort', () {
      const query = ProductListingQuery(
        sort: ProductSort.rating,
        vendorAccountId: 'v-1',
        onSale: true,
        minPrice: 100,
      );
      expect(
        query.clearFilters(),
        const ProductListingQuery(
          sort: ProductSort.rating,
          vendorAccountId: 'v-1',
        ),
      );
    });
  });

  group('campaign CTAs', () {
    HomeCampaignCta cta(HomeCtaTargetKind kind, [String value = '']) =>
        HomeCampaignCta(label: 'Go', targetKind: kind, targetValue: value);

    test('open the matching screen', () {
      expect(
        pushed(destinationForCta(cta(HomeCtaTargetKind.collection, 'edit'))),
        '/collections/edit',
      );
      expect(
        destinationForCta(cta(HomeCtaTargetKind.reels)),
        isA<MallShowReels>(),
      );
      expect(
        pushed(destinationForCta(cta(HomeCtaTargetKind.reels, 'r-1'))),
        '/reels/r-1',
      );
      expect(
        destinationForCta(cta(HomeCtaTargetKind.creators)),
        isA<MallGoTab>().having((d) => d.location, 'location', '/search'),
      );
      expect(
        pushed(destinationForCta(cta(HomeCtaTargetKind.product, 'p-1'))),
        '/product/p-1',
      );
      final category = Uri.parse(
        pushed(destinationForCta(cta(HomeCtaTargetKind.category, 'shoes')))!,
      );
      expect(category.path, '/products');
      expect(category.queryParameters, {
        'categorySlug': 'shoes',
        'title': 'Go',
      });
      expect(
        pushed(destinationForCta(cta(HomeCtaTargetKind.brand, 'v-1'))),
        '/brands/v-1',
      );
    });

    test('follow only StyleMint links', () {
      expect(
        pushed(
          destinationForCta(
            cta(HomeCtaTargetKind.url, 'https://stylemint.app/product/p-9'),
          ),
        ),
        '/product/p-9',
      );
      expect(
        styleMintLinkRoute('https://stylemint.app/collections/monsoon'),
        '/collections/monsoon',
      );
      expect(styleMintLinkRoute('https://evil.example/product/p-9'), isNull);
      expect(styleMintLinkRoute('https://stylemint.app/gifts'), isNull);
      expect(styleMintLinkRoute('javascript:alert(1)'), isNull);
      expect(destinationForCta(cta(HomeCtaTargetKind.unknown, 'x')), isNull);
    });
  });

  group('See all', () {
    HomeSection section(HomeSeeAllTarget target, [Map<String, String>? p]) =>
        HomeBrandsSection(
          id: 's',
          title: 'Picked for you',
          seeAll: HomeSeeAll(target: target, params: p ?? const {}),
          items: const [HomeBrand(vendorAccountId: 'v', name: 'B')],
        );

    test('productList params map straight onto the listing', () {
      final uri = Uri.parse(
        pushed(
          destinationForSeeAll(
            section(HomeSeeAllTarget.productList, {'sort': 'newest'}),
          ),
        )!,
      );
      expect(uri.path, '/products');
      expect(uri.queryParameters, {
        'sort': 'newest',
        'title': 'Picked for you',
      });
    });

    test('other targets', () {
      expect(
        destinationForSeeAll(section(HomeSeeAllTarget.reels)),
        isA<MallShowReels>(),
      );
      expect(
        pushed(destinationForSeeAll(section(HomeSeeAllTarget.creators))),
        '/discover/creators',
      );
      expect(
        pushed(
          destinationForSeeAll(
            section(HomeSeeAllTarget.collection, {'slug': 'look-1'}),
          ),
        ),
        '/collections/look-1',
      );
      expect(destinationForSeeAll(section(HomeSeeAllTarget.brands)), isNull);
    });
  });

  test('greeting uses Kathmandu time of day', () {
    expect(mallSalutation(DateTime.utc(2026, 9, 15, 1)), 'Good morning');
    expect(mallSalutation(DateTime.utc(2026, 9, 15, 7)), 'Good afternoon');
    expect(mallSalutation(DateTime.utc(2026, 9, 15, 13)), 'Good evening');
    expect(mallSalutation(DateTime.utc(2026, 9, 15, 21)), 'Good evening');
  });
}
