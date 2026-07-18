import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/discover_creator_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ─── SEARCH RESULTS SCREEN ────────────────────────────────────────────────────
class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key, required this.query});

  final String query;

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
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
    final async = ref.watch(customerSearchResultsProvider(widget.query));

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Search Results', style: DesignTokens.sectionInnerTitle),
        centerTitle: false,
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
        ),
        error: (_, _) => Center(
          child: Text(
            'Could not load search results.',
            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
          ),
        ),
        data: (results) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                'Showing ${results.totalHits} results for "${widget.query}"',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                  fontSize: 13,
                ),
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
              labelStyle: DesignTokens.smallRegular.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: DesignTokens.smallRegular.copyWith(fontSize: 14),
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
class _EmptyTabMessage extends StatelessWidget {
  const _EmptyTabMessage(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
          ),
        ),
      );
}

// ─── PRODUCTS TAB ─────────────────────────────────────────────────────────────
class _ProductsTab extends StatelessWidget {
  const _ProductsTab({required this.products});
  final List<SearchResultProduct> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const _EmptyTabMessage('No products found.');
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: products.length,
      separatorBuilder: (_, _i) => Divider(
        height: 1,
        thickness: 1,
        color: DesignTokens.borderDefault,
      ),
      itemBuilder: (_, i) => _ProductResultTile(product: products[i]),
    );
  }
}

class _ProductResultTile extends StatelessWidget {
  const _ProductResultTile({required this.product});

  final SearchResultProduct product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(
        RouteNames.productDetail.replaceFirst(':productId', product.productId),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 72,
                child: product.heroImageUrl.isNotEmpty
                    ? Image.network(
                        product.heroImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _e, _s) => const ColoredBox(
                          color: DesignTokens.bgAppBodyLight,
                          child: Icon(Icons.image_not_supported_outlined,
                              color: DesignTokens.iconLight, size: 22),
                        ),
                      )
                    : const ColoredBox(
                        color: DesignTokens.bgAppBodyLight,
                        child: Icon(Icons.image_not_supported_outlined,
                            color: DesignTokens.iconLight, size: 22),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.textWhite,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${product.currency} ${product.price.toStringAsFixed(0)}',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (product.averageRating > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star_rounded,
                            size: 14, color: DesignTokens.secondaryYellow),
                        const SizedBox(width: 3),
                        Text(
                          '${product.averageRating.toStringAsFixed(1)} Stars',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Icon(
                Icons.shopping_cart_outlined,
                color: DesignTokens.textMuted,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CREATORS TAB ─────────────────────────────────────────────────────────────
class _CreatorsTab extends StatelessWidget {
  const _CreatorsTab({required this.creators});
  final List<SearchResultCreator> creators;

  @override
  Widget build(BuildContext context) {
    if (creators.isEmpty) return const _EmptyTabMessage('No creators found.');
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: creators.length,
      separatorBuilder: (_, _i) => const SizedBox(height: 12),
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
    if (reels.isEmpty) return const _EmptyTabMessage('No reels found.');
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
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
    return GestureDetector(
      onTap: () => context.push(
        RouteNames.reelDetail.replaceFirst(':reelId', reel.reelId),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          reel.thumbnailUrl.isNotEmpty
              ? Image.network(
                  reel.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _e, _s) =>
                      const ColoredBox(color: DesignTokens.bgAppBodyLight),
                )
              : const ColoredBox(color: DesignTokens.bgAppBodyLight),
          Positioned(
            bottom: 8,
            left: 8,
            child: Row(
              children: [
                const Icon(Icons.remove_red_eye_outlined,
                    size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  _formatCount(reel.viewCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ],
            ),
          ),
        ],
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
    if (brands.isEmpty) return const _EmptyTabMessage('No brands found.');
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: brands.length,
      separatorBuilder: (_, _i) => Divider(
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
    final initial = brand.name.trim().isEmpty ? '?' : brand.name.trim()[0].toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 52,
              height: 52,
              child: (brand.logoUrl?.isNotEmpty ?? false)
                  ? Image.network(brand.logoUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, _e, _s) => _BrandInitial(initial))
                  : _BrandInitial(initial),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand.name,
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.textWhite,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                if (brand.averageRating > 0)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: DesignTokens.secondaryYellow),
                      const SizedBox(width: 3),
                      Text(
                        '${brand.averageRating.toStringAsFixed(1)} Stars',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 3),
                Text(
                  '${brand.productCount} Products',
                  style: DesignTokens.smallRegular.copyWith(
                    color: const Color(0xFF4FC3F7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: DesignTokens.iconLight),
        ],
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
            style: const TextStyle(
              color: DesignTokens.textWhite,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ),
      );
}
