import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_navigation.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/mall_choice_chip.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/widgets/saveable_product_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_collection.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/repositories/storefront_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/notifiers/storefront_paged_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/storefront_view_mappers.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_collection_cards.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_reel_grid.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_states.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/creator_shop_product.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/presentation/creator_shop_view.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/product_reel_vm.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The tabs of a creator storefront, in order.
enum CreatorStorefrontTab {
  home('Home'),
  reels('Reels'),
  shop('Shop'),
  collections('Collections'),
  looks('Looks');

  const CreatorStorefrontTab(this.label);

  final String label;
}

extension CreatorShopProductToVm on CreatorShopProduct {
  MallProductVm toVm() => MallProductVm(
    id: productId,
    name: name,
    price: price,
    brandName: vendorDisplayName.trim().isEmpty ? null : vendorDisplayName,
    imageUrl: imageUrl,
    reel: reel?.toVm(),
  );
}

const TextStyle _countStyle = TextStyle(
  fontFamily: DesignTokens.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 1.4,
  color: DesignTokens.textMuted,
);

void _openReel(BuildContext context, StorefrontReel reel) =>
    unawaited(context.push(MallRoutes.reel(reel.id)));

void _openCollection(BuildContext context, StorefrontCollection collection) =>
    unawaited(context.push(MallRoutes.collection(collection.slug)));

void _openProduct(BuildContext context, String productId) =>
    unawaited(context.push(MallRoutes.product(productId)));

String _plural(int count, String one, String many) =>
    count == 1 ? '1 $one' : '${formatCompactNumber(count)} $many';

// ── Home ────────────────────────────────────────────────────────────────────

/// Latest reels, the creator's picks, a featured collection and looks.
class CreatorHomeTab extends ConsumerWidget {
  const CreatorHomeTab({
    required this.accountId,
    required this.displayName,
    required this.firstName,
    required this.onOpenTab,
    super.key,
  });

  final String accountId;
  final String displayName;
  final String firstName;
  final ValueChanged<CreatorStorefrontTab> onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reelsProvider = creatorReelsProvider((
      accountId: accountId,
      sort: CreatorReelSort.latest,
    ));
    final reels = ref.watch(reelsProvider);
    final shop = ref.watch(creatorShopProvider(accountId));
    final collections = ref.watch(
      storefrontCollectionsProvider(creatorCollectionsKey(accountId)),
    );
    final looks = ref.watch(
      storefrontCollectionsProvider(creatorLooksKey(accountId)),
    );
    final all = <StorefrontPagedState<Object>>[reels, shop, collections, looks];

    if (all.every((state) => state is StorefrontPagedFailure)) {
      return SliverMainAxisGroup(
        slivers: [
          StorefrontSliverMessage.failure(
            (reels as StorefrontPagedFailure<StorefrontReel>).failure,
            onRetry: () {
              unawaited(ref.read(reelsProvider.notifier).refresh());
              unawaited(
                ref.read(creatorShopProvider(accountId).notifier).refresh(),
              );
              unawaited(
                ref
                    .read(
                      storefrontCollectionsProvider(
                        creatorCollectionsKey(accountId),
                      ).notifier,
                    )
                    .refresh(),
              );
              unawaited(
                ref
                    .read(
                      storefrontCollectionsProvider(
                        creatorLooksKey(accountId),
                      ).notifier,
                    )
                    .refresh(),
              );
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
            icon: Icons.auto_awesome_outlined,
            title: 'A new style universe is taking shape',
            body:
                "$firstName hasn't shared reels, picks or looks yet. "
                'Follow to see them first.',
          ),
        ],
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        ..._reelsSection(context, reels),
        ..._shopSection(context, shop),
        ..._featuredSection(context, collections),
        ..._looksSection(context, looks),
        const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.s40)),
      ],
    );
  }

  List<Widget> _reelsSection(
    BuildContext context,
    StorefrontPagedState<StorefrontReel> state,
  ) {
    const width = MallReelCard.compactWidth;
    final height = MallReelCard.heightFor(width);
    final header = StorefrontSliverHeader(
      eyebrow: 'Fresh from the feed',
      title: 'Latest reels',
      onSeeAll: () => onOpenTab(CreatorStorefrontTab.reels),
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
            semanticLabel: 'Latest reels',
            itemBuilder: (context, reel, _) => MallReelCard(
              reel: reel.toVm(fallbackCreatorName: displayName),
              onTap: () => _openReel(context, reel),
            ),
          ),
        ),
      ],
      _ => const [],
    };
  }

  List<Widget> _shopSection(
    BuildContext context,
    StorefrontPagedState<CreatorShopProduct> state,
  ) {
    const width = MallProductTile.compactWidth;
    final height = MallProductTile.heightFor(
      context,
      width: width,
      size: MallCardSize.compact,
    );
    final header = StorefrontSliverHeader(
      eyebrow: 'Tagged in reels',
      title: "Shop $firstName's picks",
      onSeeAll: () => onOpenTab(CreatorStorefrontTab.shop),
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
          child: MallRail<CreatorShopProduct>(
            items: items.take(12).toList(growable: false),
            itemWidth: width,
            height: height,
            semanticLabel: "$firstName's picks",
            itemBuilder: (context, product, _) => SaveableMallProductTile(
              product: product.toVm(),
              size: MallCardSize.compact,
              onTap: () => _openProduct(context, product.productId),
              onReelTap: (reel) =>
                  unawaited(context.push(MallRoutes.reel(reel.reelId))),
            ),
          ),
        ),
      ],
      _ => const [],
    };
  }

  List<Widget> _featuredSection(
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
        eyebrow: 'Curated by $firstName',
        title: 'Featured collection',
        onSeeAll: state.items.length > 1
            ? () => onOpenTab(CreatorStorefrontTab.collections)
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

  List<Widget> _looksSection(
    BuildContext context,
    StorefrontPagedState<StorefrontCollection> state,
  ) {
    if (state is! StorefrontPagedLoaded<StorefrontCollection> ||
        state.items.isEmpty) {
      return const [];
    }
    const width = StorefrontLookCard.railWidth;
    return [
      StorefrontSliverHeader(
        eyebrow: 'Styled by $firstName',
        title: 'Looks',
        onSeeAll: () => onOpenTab(CreatorStorefrontTab.looks),
      ),
      SliverToBoxAdapter(
        child: MallRail<StorefrontCollection>(
          items: state.items.take(8).toList(growable: false),
          itemWidth: width,
          height: width / StorefrontLookCard.aspectRatio,
          semanticLabel: 'Looks',
          itemBuilder: (context, look, _) => StorefrontLookCard(
            look: look,
            onTap: () => _openCollection(context, look),
          ),
        ),
      ),
    ];
  }
}

// ── Reels ───────────────────────────────────────────────────────────────────

/// The creator's reels as a 9:16 grid, latest or most popular first.
class CreatorReelsTab extends ConsumerWidget {
  const CreatorReelsTab({
    required this.accountId,
    required this.firstName,
    required this.sort,
    required this.onSortChanged,
    super.key,
  });

  final String accountId;
  final String firstName;
  final CreatorReelSort sort;
  final ValueChanged<CreatorReelSort> onSortChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = creatorReelsProvider((accountId: accountId, sort: sort));
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final count = switch (state) {
      StorefrontPagedLoaded(:final items, :final totalCount) => _plural(
        totalCount ?? items.length,
        'reel',
        'reels',
      ),
      _ => '',
    };

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              top: DesignTokens.s16,
              bottom: DesignTokens.s8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (count.isNotEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: DesignTokens.s16,
                    ),
                    child: Text(count, style: _countStyle),
                  ),
                StorefrontChipRow(
                  children: [
                    for (final option in CreatorReelSort.values)
                      MallChoiceChip(
                        label: option == CreatorReelSort.latest
                            ? 'Latest'
                            : 'Popular',
                        selected: option == sort,
                        onTap: () => onSortChanged(option),
                      ),
                  ],
                ),
              ],
            ),
          ),
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
              title: 'No reels yet',
              body: 'When $firstName shares a reel, it lands here first.',
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

// ── Shop ────────────────────────────────────────────────────────────────────

/// Products tagged in the creator's reels, filterable by brand.
class CreatorShopTab extends ConsumerWidget {
  const CreatorShopTab({
    required this.accountId,
    required this.firstName,
    required this.sort,
    required this.brandKey,
    required this.onSortChanged,
    required this.onBrandChanged,
    super.key,
  });

  final String accountId;
  final String firstName;
  final CreatorShopSort sort;

  /// Selected brand, or null for all brands.
  final String? brandKey;
  final ValueChanged<CreatorShopSort> onSortChanged;
  final ValueChanged<String?> onBrandChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = creatorShopProvider(accountId);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return SliverMainAxisGroup(
      slivers: switch (state) {
        StorefrontPagedLoading() => const [
          SliverToBoxAdapter(child: SizedBox(height: DesignTokens.s16)),
          MallSliverProductGrid(products: [], isLoading: true),
        ],
        StorefrontPagedFailure(:final failure) => [
          StorefrontSliverMessage.failure(
            failure,
            onRetry: () => unawaited(notifier.refresh()),
          ),
        ],
        StorefrontPagedLoaded() when state.isEmpty => [
          StorefrontSliverMessage(
            icon: Icons.shopping_bag_outlined,
            title: 'Shop coming soon',
            body:
                "$firstName hasn't tagged any pieces in reels yet. "
                'Follow to catch the first drop.',
          ),
        ],
        final StorefrontPagedLoaded<CreatorShopProduct> loaded => _loaded(
          context,
          loaded,
          notifier,
        ),
      },
    );
  }

  List<Widget> _loaded(
    BuildContext context,
    StorefrontPagedLoaded<CreatorShopProduct> loaded,
    StorefrontPagedNotifier<CreatorShopProduct> notifier,
  ) {
    final brands = creatorShopBrands(loaded.items);
    final selected = brands.any((brand) => brand.key == brandKey)
        ? brandKey
        : null;
    final visible = creatorShopView(
      loaded.items,
      brandKey: selected,
      sort: sort,
    );
    final total = loaded.items.length;
    final pieces =
        '${_plural(total, 'piece', 'pieces')}'
        '${loaded.hasMore ? '+' : ''} tagged in reels';

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            DesignTokens.s16,
            DesignTokens.s16,
            DesignTokens.s16,
            DesignTokens.s4,
          ),
          child: Text(pieces, style: _countStyle),
        ),
      ),
      SliverToBoxAdapter(
        child: StorefrontChipRow(
          children: [
            for (final option in CreatorShopSort.values)
              MallChoiceChip(
                label: option.label,
                selected: option == sort,
                onTap: () => onSortChanged(option),
              ),
          ],
        ),
      ),
      if (brands.length > 1)
        SliverToBoxAdapter(
          child: StorefrontChipRow(
            children: [
              MallChoiceChip(
                label: 'All · $total',
                semanticLabel: 'All brands, $total pieces',
                selected: selected == null,
                onTap: () => onBrandChanged(null),
              ),
              for (final brand in brands)
                MallChoiceChip(
                  label: '${brand.name} · ${brand.count}',
                  semanticLabel: _brandChipSemantics(brand),
                  selected: brand.key == selected,
                  onTap: () => onBrandChanged(brand.key),
                ),
            ],
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.s12)),
      MallSliverProductGrid(
        products: [for (final product in visible) product.toVm()],
        onProductTap: (product) => _openProduct(context, product.id),
        onReelTap: (_, reel) =>
            unawaited(context.push(MallRoutes.reel(reel.reelId))),
      ),
      StorefrontSliverPagingFooter(
        state: loaded,
        onRetry: () => unawaited(notifier.retryLoadMore()),
      ),
    ];
  }
}

String _brandChipSemantics(CreatorShopBrand brand) =>
    '${brand.name}, ${_plural(brand.count, 'piece', 'pieces')}';

// ── Collections and looks ───────────────────────────────────────────────────

/// The creator's collections (wide cards) or looks (tall cards).
class CreatorCollectionsTab extends ConsumerWidget {
  const CreatorCollectionsTab({
    required this.accountId,
    required this.firstName,
    required this.looks,
    super.key,
  });

  final String accountId;
  final String firstName;

  /// Looks instead of collections.
  final bool looks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = storefrontCollectionsProvider(
      looks ? creatorLooksKey(accountId) : creatorCollectionsKey(accountId),
    );
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.s16)),
        ...switch (state) {
          StorefrontPagedLoading() => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: DesignTokens.s16,
                ),
                child: AspectRatio(
                  aspectRatio: looks
                      ? 2 * StorefrontLookCard.aspectRatio
                      : StorefrontSliverCollections.aspectRatio,
                  child: const SmSkeleton.box(radius: DesignTokens.cardRadius),
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
            if (looks)
              StorefrontSliverMessage(
                icon: Icons.checkroom_outlined,
                title: 'No looks yet',
                body:
                    'Looks $firstName styles will show up here, ready to shop.',
              )
            else
              StorefrontSliverMessage(
                icon: Icons.collections_bookmark_outlined,
                title: 'No collections yet',
                body:
                    'When $firstName curates a collection, '
                    "you'll find it here.",
              ),
          ],
          final StorefrontPagedLoaded<StorefrontCollection> loaded => [
            if (looks)
              StorefrontSliverLooks(
                looks: loaded.items,
                onTap: (look) => _openCollection(context, look),
              )
            else
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
