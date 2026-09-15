import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/domain/entities/public_brand_profile.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/presentation/brand_story.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_navigation.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_view_mappers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/mall_choice_chip.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/product_filter_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_collection.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/notifiers/storefront_paged_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/storefront_view_mappers.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_collection_cards.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_reel_grid.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_states.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The tabs of a brand storefront, in order.
enum BrandStorefrontTab {
  home('Home'),
  shopAll('Shop All'),
  newIn('New'),
  reels('Reels'),
  collections('Collections'),
  about('About');

  const BrandStorefrontTab(this.label);

  final String label;
}

/// The brand's newest products (the New tab and the Home rail).
ProductListingQuery brandNewestQuery(String vendorAccountId) =>
    ProductListingQuery(vendorAccountId: vendorAccountId);

/// The brand's best sellers (the Home rail).
ProductListingQuery brandBestSellersQuery(String vendorAccountId) =>
    ProductListingQuery(
      vendorAccountId: vendorAccountId,
      sort: ProductSort.bestselling,
    );

/// The brand's live collections.
StorefrontCollectionsKey brandCollectionsKey(String vendorAccountId) => (
  ownerKind: StorefrontOwnerKind.vendor,
  ownerAccountId: vendorAccountId,
  kind: CollectionKind.brandCollection,
);

/// Chip label and spoken label of each listing sort.
(String, String) productSortLabels(ProductSort sort) => switch (sort) {
  ProductSort.newest => ('Newest', 'Newest'),
  ProductSort.bestselling => ('Best selling', 'Best selling'),
  ProductSort.rating => ('Top rated', 'Top rated'),
  ProductSort.priceAsc => ('Price ↑', 'Price, low to high'),
  ProductSort.priceDesc => ('Price ↓', 'Price, high to low'),
};

const TextStyle _countStyle = TextStyle(
  fontFamily: DesignTokens.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 1.4,
  color: DesignTokens.textMuted,
);

void _openProduct(BuildContext context, String id) =>
    unawaited(context.push(MallRoutes.product(id)));

void _openReel(BuildContext context, StorefrontReel reel) =>
    unawaited(context.push(MallRoutes.reel(reel.id)));

void _openCollection(BuildContext context, StorefrontCollection collection) =>
    unawaited(context.push(MallRoutes.collection(collection.slug)));

// ── Home ────────────────────────────────────────────────────────────────────

/// New arrivals, best sellers, a featured collection, creator reels and the
/// opening of the brand story.
class BrandHomeTab extends ConsumerWidget {
  const BrandHomeTab({
    required this.vendorAccountId,
    required this.brandName,
    required this.onOpenTab,
    required this.onShopBestSellers,
    super.key,
    this.brand,
  });

  final String vendorAccountId;
  final String brandName;
  final PublicBrandProfile? brand;
  final ValueChanged<BrandStorefrontTab> onOpenTab;
  final VoidCallback onShopBestSellers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newestProvider = storefrontProductsProvider(
      brandNewestQuery(vendorAccountId),
    );
    final bestProvider = storefrontProductsProvider(
      brandBestSellersQuery(vendorAccountId),
    );
    final collectionsProvider = storefrontCollectionsProvider(
      brandCollectionsKey(vendorAccountId),
    );
    final reelsProvider = vendorReelsProvider(vendorAccountId);
    final newest = ref.watch(newestProvider);
    final best = ref.watch(bestProvider);
    final collections = ref.watch(collectionsProvider);
    final reels = ref.watch(reelsProvider);
    final all = <StorefrontPagedState<Object>>[
      newest,
      best,
      collections,
      reels,
    ];

    if (all.every((state) => state is StorefrontPagedFailure)) {
      return SliverMainAxisGroup(
        slivers: [
          StorefrontSliverMessage.failure(
            (newest as StorefrontPagedFailure<CatalogProduct>).failure,
            onRetry: () {
              unawaited(ref.read(newestProvider.notifier).refresh());
              unawaited(ref.read(bestProvider.notifier).refresh());
              unawaited(ref.read(collectionsProvider.notifier).refresh());
              unawaited(ref.read(reelsProvider.notifier).refresh());
            },
          ),
        ],
      );
    }
    if (all.every(
      (state) => state is StorefrontPagedLoaded<Object> && state.items.isEmpty,
    )) {
      return SliverMainAxisGroup(
        slivers: [
          StorefrontSliverMessage(
            icon: Icons.storefront_outlined,
            title: 'The flagship is being styled',
            body:
                'New pieces from $brandName will appear here soon. '
                'Follow to hear first.',
          ),
        ],
      );
    }

    final story = brand?.story;
    return SliverMainAxisGroup(
      slivers: [
        ..._productRail(
          context,
          newest,
          eyebrow: 'Just in',
          title: 'New arrivals',
          onSeeAll: () => onOpenTab(BrandStorefrontTab.newIn),
        ),
        ..._productRail(
          context,
          best,
          eyebrow: 'Most loved',
          title: 'Best sellers',
          onSeeAll: onShopBestSellers,
        ),
        ..._featured(context, collections),
        ..._reelsRail(context, reels),
        if (story != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                DesignTokens.s16,
                DesignTokens.s32,
                DesignTokens.s16,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MallEyebrow('Our story'),
                  const SizedBox(height: DesignTokens.s12),
                  BrandPullQuote(text: brandPullQuote(story)),
                  const SizedBox(height: DesignTokens.s4),
                  TextButton(
                    onPressed: () => onOpenTab(BrandStorefrontTab.about),
                    style: TextButton.styleFrom(
                      foregroundColor: DesignTokens.textWhite,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(
                        DesignTokens.minTouchTarget,
                        DesignTokens.minTouchTarget,
                      ),
                    ),
                    child: const Text(
                      'Read our story',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.s40)),
      ],
    );
  }

  List<Widget> _productRail(
    BuildContext context,
    StorefrontPagedState<CatalogProduct> state, {
    required String eyebrow,
    required String title,
    required VoidCallback onSeeAll,
  }) {
    const width = MallProductCard.compactWidth;
    final height = MallProductCard.heightFor(
      context,
      width: width,
      size: MallCardSize.compact,
    );
    final header = StorefrontSliverHeader(
      eyebrow: eyebrow,
      title: title,
      onSeeAll: onSeeAll,
    );
    return switch (state) {
      StorefrontPagedLoading() => [
        header,
        SliverToBoxAdapter(
          child: SmSkeletonRail(
            itemWidth: width,
            height: height,
            itemBuilder: (_, _) => const SmSkeletonProductCard(
              width: width,
              size: MallCardSize.compact,
            ),
          ),
        ),
      ],
      StorefrontPagedLoaded(:final items) when items.isNotEmpty => [
        header,
        SliverToBoxAdapter(
          child: MallRail<CatalogProduct>(
            items: items.take(12).toList(growable: false),
            itemWidth: width,
            height: height,
            semanticLabel: title,
            itemBuilder: (context, product, _) => MallProductCard(
              product: product.toVm(),
              size: MallCardSize.compact,
              onTap: () => _openProduct(context, product.id),
            ),
          ),
        ),
      ],
      _ => const [],
    };
  }

  List<Widget> _featured(
    BuildContext context,
    StorefrontPagedState<StorefrontCollection> state,
  ) {
    if (state is! StorefrontPagedLoaded<StorefrontCollection> ||
        state.items.isEmpty) {
      return const [];
    }
    final featured = state.items.first;
    return [
      StorefrontSliverHeader(
        eyebrow: 'The edit',
        title: 'Featured collection',
        onSeeAll: state.items.length > 1
            ? () => onOpenTab(BrandStorefrontTab.collections)
            : null,
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: DesignTokens.s16,
          ),
          child: MallCollectionCard(
            collection: featured.toVm(),
            aspectRatio: StorefrontSliverCollections.aspectRatio,
            onTap: () => _openCollection(context, featured),
          ),
        ),
      ),
    ];
  }

  List<Widget> _reelsRail(
    BuildContext context,
    StorefrontPagedState<StorefrontReel> state,
  ) {
    const width = MallReelCard.compactWidth;
    final height = MallReelCard.heightFor(width);
    final header = StorefrontSliverHeader(
      eyebrow: 'As seen on creators',
      title: 'Styled in reels',
      onSeeAll: () => onOpenTab(BrandStorefrontTab.reels),
    );
    return switch (state) {
      StorefrontPagedLoading() => [
        header,
        SliverToBoxAdapter(
          child: SmSkeletonRail(
            itemWidth: width,
            height: height,
            itemBuilder: (_, _) => const SmSkeletonReelCard(width: width),
          ),
        ),
      ],
      StorefrontPagedLoaded(:final items) when items.isNotEmpty => [
        header,
        SliverToBoxAdapter(
          child: MallRail<StorefrontReel>(
            items: items.take(8).toList(growable: false),
            itemWidth: width,
            height: height,
            semanticLabel: 'Reels featuring $brandName',
            itemBuilder: (context, reel, _) => MallReelCard(
              reel: reel.toVm(fallbackCreatorName: 'StyleMint creator'),
              onTap: () => _openReel(context, reel),
            ),
          ),
        ),
      ],
      _ => const [],
    };
  }
}

// ── Shop All and New ────────────────────────────────────────────────────────

/// The brand's products for [query]. With [showControls] (Shop All) it has
/// sort chips and the filter sheet; without (New) a heading.
class BrandProductsTab extends ConsumerWidget {
  const BrandProductsTab({
    required this.query,
    required this.brandName,
    required this.showControls,
    required this.onQueryChanged,
    super.key,
  });

  final ProductListingQuery query;
  final String brandName;
  final bool showControls;
  final ValueChanged<ProductListingQuery> onQueryChanged;

  Future<void> _openFilters(BuildContext context) async {
    final chosen = await showProductFilterSheet(context, query);
    if (chosen == null || chosen == query || !context.mounted) return;
    onQueryChanged(chosen);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = storefrontProductsProvider(query);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final filtered = query.activeFilterCount > 0;
    final count = switch (state) {
      StorefrontPagedLoaded(:final items, :final totalCount) =>
        (totalCount ?? items.length) == 1
            ? '1 product'
            : '${formatCompactNumber(totalCount ?? items.length)} products',
      _ => '',
    };

    return SliverMainAxisGroup(
      slivers: [
        if (showControls)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: DesignTokens.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: DesignTokens.s16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            count,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _countStyle,
                          ),
                        ),
                        _FilterButton(
                          activeCount: query.activeFilterCount,
                          onPressed: () => unawaited(_openFilters(context)),
                        ),
                      ],
                    ),
                  ),
                  StorefrontChipRow(
                    children: [
                      for (final sort in ProductSort.values)
                        MallChoiceChip(
                          label: productSortLabels(sort).$1,
                          semanticLabel: productSortLabels(sort).$2,
                          selected: query.sort == sort,
                          onTap: () => onQueryChanged(query.withSort(sort)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          StorefrontSliverHeader(
            eyebrow: 'Just landed',
            title: 'New arrivals',
            subtitle: 'The latest pieces from $brandName',
            topPadding: DesignTokens.s20,
          ),
        ...switch (state) {
          StorefrontPagedLoading() => const [
            SliverToBoxAdapter(child: SizedBox(height: DesignTokens.s12)),
            MallSliverProductGrid(products: [], isLoading: true),
          ],
          StorefrontPagedFailure(:final failure) => [
            StorefrontSliverMessage.failure(
              failure,
              onRetry: () => unawaited(notifier.refresh()),
            ),
          ],
          StorefrontPagedLoaded() when state.isEmpty => [
            if (filtered)
              StorefrontSliverMessage(
                icon: Icons.search_off_rounded,
                title: 'No pieces match these filters',
                body: 'Try a wider price range or fewer filters.',
                actionLabel: 'Clear filters',
                onAction: () => onQueryChanged(query.clearFilters()),
              )
            else if (showControls)
              StorefrontSliverMessage(
                icon: Icons.storefront_outlined,
                title: 'No products yet',
                body: '$brandName is stocking the shelves. Check back soon.',
              )
            else
              StorefrontSliverMessage(
                icon: Icons.new_releases_outlined,
                title: 'No new arrivals yet',
                body: 'Fresh pieces from $brandName will land here.',
              ),
          ],
          final StorefrontPagedLoaded<CatalogProduct> loaded => [
            const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.s12)),
            MallSliverProductGrid(
              products: [for (final product in loaded.items) product.toVm()],
              onProductTap: (product) => _openProduct(context, product.id),
            ),
            StorefrontSliverPagingFooter(
              state: loaded,
              onRetry: () => unawaited(notifier.retryLoadMore()),
            ),
          ],
        },
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onPressed});

  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = activeCount > 0 ? 'Filter · $activeCount' : 'Filter';
    return Semantics(
      button: true,
      label: activeCount > 0 ? 'Filter, $activeCount active' : 'Filter',
      excludeSemantics: true,
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: DesignTokens.textWhite,
          backgroundColor: DesignTokens.surfaceRaised,
          minimumSize: const Size(
            DesignTokens.minTouchTarget,
            DesignTokens.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: const StadiumBorder(),
        ),
        icon: const Icon(Icons.tune_rounded, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Reels ───────────────────────────────────────────────────────────────────

/// Public reels that tag the brand's products.
class BrandReelsTab extends ConsumerWidget {
  const BrandReelsTab({
    required this.vendorAccountId,
    required this.brandName,
    super.key,
  });

  final String vendorAccountId;
  final String brandName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = vendorReelsProvider(vendorAccountId);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    return SliverMainAxisGroup(
      slivers: [
        StorefrontSliverHeader(
          eyebrow: 'As seen on creators',
          title: 'Styled in reels',
          subtitle: 'Creators wearing $brandName',
          topPadding: DesignTokens.s20,
        ),
        ...switch (state) {
          StorefrontPagedLoading() => const [
            StorefrontSliverReelGridSkeleton(),
          ],
          StorefrontPagedFailure(:final failure) => [
            StorefrontSliverMessage.failure(
              failure,
              onRetry: () => unawaited(notifier.refresh()),
            ),
          ],
          StorefrontPagedLoaded() when state.isEmpty => [
            StorefrontSliverMessage(
              icon: Icons.movie_filter_outlined,
              title: 'No creator reels yet',
              body:
                  "When creators tag $brandName in their reels, you'll see "
                  'them here.',
            ),
          ],
          final StorefrontPagedLoaded<StorefrontReel> loaded => [
            StorefrontSliverReelGrid(
              reels: loaded.items,
              onReelTap: (reel) => _openReel(context, reel),
            ),
            StorefrontSliverPagingFooter(
              state: loaded,
              onRetry: () => unawaited(notifier.retryLoadMore()),
            ),
          ],
        },
      ],
    );
  }
}

// ── Collections ─────────────────────────────────────────────────────────────

class BrandCollectionsTab extends ConsumerWidget {
  const BrandCollectionsTab({
    required this.vendorAccountId,
    required this.brandName,
    super.key,
  });

  final String vendorAccountId;
  final String brandName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = storefrontCollectionsProvider(
      brandCollectionsKey(vendorAccountId),
    );
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.s16)),
        ...switch (state) {
          StorefrontPagedLoading() => const [
            SliverPadding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: DesignTokens.s16,
              ),
              sliver: SliverToBoxAdapter(
                child: AspectRatio(
                  aspectRatio: StorefrontSliverCollections.aspectRatio,
                  child: SmSkeleton.box(radius: DesignTokens.cardRadius),
                ),
              ),
            ),
          ],
          StorefrontPagedFailure(:final failure) => [
            StorefrontSliverMessage.failure(
              failure,
              onRetry: () => unawaited(notifier.refresh()),
            ),
          ],
          StorefrontPagedLoaded() when state.isEmpty => [
            StorefrontSliverMessage(
              icon: Icons.collections_bookmark_outlined,
              title: 'No collections yet',
              body: "$brandName's curated edits will live here.",
            ),
          ],
          final StorefrontPagedLoaded<StorefrontCollection> loaded => [
            StorefrontSliverCollections(
              collections: loaded.items,
              onTap: (collection) => _openCollection(context, collection),
            ),
            StorefrontSliverPagingFooter(
              state: loaded,
              onRetry: () => unawaited(notifier.retryLoadMore()),
            ),
          ],
        },
      ],
    );
  }
}

// ── About ───────────────────────────────────────────────────────────────────

/// A pull quote in the display face.
class BrandPullQuote extends StatelessWidget {
  const BrandPullQuote({required this.text, super.key});

  final String text;

  static const TextStyle _style = TextStyle(
    fontFamily: DesignTokens.displayFontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    height: 32 / 26,
    letterSpacing: -0.2,
    color: DesignTokens.textWhite,
  );

  @override
  Widget build(BuildContext context) => Text('“$text”', style: _style);
}

/// Story, origin, returns, support and trust points.
class BrandAboutTab extends ConsumerWidget {
  const BrandAboutTab({super.key, this.brand});

  /// Null while loading.
  final PublicBrandProfile? brand;

  static const TextStyle _bodyStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: DesignTokens.textLight,
  );

  Future<void> _openSupport(
    BuildContext context,
    WidgetRef ref,
    Uri uri,
  ) async {
    final opened = await ref.read(storefrontExternalActionsProvider).open(uri);
    if (!opened && context.mounted) {
      SmSnackbar.error(context, "Couldn't open the support page.");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = brand;
    if (profile == null) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16, 28, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SmSkeleton.line(width: 80),
              SizedBox(height: DesignTokens.s16),
              SmSkeleton.line(height: 24),
              SizedBox(height: DesignTokens.s8),
              SmSkeleton.line(width: 220, height: 24),
              SizedBox(height: DesignTokens.s20),
              SmSkeleton.line(),
              SizedBox(height: DesignTokens.s8),
              SmSkeleton.line(width: 260),
            ],
          ),
        ),
      );
    }

    final story = profile.story;
    final body = story == null ? null : brandStoryBody(story);
    final origin = profile.origin;
    final year = profile.foundedYear;
    final policy = profile.returnPolicySummary;
    final support = profile.supportUri;

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              DesignTokens.s16,
              DesignTokens.s28,
              DesignTokens.s16,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MallEyebrow('Our story'),
                const SizedBox(height: DesignTokens.s12),
                if (story != null) ...[
                  BrandPullQuote(text: brandPullQuote(story)),
                  if (body != null) ...[
                    const SizedBox(height: DesignTokens.s16),
                    Text(body, style: _bodyStyle),
                  ],
                ] else
                  Text(
                    "${profile.name} hasn't shared its story yet.",
                    style: _bodyStyle.copyWith(color: DesignTokens.textMuted),
                  ),
              ],
            ),
          ),
        ),
        if (origin != null || year != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                DesignTokens.s16,
                DesignTokens.s28,
                DesignTokens.s16,
                0,
              ),
              child: Wrap(
                spacing: DesignTokens.s12,
                runSpacing: DesignTokens.s12,
                children: [
                  if (origin != null)
                    _FactTile(
                      icon: Icons.place_outlined,
                      label: 'Origin',
                      value: origin,
                    ),
                  if (year != null)
                    _FactTile(
                      icon: Icons.history_edu_outlined,
                      label: 'Founded',
                      value: '$year',
                    ),
                ],
              ),
            ),
          ),
        if (policy != null)
          SliverToBoxAdapter(
            child: _InfoBlock(
              icon: Icons.assignment_return_outlined,
              title: 'Returns',
              body: policy,
            ),
          ),
        if (support != null)
          SliverToBoxAdapter(
            child: _InfoBlock(
              icon: Icons.support_agent_rounded,
              title: 'Customer support',
              body: 'Get help from ${profile.name} at ${support.host}',
              trailing: Icons.open_in_new_rounded,
              semanticLabel:
                  'Customer support, opens ${support.host} in your browser',
              onTap: () => unawaited(_openSupport(context, ref, support)),
            ),
          ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsetsDirectional.only(top: DesignTokens.s32),
            child: MallSectionHeader(title: 'Shop with confidence'),
          ),
        ),
        SliverToBoxAdapter(
          child: MallTrustStrip(items: brandTrustItems(profile)),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.s40)),
      ],
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, $value',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 132),
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          boxShadow: DesignTokens.shadowCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: DesignTokens.textMuted),
            const SizedBox(height: DesignTokens.s8),
            MallEyebrow(label),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: DesignTokens.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.icon,
    required this.title,
    required this.body,
    this.trailing,
    this.semanticLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final IconData? trailing;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(DesignTokens.cardRadius);
    final end = trailing;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        0,
      ),
      child: Semantics(
        button: onTap != null,
        label: semanticLabel ?? '$title. $body',
        excludeSemantics: true,
        child: Material(
          color: DesignTokens.surfaceRaised,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 22, color: DesignTokens.textLight),
                  const SizedBox(width: DesignTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            color: DesignTokens.textWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                            color: DesignTokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (end != null) ...[
                    const SizedBox(width: DesignTokens.s8),
                    Icon(end, size: 18, color: DesignTokens.textMuted),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
