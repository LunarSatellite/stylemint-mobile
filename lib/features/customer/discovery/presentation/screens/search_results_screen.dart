import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/discover_creator_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/sponsored_badge.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';

/// Results for one query, split by what was found.
///
/// The products tab is `MallResultRow`, so a product looks the same here as
/// it does in a Mall rail: the typographic ground, never a photo. Empty and
/// failed states are the kit's, so "nothing found" reads as a decision
/// rather than as a page that failed to paint.
class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({
    super.key,
    required this.query,
    this.initialResults,
  });

  final String query;
  final CustomerSearchResults? initialResults;

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = widget.initialResults == null
        ? ref.watch(customerSearchResultsProvider(widget.query))
        : AsyncValue<CustomerSearchResults>.data(widget.initialResults!);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
          ),
          tooltip: 'Back',
          onPressed: () => context.popOrHome(),
        ),
        title: const Text(
          'Search Results',
          style: DesignTokens.sectionInnerTitle,
        ),
        centerTitle: false,
      ),
      body: async.when(
        loading: () => const SmPageLoader(),
        error: (_, _) => MallErrorState(
          icon: Icons.search_off_rounded,
          title: "We couldn't run that search",
          body: 'Check your connection and try again.',
          onRetry: widget.initialResults == null
              ? () => ref.invalidate(
                  customerSearchResultsProvider(widget.query),
                )
              : null,
        ),
        data: (results) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s4,
                DesignTokens.s16,
                0,
              ),
              child: Text(
                widget.initialResults == null
                    ? 'Showing ${results.totalHits} results for "${widget.query}"'
                    : '${results.totalHits} visual matches from your photo',
                style: DesignTokens.smallRegular,
              ),
            ),
            if (results.queryUnderstanding case final understanding?)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s8,
                  DesignTokens.s16,
                  DesignTokens.s4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: DesignTokens.primaryGreen,
                    ),
                    const SizedBox(width: DesignTokens.s8),
                    Expanded(
                      child: Text(
                        'Understood as: $understanding',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.smallDescription.copyWith(
                          color: DesignTokens.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: DesignTokens.primaryGreen,
              unselectedLabelColor: DesignTokens.textMuted,
              indicatorColor: DesignTokens.primaryGreen,
              indicatorWeight: 2,
              dividerColor: DesignTokens.borderDefault,
              labelStyle: DesignTokens.mediumSemibold,
              unselectedLabelStyle: DesignTokens.mediumRegular,
              tabs: const [
                Tab(text: 'Products'),
                Tab(text: 'Creators'),
                Tab(text: 'Reels'),
                Tab(text: 'Brands'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ProductsTab(products: results.products),
                  _CreatorsTab(creators: results.creators),
                  _ReelsTab(reels: results.reels),
                  _BrandsTab(brands: results.brands),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── EMPTY STATE ──────────────────────────────────────────────────────────────

/// One empty state for all four tabs, so "no reels" and "no brands" are the
/// same object with a different word rather than four different messages.
class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      MallEmptyState(icon: icon, title: title, body: body);
}

// ─── PRODUCTS TAB ─────────────────────────────────────────────────────────────
class _ProductsTab extends StatelessWidget {
  const _ProductsTab({required this.products});
  final List<SearchResultProduct> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const _EmptyTab(
        icon: Icons.search_off_rounded,
        title: 'No products found',
        body: 'Try a shorter phrase, or search for a brand instead.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      itemCount: products.length,
      separatorBuilder: (_, _i) => const Divider(
        height: 1,
        thickness: 1,
        color: DesignTokens.borderDefault,
      ),
      itemBuilder: (_, i) => _ProductResultTile(product: products[i]),
    );
  }
}

/// A search hit, in the Mall's own row.
///
/// The rating is drawn only when the catalogue really carries one: a product
/// with no reviews used to render "0.0 Stars", which reads as the worst
/// rating on the page rather than as no rating at all.
class _ProductResultTile extends StatelessWidget {
  const _ProductResultTile({required this.product});

  final SearchResultProduct product;

  MallProductVm get _vm => MallProductVm(
    id: product.productId,
    name: product.name,
    price: Money(amount: product.price, currency: product.currency),
    rating: product.averageRating > 0 ? product.averageRating : null,
  );

  @override
  Widget build(BuildContext context) {
    final disclosure = product.sponsoredDisclosure;
    final reason = product.matchReason;
    return KeyedSubtree(
      key: ValueKey('search-product-${product.productId}'),
      child: MallResultRow(
        product: _vm,
        onTap: () => context.push(
          RouteNames.productDetail.replaceFirst(
            ':productId',
            product.productId,
          ),
        ),
        // The disclosure is spoken first, before the product: a buyer hears
        // that a result is paid for before they hear what it sells.
        semanticPrefix: disclosure,
        semanticExtras: [?reason],
        footer: (disclosure == null && reason == null)
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (reason != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: DesignTokens.primaryGreen,
                        ),
                        const SizedBox(width: DesignTokens.s6),
                        Expanded(
                          child: ExcludeSemantics(
                            child: Text(
                              reason,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: DesignTokens.smallDescription,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (disclosure != null)
                    SponsoredBadge(
                      label: disclosure,
                      onInfo: () => showSponsoredInfoSheet(
                        context,
                        label: disclosure,
                        organicPosition: product.organicPosition,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// What a screen reader says for a product result: the sponsored disclosure
/// first (when paid), then name, price and rating.
String searchProductSemanticsLabel(SearchResultProduct product) => [
  ?product.sponsoredDisclosure,
  product.name,
  '${product.currency} ${product.price.toStringAsFixed(0)}',
  if (product.averageRating > 0)
    'Rated ${product.averageRating.toStringAsFixed(1)} stars',
  ?product.matchReason,
].join('. ');

// ─── CREATORS TAB ─────────────────────────────────────────────────────────────
class _CreatorsTab extends StatelessWidget {
  const _CreatorsTab({required this.creators});
  final List<SearchResultCreator> creators;

  @override
  Widget build(BuildContext context) {
    if (creators.isEmpty) {
      return const _EmptyTab(
        icon: Icons.person_search_rounded,
        title: 'No creators found',
        body: 'Search a handle, or browse the creators on Discover.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      itemCount: creators.length,
      separatorBuilder: (_, _i) => const SizedBox(height: DesignTokens.s12),
      itemBuilder: (_, i) {
        final c = creators[i];
        return DiscoverCreatorCard(
          creator: DiscoverCreator(
            id: c.creatorProfileId,
            name: c.displayName,
            handle: '@${c.handle}',
            avatarUrl: c.avatarUrl ?? '',
            category: '',
            description: '',
            // Search carries no creator rating. Zero here means "unknown",
            // and the card draws nothing rather than "0.0 Stars".
            rating: 0,
            followers: c.followerCount,
            isFollowing: false,
          ),
        );
      },
    );
  }
}

// ─── REELS TAB ────────────────────────────────────────────────────────────────
class _ReelsTab extends StatelessWidget {
  const _ReelsTab({required this.reels});
  final List<SearchResultReel> reels;

  @override
  Widget build(BuildContext context) {
    if (reels.isEmpty) {
      return const _EmptyTab(
        icon: Icons.videocam_off_rounded,
        title: 'No reels found',
        body: 'Try a different phrase, or watch what is trending on Reels.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(DesignTokens.s4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        // A visible gutter on the spacing scale: at 2px the thumbnails
        // fused into one block and read as a contact sheet.
        crossAxisSpacing: DesignTokens.s4,
        mainAxisSpacing: DesignTokens.s4,
        childAspectRatio: 0.85,
      ),
      itemCount: reels.length,
      itemBuilder: (_, i) => _ReelThumbnail(reel: reels[i]),
    );
  }
}

class _ReelThumbnail extends StatelessWidget {
  const _ReelThumbnail({required this.reel});

  final SearchResultReel reel;

  @override
  Widget build(BuildContext context) {
    final views = reel.viewCount > 0 ? _formatCount(reel.viewCount) : null;
    return Semantics(
      button: true,
      label: [
        'Reel',
        if (views != null) '$views views',
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.push(
          RouteNames.reelDetail.replaceFirst(':reelId', reel.reelId),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            reel.thumbnailUrl.isNotEmpty
                ? MallNetworkImage(url: reel.thumbnailUrl)
                : MallTypeGround(seed: reel.reelId),
            const DecoratedBox(
              decoration: BoxDecoration(gradient: DesignTokens.imageScrim),
            ),
            const Center(child: MallPlayMark()),
            // Views are drawn only when the search really returned a count.
            if (views != null)
              PositionedDirectional(
                bottom: DesignTokens.s8,
                start: DesignTokens.s8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.remove_red_eye_outlined,
                      size: 14,
                      color: DesignTokens.textLight,
                    ),
                    const SizedBox(width: DesignTokens.s4),
                    Text(
                      views,
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textWhite,
                        fontWeight: FontWeight.w600,
                        fontFeatures: mallTabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}m';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ─── BRANDS TAB ───────────────────────────────────────────────────────────────
class _BrandsTab extends StatelessWidget {
  const _BrandsTab({required this.brands});
  final List<SearchResultBrand> brands;

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty) {
      return const _EmptyTab(
        icon: Icons.storefront_outlined,
        title: 'No brands found',
        body: 'Search a brand name, or open a brand from a product page.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      itemCount: brands.length,
      separatorBuilder: (_, _i) => const Divider(
        height: 1,
        thickness: 1,
        color: DesignTokens.borderDefault,
      ),
      itemBuilder: (_, i) => _BrandResultTile(brand: brands[i]),
    );
  }
}

class _BrandResultTile extends StatelessWidget {
  const _BrandResultTile({required this.brand});

  final SearchResultBrand brand;

  @override
  Widget build(BuildContext context) {
    final initial = brand.name.trim().isEmpty
        ? '?'
        : brand.name.trim()[0].toUpperCase();
    final rated = brand.averageRating > 0;
    final products = brand.productCount > 0
        ? (brand.productCount == 1
              ? '1 product'
              : '${brand.productCount} products')
        : null;
    final canOpen = brand.brandId.isNotEmpty;
    final logo = brand.logoUrl;
    // Opens the brand's storefront (brandId is the vendor account id).
    return Semantics(
      button: canOpen,
      label: [
        brand.name,
        if (rated) 'Rated ${brand.averageRating.toStringAsFixed(1)} out of 5',
        ?products,
      ].join('. '),
      excludeSemantics: true,
      child: InkWell(
        onTap: canOpen
            ? () => context.push(
                RouteNames.brandStorefront.replaceFirst(
                  ':vendorAccountId',
                  Uri.encodeComponent(brand.brandId),
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: DesignTokens.avatarLarge,
                  height: DesignTokens.avatarLarge,
                  child: logo != null && logo.isNotEmpty
                      ? MallNetworkImage(url: logo)
                      : _BrandInitial(initial),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.sectionInnerTitle.copyWith(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s4),
                    if (rated)
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: DesignTokens.secondaryYellow,
                          ),
                          const SizedBox(width: DesignTokens.s4),
                          Text(
                            brand.averageRating.toStringAsFixed(1),
                            style: DesignTokens.smallRegular.copyWith(
                              fontFeatures: mallTabularFigures,
                            ),
                          ),
                        ],
                      ),
                    if (products != null) ...[
                      const SizedBox(height: DesignTokens.s4),
                      Text(
                        products,
                        style: DesignTokens.smallRegular.copyWith(
                          fontFeatures: mallTabularFigures,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DesignTokens.iconLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandInitial extends StatelessWidget {
  const _BrandInitial(this.initial);
  final String initial;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: DesignTokens.bgAppBodyLight,
    child: Center(
      child: Text(
        initial,
        style: DesignTokens.titleLarge.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
