import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_navigation.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_view_mappers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/notifiers/product_listing_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/active_filter_chips.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/mall_choice_chip.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/mall_page_chrome.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/product_filter_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_window.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/widgets/saveable_product_card.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// `/products` — the public product listing: sort chips, a filter sheet and
/// an infinitely scrolling grid. Opened from Home "See all", brands and
/// categories with the filters in the query.
class ProductListingScreen extends ConsumerWidget {
  const ProductListingScreen({required this.query, super.key, this.title});

  /// The filters the screen opened with.
  final ProductListingQuery query;
  final String? title;

  /// Start the next page this close to the end.
  static const double loadMoreExtent = 800;

  static String headingFor(ProductListingQuery query, String? title) {
    final name = title?.trim();
    if (name != null && name.isNotEmpty) return name;
    final search = query.search;
    if (search != null) return '"$search"';
    return query.onSale ? 'Deals' : 'Shop all';
  }

  Future<void> _openFilters(
    BuildContext context,
    WidgetRef ref,
    ProductListingQuery current,
  ) async {
    final chosen = await showProductFilterSheet(context, current);
    if (chosen == null || chosen == current || !context.mounted) return;
    final notifier = ref.read(productListingNotifierProvider(query).notifier);
    unawaited(notifier.applyQuery(chosen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = productListingNotifierProvider(query);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final active = state.activeQuery;

    final countText = state.maybeWhen(
      loadSuccess: (data) {
        final total = data.totalCount ?? data.products.length;
        return total == 1 ? '1 product' : '$total products';
      },
      orElse: () => '',
    );
    final canLoadMore = state.maybeWhen(
      loadSuccess: (data) =>
          data.hasMore && !data.isLoadingMore && !data.loadMoreFailed,
      orElse: () => false,
    );

    final body = state.when<List<Widget>>(
      initial: (_) => const [
        MallSliverProductGrid(products: [], isLoading: true),
      ],
      loadInProgress: (_) => const [
        MallSliverProductGrid(products: [], isLoading: true),
      ],
      loadFailure: (_, failure) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: SmErrorView(
            message: failure.isNoInternet
                ? 'No internet connection.'
                : "Couldn't load products. Please try again.",
            onRetry: () => unawaited(notifier.load()),
          ),
        ),
      ],
      loadSuccess: (data) {
        if (data.products.isEmpty) {
          final filtered = data.query.activeFilterCount > 0;
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: MallEmptyState(
                icon: Icons.search_off_rounded,
                title: filtered
                    ? 'No products match these filters'
                    : 'No products here yet',
                body: filtered
                    ? 'Try a wider price range or fewer filters.'
                    : 'Check back soon for new pieces.',
                actionLabel: filtered ? 'Clear filters' : null,
                onAction: filtered
                    ? () => unawaited(
                        notifier.applyQuery(data.query.clearFilters()),
                      )
                    : null,
              ),
            ),
          ];
        }
        return [
          SaveableSliverProductGrid(
            products: [for (final product in data.products) product.toVm()],
            onProductTap: (product) =>
                unawaited(context.push(MallRoutes.product(product.id))),
            onReelTap: (_, reel) =>
                unawaited(openMallReelWindow(context, reel)),
          ),
          SliverToBoxAdapter(
            child: MallPagingFooter(
              isLoading: data.isLoadingMore,
              failed: data.loadMoreFailed,
              onRetry: () => unawaited(notifier.loadMore()),
            ),
          ),
        ];
      },
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        bottom: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            final metrics = notification.metrics;
            if (canLoadMore &&
                notification.depth == 0 &&
                metrics.axis == Axis.vertical &&
                metrics.extentAfter < loadMoreExtent) {
              unawaited(notifier.loadMore());
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _TopBar(
                  filterCount: active.activeFilterCount,
                  onFilters: () =>
                      unawaited(_openFilters(context, ref, active)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          headingFor(query, title),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: DesignTokens.displayTitle,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s4),
                      Text(countText, style: DesignTokens.smallRegular),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _SortChips(
                  selected: active.sort,
                  onSelected: (sort) {
                    if (sort == active.sort) return;
                    unawaited(notifier.applyQuery(active.withSort(sort)));
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: ActiveFilterChips(
                  query: active,
                  onChanged: (next) => unawaited(notifier.applyQuery(next)),
                ),
              ),
              ...body,
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.filterCount, required this.onFilters});

  final int filterCount;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: context.popOrHome,
            constraints: const BoxConstraints.tightFor(
              width: DesignTokens.minTouchTarget,
              height: DesignTokens.minTouchTarget,
            ),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: DesignTokens.textWhite,
            ),
          ),
          const Spacer(),
          _FilterButton(count: filterCount, onTap: onFilters),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: count == 0 ? 'Filter' : 'Filter, $count applied',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: DesignTokens.minTouchTarget,
          ),
          padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 16, 0),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceRaised,
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 18,
                color: DesignTokens.textWhite,
              ),
              const SizedBox(width: DesignTokens.s8),
              const Text(
                'Filter',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textWhite,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: DesignTokens.s8),
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: DesignTokens.textWhite,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 20,
                    child: Center(
                      child: Text(
                        '$count',
                        textScaler: TextScaler.noScaling,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: DesignTokens.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SortChips extends StatelessWidget {
  const _SortChips({required this.selected, required this.onSelected});

  final ProductSort selected;
  final ValueChanged<ProductSort> onSelected;

  static const List<(ProductSort, String, String)> options = [
    (ProductSort.newest, 'Newest', 'Newest'),
    (ProductSort.bestselling, 'Best selling', 'Best selling'),
    (ProductSort.rating, 'Top rated', 'Top rated'),
    (ProductSort.priceAsc, 'Price ↑', 'Price, low to high'),
    (ProductSort.priceDesc, 'Price ↓', 'Price, high to low'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      child: Row(
        children: [
          for (final (index, (sort, label, spoken)) in options.indexed) ...[
            if (index > 0) const SizedBox(width: DesignTokens.s8),
            MallChoiceChip(
              label: label,
              semanticLabel: spoken,
              selected: sort == selected,
              onTap: () => onSelected(sort),
            ),
          ],
        ],
      ),
    );
  }
}
