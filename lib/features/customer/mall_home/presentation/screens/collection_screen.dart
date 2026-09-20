import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_navigation.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_view_mappers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/notifiers/collection_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/mall_page_chrome.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/widgets/saveable_product_card.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// `/collections/:slug` — an editorial collection (cover, story, product
/// grid) or a look ("Shop the look": numbered markers on the cover and the
/// pieces listed in the same order). Items page in as the viewer scrolls.
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({required this.slug, super.key, this.heroTag});

  final String slug;

  /// Shared element this screen's cover flies from, when it was opened from
  /// a tagged image such as the Mall's campaign hero. Null on a deep link.
  final String? heroTag;

  /// Start the next page this close to the end.
  static const double loadMoreExtent = 900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = collectionNotifierProvider(slug);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: Stack(
        fit: StackFit.expand,
        children: [
          state.when(
            initial: () => _CollectionSkeleton(heroTag: heroTag),
            loadInProgress: () => _CollectionSkeleton(heroTag: heroTag),
            loadFailure: (failure) => SafeArea(
              child: SmErrorView(
                message: failure.isNotFound
                    ? 'This collection is no longer available.'
                    : failure.isNoInternet
                    ? 'No internet connection.'
                    : "Couldn't load this collection. Please try again.",
                onRetry: failure.isNotFound
                    ? null
                    : () => unawaited(notifier.load()),
              ),
            ),
            loadSuccess: (data) => NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                final metrics = notification.metrics;
                if (notification.depth == 0 &&
                    metrics.axis == Axis.vertical &&
                    metrics.extentAfter < loadMoreExtent &&
                    data.hasMore &&
                    !data.isLoadingMore &&
                    !data.loadMoreFailed) {
                  unawaited(notifier.loadMore());
                }
                return false;
              },
              child: _CollectionBody(
                data: data,
                heroTag: heroTag,
                onRetryMore: () => unawaited(notifier.loadMore()),
              ),
            ),
          ),
          const MallBackButton(),
        ],
      ),
    );
  }
}

/// Wraps [child] in a shared-element flight when the screen was opened from
/// a tagged image. Without a tag nothing changes.
class _CoverHero extends StatelessWidget {
  const _CoverHero({required this.tag, required this.child});

  final String? tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final heroTag = tag;
    if (heroTag == null) return child;
    return Hero(tag: heroTag, child: child);
  }
}

class _CollectionBody extends StatelessWidget {
  const _CollectionBody({
    required this.data,
    required this.heroTag,
    required this.onRetryMore,
  });

  final CollectionViewData data;
  final String? heroTag;
  final VoidCallback onRetryMore;

  static const TextStyle _descriptionStyle = DesignTokens.editorialBody;

  @override
  Widget build(BuildContext context) {
    final collection = data.collection;
    final description = collection.description;
    final owner = collection.ownerDisplayName;
    final count = collection.itemCount > 0
        ? collection.itemCount
        : data.items.length;
    final meta = [
      if (count > 0) MallStrings.of(context).itemCount(count),
      if (owner != null) 'Curated by $owner',
    ].join(' · ');
    void openProduct(String id) =>
        unawaited(context.push(MallRoutes.product(id)));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _CollectionCover(
            data: data,
            heroTag: heroTag,
            onOpenProduct: openProduct,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description != null) ...[
                  Text(description, style: _descriptionStyle),
                  const SizedBox(height: DesignTokens.s12),
                ],
                if (meta.isNotEmpty)
                  Text(meta, style: DesignTokens.smallRegular),
              ],
            ),
          ),
        ),
        if (data.items.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsDirectional.only(top: DesignTokens.s24),
              child: MallEmptyState(
                icon: Icons.checkroom_outlined,
                title: 'Nothing here yet',
                body:
                    'The pieces in this collection are not available '
                    'right now.',
              ),
            ),
          )
        else if (collection.isLook) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsDirectional.only(top: DesignTokens.s32),
              child: MallSectionHeader(title: 'Shop the look'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
            sliver: SliverList.separated(
              itemCount: data.items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: DesignTokens.s16),
              itemBuilder: (context, index) => _LookItemRow(
                number: index + 1,
                item: data.items[index],
                onTap: () => openProduct(data.items[index].product.id),
              ),
            ),
          ),
        ] else ...[
          const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.s24)),
          SaveableSliverProductGrid(
            products: [for (final item in data.items) item.product.toVm()],
            onProductTap: (product) => openProduct(product.id),
          ),
        ],
        SliverToBoxAdapter(
          child: MallPagingFooter(
            isLoading: data.isLoadingMore,
            failed: data.loadMoreFailed,
            onRetry: onRetryMore,
          ),
        ),
      ],
    );
  }
}

/// Cover image with the editorial copy; on a look, numbered markers where
/// the curator pinned each piece.
class _CollectionCover extends StatelessWidget {
  const _CollectionCover({
    required this.data,
    required this.heroTag,
    required this.onOpenProduct,
  });

  final CollectionViewData data;
  final String? heroTag;
  final ValueChanged<String> onOpenProduct;

  static const TextStyle _subtitleStyle = DesignTokens.editorialBody;

  static const double _marker = DesignTokens.minTouchTarget;

  @override
  Widget build(BuildContext context) {
    final collection = data.collection;
    final subtitle = collection.subtitle;
    final screenHeight = MediaQuery.sizeOf(context).height;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // 4:5, the cover aspect markers are placed against; capped on tall
        // tablets so the copy stays near the fold.
        final height = math.min(width * 5 / 4, screenHeight * 0.75);
        final markers = collection.isLook
            ? [
                for (final (index, item) in data.items.indexed)
                  if (item.positionX case final x?)
                    if (item.positionY case final y?)
                      (number: index + 1, x: x, y: y, item: item),
              ]
            : const <({int number, double x, double y, CollectionItem item})>[];
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeSemantics(
                child: _CoverHero(
                  tag: heroTag,
                  child: MallNetworkImage(url: collection.coverImageUrl),
                ),
              ),
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: DesignTokens.imageScrimTop,
                  ),
                ),
              ),
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: DesignTokens.imageScrim),
                ),
              ),
              PositionedDirectional(
                start: 20,
                end: 20,
                bottom: 24,
                child: IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MallEyebrow(
                        collectionEyebrow(collection.kind),
                        color: DesignTokens.textLight,
                      ),
                      const SizedBox(height: DesignTokens.s12),
                      Semantics(
                        header: true,
                        child: Text(
                          collection.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: DesignTokens.displayTitle,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: DesignTokens.s8),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _subtitleStyle,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Positions are fractions of the image itself, so they are
              // placed from the physical left in every text direction.
              for (final marker in markers)
                Positioned(
                  left: (marker.x * width - _marker / 2)
                      .clamp(4, width - _marker - 4)
                      .toDouble(),
                  top: (marker.y * height - _marker / 2)
                      .clamp(4, height - _marker - 4)
                      .toDouble(),
                  child: _LookMarker(
                    number: marker.number,
                    name: marker.item.product.name,
                    onTap: () => onOpenProduct(marker.item.product.id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LookMarker extends StatelessWidget {
  const _LookMarker({
    required this.number,
    required this.name,
    required this.onTap,
  });

  final int number;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Piece $number, $name',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: DesignTokens.minTouchTarget,
          child: Center(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: DesignTokens.textWhite,
                shape: BoxShape.circle,
                boxShadow: DesignTokens.shadowLifted,
              ),
              child: SizedBox.square(
                dimension: 28,
                child: Center(
                  child: Text(
                    '$number',
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: DesignTokens.textDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A piece of a look, numbered to match its marker on the cover.
///
/// This was a privately built row — its own number, its own 72×90 product
/// photo, its own four text styles — that drifted from every other product
/// row in the app and put a catalogue photo on a page that is not product
/// detail. It is `MallResultRow` now: same rank, same ground, same price
/// rhythm as a search hit, and the stylist's note rides in the footer.
class _LookItemRow extends StatelessWidget {
  const _LookItemRow({
    required this.number,
    required this.item,
    required this.onTap,
  });

  final int number;
  final CollectionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final note = item.note;
    return MallResultRow(
      product: item.product.toVm(),
      rank: number,
      onTap: onTap,
      semanticExtras: [?note],
      footer: note == null
          ? null
          : ExcludeSemantics(
              child: Text(
                note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: DesignTokens.smallDescription,
              ),
            ),
    );
  }
}

class _CollectionSkeleton extends StatelessWidget {
  const _CollectionSkeleton({this.heroTag});

  /// The skeleton owns the cover slot until the real cover arrives, so it
  /// carries the tag — otherwise a flight would have nothing to land on.
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Semantics(
      container: true,
      label: MallStrings.of(context).loading,
      child: LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _CoverHero(
              tag: heroTag,
              child: SmSkeleton.box(
                height: math.min(
                  constraints.maxWidth * 5 / 4,
                  screenHeight * 0.75,
                ),
                radius: 0,
              ),
            ),
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SmSkeleton.line(width: 240, height: 14),
                  SizedBox(height: DesignTokens.s8),
                  SmSkeleton.line(width: 160, height: 14),
                ],
              ),
            ),
            const MallProductGrid(
              products: [],
              isLoading: true,
              skeletonCount: 4,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
            ),
          ],
        ),
      ),
    );
  }
}
