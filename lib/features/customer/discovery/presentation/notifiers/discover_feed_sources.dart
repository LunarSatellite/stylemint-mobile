import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feed.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discover_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_catalog_repository.dart';

typedef DiscoverHomeLoader =
    Future<Either<NetworkExceptions, MallHome>> Function();

typedef DiscoverBlocksResult = Either<NetworkExceptions, List<DiscoverBlock>>;

/// Builds and pages the blocks of one chip's feed.
abstract interface class DiscoverFeedSource {
  /// Whether [more] can add anything.
  bool get hasMore;

  Future<DiscoverBlocksResult> first();

  /// [current] with the next blocks (or a longer last block) appended.
  Future<DiscoverBlocksResult> more(List<DiscoverBlock> current);
}

extension CatalogProductToHomeProduct on CatalogProduct {
  HomeProduct toHomeProduct() => HomeProduct(
    id: id,
    name: name,
    price: price,
    brandName: vendorDisplayName,
    vendorAccountId: vendorAccountId,
    imageUrl: imageUrl,
    compareAtPrice: compareAtPrice,
    rating: rating,
    reviewCount: reviewCount,
    isLowStock: isLowStock,
    isOnSale: compareAtPrice != null,
  );
}

/// Cursor paging over `GET v1/public/products`.
class DiscoverProductPager {
  DiscoverProductPager(this._catalog, this.query, {this.pageSize = 20});

  final MallCatalogRepository _catalog;
  final ProductListingQuery query;
  final int pageSize;

  String? _cursor;
  bool _started = false;

  bool get hasMore => !_started || _cursor != null;

  Future<Either<NetworkExceptions, List<HomeProduct>>> next() async {
    if (!hasMore) return right(const []);
    final result = await _catalog.getProducts(
      query,
      cursor: _cursor,
      pageSize: pageSize,
    );
    return result.map((page) {
      _started = true;
      _cursor = page.nextCursor;
      return [for (final product in page.items) product.toHomeProduct()];
    });
  }
}

/// Pages a server filter can empty are followed at most this many times per
/// load, so a run of empty pages can't spin.
const int _maxPagesPerLoad = 4;

List<T> _unique<T>(Iterable<T> items, String Function(T item) idOf) {
  final seen = <String>{};
  return [
    for (final item in items)
      if (idOf(item).isNotEmpty && seen.add(idOf(item))) item,
  ];
}

/// A product result list (Trending, New Drops, Sale, a category): one
/// growing block, each product once.
class ListingFeedSource implements DiscoverFeedSource {
  ListingFeedSource(
    MallCatalogRepository catalog,
    ProductListingQuery query, {
    required this.eyebrow,
    required this.title,
    int pageSize = 20,
  }) : _pager = DiscoverProductPager(catalog, query, pageSize: pageSize);

  final DiscoverProductPager _pager;
  final String eyebrow;
  final String title;
  final Set<String> _seen = {};
  final List<HomeProduct> _items = [];

  ProductListingQuery get query => _pager.query;

  @override
  bool get hasMore => _pager.hasMore;

  @override
  Future<DiscoverBlocksResult> first() => _load();

  @override
  Future<DiscoverBlocksResult> more(List<DiscoverBlock> current) => _load();

  Future<DiscoverBlocksResult> _load() async {
    for (var page = 0; page < _maxPagesPerLoad && _pager.hasMore; page++) {
      final result = await _pager.next();
      switch (result) {
        case Left(:final value):
          return left(value);
        case Right(:final value):
          final before = _items.length;
          _items.addAll(value.where((product) => _seen.add(product.id)));
          if (_items.length > before) page = _maxPagesPerLoad;
      }
    }
    return right([
      if (_items.isNotEmpty)
        DiscoverProductsBlock(
          key: 'listing',
          eyebrow: eyebrow,
          title: title,
          items: List.unmodifiable(_items),
          isListing: true,
        ),
    ]);
  }
}

/// Every published collection (the Collections chip).
class CollectionsFeedSource implements DiscoverFeedSource {
  CollectionsFeedSource(this._repository, {this.pageSize = 20});

  final DiscoverRepository _repository;
  final int pageSize;
  final Set<String> _seen = {};
  final List<HomeCollection> _items = [];
  String? _cursor;
  bool _started = false;

  @override
  bool get hasMore => !_started || _cursor != null;

  @override
  Future<DiscoverBlocksResult> first() => _load();

  @override
  Future<DiscoverBlocksResult> more(List<DiscoverBlock> current) => _load();

  Future<DiscoverBlocksResult> _load() async {
    for (var page = 0; page < _maxPagesPerLoad && hasMore; page++) {
      final result = await _repository.getCollections(
        cursor: _cursor,
        pageSize: pageSize,
      );
      switch (result) {
        case Left(:final value):
          return left(value);
        case Right(:final value):
          _started = true;
          _cursor = value.nextCursor;
          final before = _items.length;
          _items.addAll(value.items.where((item) => _seen.add(item.slug)));
          if (_items.length > before) page = _maxPagesPerLoad;
      }
    }
    return right([
      if (_items.isNotEmpty)
        DiscoverCollectionsBlock(
          key: 'collections',
          eyebrow: 'Collections',
          title: 'Edits and looks',
          items: List.unmodifiable(_items),
        ),
    ]);
  }
}

/// Reels, Creators or Brands straight from the home page.
class HomeFeedSource implements DiscoverFeedSource {
  HomeFeedSource(this._loadHome, this.kind);

  final DiscoverHomeLoader _loadHome;
  final DiscoverFeedKind kind;

  @override
  bool get hasMore => false;

  @override
  Future<DiscoverBlocksResult> first() async =>
      (await _loadHome()).map(_blocks);

  @override
  Future<DiscoverBlocksResult> more(List<DiscoverBlock> current) async =>
      right(current);

  List<DiscoverBlock> _blocks(MallHome home) {
    switch (kind) {
      case DiscoverFeedKind.reels:
        final reels = homeReels(home);
        return [
          if (reels.isNotEmpty)
            DiscoverReelsBlock(
              key: 'reels',
              eyebrow: 'Reels',
              title: 'Watch, then shop the look',
              items: reels,
              layout: DiscoverLayout.grid,
            ),
        ];
      case DiscoverFeedKind.creators:
        final creators = homeCreators(home);
        return [
          if (creators.isNotEmpty)
            DiscoverCreatorsBlock(
              key: 'creators',
              eyebrow: 'Creators',
              title: 'Creators to follow',
              items: creators,
              layout: DiscoverLayout.grid,
            ),
        ];
      case DiscoverFeedKind.brands:
        final brands = homeBrands(home);
        return [
          if (brands.isNotEmpty)
            DiscoverBrandsBlock(
              key: 'brands',
              eyebrow: 'Brands',
              title: 'Brands to know',
              items: brands,
              layout: DiscoverLayout.grid,
            ),
        ];
      case DiscoverFeedKind.forYou:
      case DiscoverFeedKind.trending:
      case DiscoverFeedKind.newDrops:
      case DiscoverFeedKind.sale:
      case DiscoverFeedKind.collections:
        return const [];
    }
  }
}

List<HomeReel> homeReels(MallHome home) => _unique([
  for (final section in home.sections.whereType<HomeReelsSection>())
    ...section.items,
], (reel) => reel.id);

List<HomeCreator> homeCreators(MallHome home) => _unique([
  for (final section in home.sections.whereType<HomeCreatorsSection>())
    ...section.items,
], (creator) => creator.accountId);

List<HomeBrand> homeBrands(MallHome home) => _unique([
  for (final section in home.sections.whereType<HomeBrandsSection>())
    ...section.items,
], (brand) => brand.vendorAccountId);

/// The controlled For You feed. Opens in a fixed editorial rhythm:
///
/// products (6) · reels rail · creators rail · products (6) · featured
/// collection · brands rail
///
/// then pages further product blocks of 6 from the bestselling listing, with
/// the next featured collection after every second block. Products come from
/// the home page's product rails (those carrying a server `reason` line
/// first) and then the listing, each product at most once across the whole
/// feed.
///
/// ## This feed is not personalised, and its own copy must not say it is
///
/// Every product here arrives from one of two sources, and neither one knows
/// who is reading:
///
/// * `GET /api/v1/public/home` — a **public**, merchandised page. Its
///   sections carry no `slotKind`, no score and no rank. The only
///   per-customer signals on the wire are a coarse response-level
///   `personalized` flag and a free-text `reason` on a section, and neither
///   is per product.
/// * The bestselling product listing — identical for every customer.
///
/// Blocks are cut from a single pool that mixes both, so no block can honestly
/// claim a relationship to this reader. The hardcoded block titles therefore
/// use the `FeedSlotKind.unknown` vocabulary — "From the Mall" — which names
/// the source and claims nothing about the person. A server-sent section title
/// is content, not a client claim, and always wins over the fallback.
///
/// If the home contract later stamps sections with a real `slotKind`, this is
/// the place to start saying "From your interests" — and only then.
class ForYouFeedSource implements DiscoverFeedSource {
  ForYouFeedSource(
    this._loadHome,
    MallCatalogRepository catalog, {
    int pageSize = 20,
  }) : _pager = DiscoverProductPager(
         catalog,
         const ProductListingQuery(sort: ProductSort.bestselling),
         pageSize: pageSize,
       );

  static const int blockSize = 6;

  final DiscoverHomeLoader _loadHome;
  final DiscoverProductPager _pager;
  final Set<String> _seenProducts = {};
  final List<HomeProduct> _pool = [];
  final List<HomeCollection> _collections = [];
  int _productBlocks = 0;
  int _appended = 0;

  @override
  bool get hasMore => _pool.isNotEmpty || _pager.hasMore;

  @override
  Future<DiscoverBlocksResult> first() async {
    final MallHome home;
    switch (await _loadHome()) {
      case Left(:final value):
        return left(value);
      case Right(:final value):
        home = value;
    }
    final productSections = home.sections
        .whereType<HomeProductsSection>()
        .toList();
    final ordered = [
      ...productSections.where((section) => section.reason != null),
      ...productSections.where((section) => section.reason == null),
    ];
    _addToPool([for (final section in ordered) ...section.items]);
    _collections.addAll(
      _unique([
        for (final section in home.sections.whereType<HomeCollectionsSection>())
          ...section.items,
      ], (collection) => collection.slug),
    );
    // Fill both opening product blocks when the listing can. A failed page
    // still shows the home content; the next load retries it.
    await _topUp(blockSize * 2);

    final lead = ordered.isEmpty ? null : ordered.first;
    final reels = homeReels(home);
    final creators = homeCreators(home);
    final brands = homeBrands(home);
    String? titleOf<T extends HomeSection>() {
      for (final section in home.sections.whereType<T>()) {
        final title = section.title?.trim();
        if (title != null && title.isNotEmpty) return title;
      }
      return null;
    }

    final blocks = <DiscoverBlock>[];
    // A server-sent title is content and wins. The fallback is the app's own
    // sentence, so it may only say what the app can defend: these products
    // come from the public Mall home rails and the bestselling listing, and
    // nothing here was picked for this reader. See the class doc.
    _addProductBlock(
      blocks,
      title: lead?.title?.trim() ?? 'From the Mall',
      subtitle: lead?.reason,
    );
    if (reels.isNotEmpty) {
      blocks.add(
        DiscoverReelsBlock(
          key: 'fy-reels',
          eyebrow: 'Reels',
          title: titleOf<HomeReelsSection>() ?? 'Shoppable reels',
          items: reels,
        ),
      );
    }
    if (creators.isNotEmpty) {
      blocks.add(
        DiscoverCreatorsBlock(
          key: 'fy-creators',
          eyebrow: 'Creators',
          title: titleOf<HomeCreatorsSection>() ?? 'Creators to follow',
          items: creators,
        ),
      );
    }
    _addProductBlock(blocks, title: 'More from the Mall');
    _addCollectionBlock(blocks);
    if (brands.isNotEmpty) {
      blocks.add(
        DiscoverBrandsBlock(
          key: 'fy-brands',
          eyebrow: 'Brands',
          title: titleOf<HomeBrandsSection>() ?? 'Brands to know',
          items: brands,
        ),
      );
    }
    return right(blocks);
  }

  @override
  Future<DiscoverBlocksResult> more(List<DiscoverBlock> current) async {
    final failure = await _topUp(blockSize);
    if (failure != null) return left(failure);
    final blocks = [...current];
    if (_pool.isEmpty) return right(blocks);
    _addProductBlock(blocks, title: 'Keep exploring');
    _appended++;
    if (_appended.isEven) _addCollectionBlock(blocks);
    return right(blocks);
  }

  /// Pages the listing until the pool holds [count] products. Returns the
  /// failure of a page that failed.
  Future<NetworkExceptions?> _topUp(int count) async {
    for (
      var page = 0;
      page < _maxPagesPerLoad && _pool.length < count && _pager.hasMore;
      page++
    ) {
      switch (await _pager.next()) {
        case Left(:final value):
          return value;
        case Right(:final value):
          _addToPool(value);
      }
    }
    return null;
  }

  void _addToPool(Iterable<HomeProduct> products) {
    for (final product in products) {
      if (product.id.isNotEmpty && _seenProducts.add(product.id)) {
        _pool.add(product);
      }
    }
  }

  void _addProductBlock(
    List<DiscoverBlock> blocks, {
    required String title,
    String? subtitle,
  }) {
    if (_pool.isEmpty) return;
    final count = _pool.length < blockSize ? _pool.length : blockSize;
    final items = List<HomeProduct>.unmodifiable(_pool.take(count));
    _pool.removeRange(0, count);
    blocks.add(
      DiscoverProductsBlock(
        key: 'fy-products-${_productBlocks++}',
        eyebrow: 'Products',
        title: title,
        subtitle: subtitle,
        items: items,
      ),
    );
  }

  void _addCollectionBlock(List<DiscoverBlock> blocks) {
    if (_collections.isEmpty) return;
    final collection = _collections.removeAt(0);
    blocks.add(
      DiscoverCollectionBlock(
        key: 'fy-collection-${collection.slug}',
        eyebrow: 'Collection',
        title: 'Featured edit',
        collection: collection,
      ),
    );
  }
}
