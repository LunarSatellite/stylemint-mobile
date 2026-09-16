import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feed.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feedback.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/discover_feed_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/discover_chip_bar.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/discover_item_actions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/discover_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_navigation.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_view_mappers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/mall_page_chrome.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_window.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Whether [failure] means the device is offline.
bool isOfflineFailure(NetworkExceptions failure) =>
    failure == const NetworkExceptions.noInternetConnection();

/// The chips and the feed under them, with pull to refresh and infinite
/// scroll.
class DiscoverFeedView extends ConsumerStatefulWidget {
  const DiscoverFeedView({super.key});

  /// Start loading the next page this close to the end.
  static const double loadMoreExtent = 800;

  @override
  ConsumerState<DiscoverFeedView> createState() => _DiscoverFeedViewState();
}

class _DiscoverFeedViewState extends ConsumerState<DiscoverFeedView> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  DiscoverFeedNotifier get _notifier =>
      ref.read(discoverFeedNotifierProvider.notifier);

  void _loadMoreIfShort() {
    if (!mounted || !_scroll.hasClients) return;
    if (_scroll.position.extentAfter < DiscoverFeedView.loadMoreExtent) {
      unawaited(_notifier.loadMore());
    }
  }

  void _push(String location) => unawaited(context.push(location));

  void _openActions(NotInterestedKind kind, String id, String label) =>
      unawaited(
        showDiscoverItemActions(
          context,
          ref,
          target: NotInterestedTarget(kind, id),
          itemLabel: label,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverFeedNotifierProvider);
    final hidden = ref.watch(notInterestedNotifierProvider);
    final layout = ref.watch(discoverProductLayoutProvider);
    ref
      ..listen(discoverFeedNotifierProvider.select((s) => s.selected), (
        previous,
        next,
      ) {
        if (previous != next && _scroll.hasClients) _scroll.jumpTo(0);
      })
      ..listen(discoverFeedNotifierProvider.select((s) => s.feed), (_, feed) {
        // A page that doesn't fill the screen can't be scrolled to its end.
        if (feed is DiscoverFeedLoaded && feed.canLoadMore) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _loadMoreIfShort(),
          );
        }
      });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.s8),
          child: DiscoverChipBar(
            chips: state.chips,
            selected: state.selected,
            onSelected: (chip) => unawaited(_notifier.select(chip)),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: DesignTokens.primaryGreen,
            backgroundColor: DesignTokens.surfaceRaised,
            onRefresh: _notifier.refresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.depth == 0 &&
                    notification.metrics.extentAfter <
                        DiscoverFeedView.loadMoreExtent) {
                  unawaited(_notifier.loadMore());
                }
                return false;
              },
              child: CustomScrollView(
                key: const ValueKey('discover-feed'),
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: _slivers(context, state, hidden, layout),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _slivers(
    BuildContext context,
    DiscoverState state,
    Set<NotInterestedTarget> hidden,
    DiscoverProductLayout layout,
  ) {
    final bottomGap = SliverToBoxAdapter(
      child: SizedBox(
        height: DesignTokens.s24 + MediaQuery.paddingOf(context).bottom,
      ),
    );
    switch (state.feed) {
      case DiscoverFeedLoading():
        return [
          const SliverToBoxAdapter(child: _HeaderSkeleton()),
          const MallSliverProductGrid(products: [], isLoading: true),
          bottomGap,
        ];
      case DiscoverFeedFailure(:final failure):
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _FeedMessage.failure(
              failure,
              onRetry: () => unawaited(_notifier.retry()),
            ),
          ),
        ];
      case final DiscoverFeedLoaded feed:
        final slivers = [
          for (final block in feed.blocks)
            ..._blockSlivers(context, block, hidden, layout),
        ];
        if (slivers.isEmpty && !feed.hasMore) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: _FeedMessage.empty(state.selected),
            ),
          ];
        }
        return [
          ...slivers,
          if (feed.hasMore || feed.loadMoreFailed)
            SliverToBoxAdapter(
              child: MallPagingFooter(
                isLoading: feed.isLoadingMore,
                failed: feed.loadMoreFailed,
                onRetry: () => unawaited(_notifier.retryLoadMore()),
              ),
            )
          else
            bottomGap,
        ];
    }
  }

  List<Widget> _blockSlivers(
    BuildContext context,
    DiscoverBlock block,
    Set<NotInterestedTarget> hidden,
    DiscoverProductLayout layout,
  ) {
    final header = SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: DesignTokens.s24),
        child: MallSectionHeader(
          key: ValueKey('discover-block-${block.key}'),
          eyebrow: block.eyebrow,
          title: block.title,
          subtitle: block.subtitle,
        ),
      ),
    );
    switch (block) {
      case DiscoverProductsBlock(:final items, :final isListing):
        final visible = [
          for (final product in items)
            if (!hidden.hidesProduct(product)) product,
        ];
        if (visible.isEmpty) return const [];
        final asList = isListing && layout == DiscoverProductLayout.list;
        return [
          header,
          if (isListing)
            SliverToBoxAdapter(child: _LayoutToggle(layout: layout)),
          if (asList) _productList(visible) else _productGrid(visible),
        ];
      case DiscoverReelsBlock(:final items, layout: final blockLayout):
        final visible = [
          for (final reel in items)
            if (!hidden.hidesReel(reel)) reel,
        ];
        if (visible.isEmpty) return const [];
        return [
          header,
          if (blockLayout == DiscoverLayout.rail)
            SliverToBoxAdapter(
              child: _railGap(
                MallRail<HomeReel>(
                  items: visible,
                  itemWidth: MallReelCard.compactWidth,
                  height: MallReelCard.heightFor(MallReelCard.compactWidth),
                  semanticLabel: block.title,
                  itemBuilder: (context, reel, _) =>
                      _reelCard(reel, inRail: true),
                ),
              ),
            )
          else
            _grid(
              count: visible.length,
              minTileWidth: MallReelCard.compactWidth,
              extentFor: MallReelCard.heightFor,
              builder: (index) => _reelCard(visible[index], inRail: false),
            ),
        ];
      case DiscoverCreatorsBlock(:final items, layout: final blockLayout):
        final visible = [
          for (final creator in items)
            if (!hidden.hidesCreator(creator)) creator,
        ];
        if (visible.isEmpty) return const [];
        final extent = MallCreatorCard.heightFor(
          context,
          hasFollowAction: false,
        );
        return [
          header,
          if (blockLayout == DiscoverLayout.rail)
            SliverToBoxAdapter(
              child: _railGap(
                MallRail<HomeCreator>(
                  items: visible,
                  itemWidth: MallCreatorCard.defaultWidth,
                  height: extent,
                  semanticLabel: block.title,
                  itemBuilder: (context, creator, _) => _creatorCard(creator),
                ),
              ),
            )
          else
            _grid(
              count: visible.length,
              minTileWidth: MallCreatorCard.defaultWidth,
              extentFor: (_) => extent,
              builder: (index) => _creatorCard(visible[index]),
            ),
        ];
      case DiscoverBrandsBlock(:final items, layout: final blockLayout):
        final visible = [
          for (final brand in items)
            if (!hidden.hidesBrand(brand)) brand,
        ];
        if (visible.isEmpty) return const [];
        return [
          header,
          if (blockLayout == DiscoverLayout.rail)
            SliverToBoxAdapter(
              child: _railGap(
                MallRail<HomeBrand>(
                  items: visible,
                  itemWidth: MallBrandCard.defaultWidth,
                  height: MallBrandCard.heightFor(
                    context,
                    width: MallBrandCard.defaultWidth,
                  ),
                  semanticLabel: block.title,
                  itemBuilder: (context, brand, _) => _brandCard(brand),
                ),
              ),
            )
          else
            _grid(
              count: visible.length,
              minTileWidth: MallBrandCard.defaultWidth,
              extentFor: (tileWidth) =>
                  MallBrandCard.heightFor(context, width: tileWidth),
              builder: (index) => _brandCard(visible[index]),
            ),
        ];
      case DiscoverCollectionBlock(:final collection):
        return [
          header,
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              DesignTokens.s16,
              DesignTokens.s12,
              DesignTokens.s16,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final ratio = constraints.maxWidth < 480 ? 1.0 : 16 / 9;
                  return SizedBox(
                    height: MallCollectionCard.heightFor(
                      constraints.maxWidth,
                      aspectRatio: ratio,
                    ),
                    child: _collectionCard(collection, ratio),
                  );
                },
              ),
            ),
          ),
        ];
      case DiscoverCollectionsBlock(:final items):
        return [
          header,
          _grid(
            count: items.length,
            minTileWidth: MallCollectionCard.defaultWidth,
            extentFor: (tileWidth) =>
                MallCollectionCard.heightFor(tileWidth, aspectRatio: 1),
            builder: (index) => _collectionCard(items[index], 1),
          ),
        ];
    }
  }

  Widget _railGap(Widget rail) => Padding(
    padding: const EdgeInsets.only(top: DesignTokens.s12),
    child: rail,
  );

  /// A grid with as many columns of at least [minTileWidth] as fit.
  Widget _grid({
    required int count,
    required double minTileWidth,
    required double Function(double tileWidth) extentFor,
    required Widget Function(int index) builder,
  }) {
    const spacing = DesignTokens.s12;
    return SliverPadding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        0,
      ),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = ((width + spacing) / (minTileWidth + spacing))
              .floor()
              .clamp(1, 4);
          final tileWidth = (width - spacing * (columns - 1)) / columns;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              mainAxisExtent: extentFor(tileWidth),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => builder(index),
              childCount: count,
            ),
          );
        },
      ),
    );
  }

  Widget _productGrid(List<HomeProduct> products) => SliverPadding(
    padding: const EdgeInsetsDirectional.fromSTEB(
      DesignTokens.s16,
      DesignTokens.s12,
      DesignTokens.s16,
      0,
    ),
    sliver: SliverLayoutBuilder(
      builder: (context, constraints) {
        const spacing = DesignTokens.s12;
        final width = constraints.crossAxisExtent;
        final columns = MallProductGrid.columnsFor(width);
        final tileWidth = (width - spacing * (columns - 1)) / columns;
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: DesignTokens.s24,
            mainAxisExtent: MallProductCard.heightFor(
              context,
              width: tileWidth,
            ),
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _productCard(products[index]),
            childCount: products.length,
          ),
        );
      },
    ),
  );

  Widget _productList(List<HomeProduct> products) => SliverPadding(
    padding: const EdgeInsetsDirectional.fromSTEB(
      DesignTokens.s16,
      DesignTokens.s12,
      DesignTokens.s16,
      0,
    ),
    sliver: SliverList.separated(
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.s12),
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductListTile(
          key: ValueKey('discover-product-${product.id}'),
          product: product,
          onTap: () => _push(MallRoutes.product(product.id)),
          onMore: () => _openActions(
            NotInterestedKind.product,
            product.id,
            product.name,
          ),
        );
      },
    ),
  );

  Widget _productCard(HomeProduct product) => DiscoverActionable(
    key: ValueKey('discover-product-${product.id}'),
    itemLabel: product.name,
    onMore: () =>
        _openActions(NotInterestedKind.product, product.id, product.name),
    child: MallProductCard(
      product: product.toVm(),
      onTap: () => _push(MallRoutes.product(product.id)),
    ),
  );

  /// One reel in a Discover block.
  ///
  /// [inRail] decides how it opens, and the two are genuinely different
  /// surfaces. A rail is a peek beside other blocks — a row of play marks —
  /// so it plays in the window over Discover, like a product tile's reel.
  /// The block's grid is the feed's own wall of reels, paged as you scroll:
  /// tapping one there enters the full-screen pager and keeps the swipe to
  /// the next reel that a wall of reels promises, so it stays a push.
  Widget _reelCard(HomeReel reel, {required bool inRail}) {
    final label = 'Reel by ${reel.toVm().creatorName}';
    return DiscoverActionable(
      key: ValueKey('discover-reel-${reel.id}'),
      itemLabel: label,
      onMore: () => _openActions(NotInterestedKind.reel, reel.id, label),
      child: MallReelCard(
        reel: reel.toVm(),
        onTap: inRail
            ? () => unawaited(openMallReelWindow(context, reel.toRef()))
            : () => _push(MallRoutes.reel(reel.id)),
      ),
    );
  }

  Widget _creatorCard(HomeCreator creator) => DiscoverActionable(
    key: ValueKey('discover-creator-${creator.accountId}'),
    itemLabel: creator.displayName,
    onMore: () => _openActions(
      NotInterestedKind.creator,
      creator.accountId,
      creator.displayName,
    ),
    child: MallCreatorCard(
      creator: creator.toVm(),
      onTap: () => _push(MallRoutes.creator(creator.accountId)),
    ),
  );

  Widget _brandCard(HomeBrand brand) => DiscoverActionable(
    key: ValueKey('discover-brand-${brand.vendorAccountId}'),
    itemLabel: brand.name,
    onMore: () => _openActions(
      NotInterestedKind.brand,
      brand.vendorAccountId,
      brand.name,
    ),
    child: MallBrandCard(
      brand: brand.toVm(),
      onTap: () => _push(MallRoutes.brand(brand.vendorAccountId, brand.name)),
    ),
  );

  Widget _collectionCard(HomeCollection collection, double ratio) =>
      MallCollectionCard(
        key: ValueKey('discover-collection-${collection.slug}'),
        collection: collection.toVm(),
        aspectRatio: ratio,
        onTap: () => _push(MallRoutes.collection(collection.slug)),
      );
}

/// Grid or list for product results.
class _LayoutToggle extends ConsumerWidget {
  const _LayoutToggle({required this.layout});

  final DiscoverProductLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget option(DiscoverProductLayout value, IconData icon, String label) {
      final selected = layout == value;
      return Semantics(
        selected: selected,
        child: IconButton(
          key: ValueKey('discover-layout-${value.name}'),
          tooltip: label,
          isSelected: selected,
          color: selected ? DesignTokens.textWhite : DesignTokens.textMuted,
          icon: Icon(icon),
          onPressed: () =>
              ref.read(discoverProductLayoutProvider.notifier).state = value,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: DesignTokens.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          option(
            DiscoverProductLayout.grid,
            Icons.grid_view_rounded,
            'Grid view',
          ),
          option(
            DiscoverProductLayout.list,
            Icons.view_agenda_outlined,
            'List view',
          ),
        ],
      ),
    );
  }
}

/// A product row for the list layout: photo, brand, name and price.
class _ProductListTile extends StatelessWidget {
  const _ProductListTile({
    required this.product,
    required this.onTap,
    required this.onMore,
    super.key,
  });

  final HomeProduct product;
  final VoidCallback onTap;
  final VoidCallback onMore;

  static const TextStyle _brandStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12,
    height: 1.3,
    color: DesignTokens.textMuted,
  );
  static const TextStyle _nameStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: DesignTokens.textWhite,
  );
  static const TextStyle _priceStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: DesignTokens.textWhite,
  );

  @override
  Widget build(BuildContext context) {
    final vm = product.toVm();
    final discount = vm.discountPercent;
    final compareAt = discount == null ? null : vm.compareAtPrice;
    final price = formatMoney(product.price, decimalDigits: 0);
    final was = compareAt == null
        ? null
        : formatMoney(compareAt, decimalDigits: 0);
    final brand = product.brandName;
    final label = [
      ?brand,
      product.name,
      price,
      if (was != null) 'was $was',
      if (discount != null) '$discount% off',
    ].join(', ');

    return Material(
      color: DesignTokens.surfaceRaised,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: label,
              excludeSemantics: true,
              child: InkWell(
                onTap: onTap,
                onLongPress: onMore,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 96,
                      child: AspectRatio(
                        aspectRatio: MallProductCard.imageAspectRatio,
                        child: MallNetworkImage(url: product.imageUrl),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          DesignTokens.s12,
                          DesignTokens.s12,
                          0,
                          DesignTokens.s12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (brand != null)
                              Text(
                                brand,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _brandStyle,
                              ),
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _nameStyle,
                            ),
                            const SizedBox(height: DesignTokens.s8),
                            Wrap(
                              spacing: DesignTokens.s8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(price, style: _priceStyle),
                                if (was != null)
                                  Text(
                                    was,
                                    style: _brandStyle.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                if (discount != null)
                                  Text(
                                    '-$discount%',
                                    style: _brandStyle.copyWith(
                                      color: DesignTokens.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          DiscoverMoreButton(
            label: 'More options for ${product.name}',
            onTap: onMore,
          ),
        ],
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        DesignTokens.s16,
        DesignTokens.s24,
        DesignTokens.s16,
        DesignTokens.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmSkeleton.line(width: 72),
          SizedBox(height: DesignTokens.s8),
          SmSkeleton.line(width: 180, height: 22),
        ],
      ),
    );
  }
}

/// A full-height empty, error or offline message.
class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.title,
    required this.body,
    required this.icon,
    super.key,
    this.eyebrow,
    this.onRetry,
  });

  factory _FeedMessage.failure(
    NetworkExceptions failure, {
    required VoidCallback onRetry,
  }) => isOfflineFailure(failure)
      ? _FeedMessage(
          key: const ValueKey('discover-feed-offline'),
          eyebrow: 'Offline',
          title: "You're offline",
          body: 'Check your connection, then try again.',
          icon: Icons.wifi_off_rounded,
          onRetry: onRetry,
        )
      : _FeedMessage(
          key: const ValueKey('discover-feed-error'),
          title: "We couldn't load this",
          body: 'Something went wrong on our side. Try again in a moment.',
          icon: Icons.error_outline_rounded,
          onRetry: onRetry,
        );

  factory _FeedMessage.empty(DiscoverChip chip) {
    final (title, body) = switch (chip) {
      DiscoverKindChip(kind: DiscoverFeedKind.sale) => (
        'No sales right now',
        'New offers land often. Check back soon.',
      ),
      DiscoverKindChip(kind: DiscoverFeedKind.reels) => (
        'No reels yet',
        'Shoppable reels from creators will show up here.',
      ),
      DiscoverKindChip(kind: DiscoverFeedKind.creators) => (
        'No creators yet',
        'Creators you can shop from will show up here.',
      ),
      DiscoverKindChip(kind: DiscoverFeedKind.brands) => (
        'No brands yet',
        'Verified brands will show up here.',
      ),
      DiscoverKindChip(kind: DiscoverFeedKind.collections) => (
        'No collections yet',
        'Our editors are putting new edits together.',
      ),
      DiscoverCategoryChip(:final category) => (
        'Nothing in ${category.name} yet',
        'Try another category.',
      ),
      DiscoverKindChip() => ('Nothing here yet', 'Pull down to refresh.'),
    };
    return _FeedMessage(
      key: const ValueKey('discover-feed-empty'),
      title: title,
      body: body,
      icon: Icons.auto_awesome_outlined,
    );
  }

  final String title;
  final String body;
  final IconData icon;
  final String? eyebrow;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.s24),
      child: Center(
        child: MallEmptyState(
          eyebrow: eyebrow,
          title: title,
          body: body,
          icon: icon,
          actionLabel: onRetry == null ? null : 'Try again',
          onAction: onRetry,
        ),
      ),
    );
  }
}
