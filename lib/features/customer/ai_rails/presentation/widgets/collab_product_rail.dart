import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/domain/entities/ai_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/pdp_bleed.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/related_products_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_window.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/widgets/saveable_product_card.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Which collaborative-filtering relation a product rail shows.
enum CollabProductRelation {
  boughtTogether('Frequently bought together'),
  alsoViewed('People also viewed');

  const CollabProductRelation(this.title);

  /// Aggregate wording: what other shoppers did, never who, and never a
  /// claim about the reader.
  final String title;
}

/// "Frequently bought together" / "People also viewed" on the item page (AI
/// features contract v1.0 §3).
///
/// Collaborative filtering is empty most of the time on a young catalogue,
/// so this rail draws **nothing at all** until it has items: no skeleton
/// that would then collapse, no empty state, no error. A server without the
/// endpoint (404) is the same as a server with too little data.
class CollabProductRail extends ConsumerWidget {
  const CollabProductRail({
    required this.productId,
    required this.relation,
    super.key,
    this.padding = EdgeInsets.zero,
    this.excludeIds = const {},
  });

  final String productId;
  final CollabProductRelation relation;
  final EdgeInsetsGeometry padding;

  /// Products already shown higher up the page.
  final Set<String> excludeIds;

  static Key railKey(CollabProductRelation relation) =>
      Key('collab-rail-${relation.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = switch (relation) {
      CollabProductRelation.boughtTogether => boughtTogetherProvider(productId),
      CollabProductRelation.alsoViewed => alsoViewedProvider(productId),
    };
    final rail = ref.watch(provider).asData?.value;
    final products = [
      for (final product in rail?.items ?? const <RelatedProduct>[])
        if (product.id != productId && !excludeIds.contains(product.id))
          product,
    ];
    if (rail == null || rail.status != AiRailStatus.ok || products.isEmpty) {
      return const SizedBox.shrink();
    }

    const size = MallCardSize.compact;
    const width = MallProductCard.compactWidth;
    return Padding(
      key: railKey(relation),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MallSectionHeader(title: relation.title, padding: EdgeInsets.zero),
          const SizedBox(height: DesignTokens.s12),
          PdpBleed(
            child: MallRail<RelatedProduct>(
              items: products,
              itemWidth: width,
              height: MallProductCard.heightFor(
                context,
                width: width,
                size: size,
              ),
              semanticLabel: relation.title,
              itemBuilder: (context, product, _) => SaveableMallProductCard(
                product: RelatedProductsRail.toVm(product),
                size: size,
                onReelTap: (reel) =>
                    unawaited(openMallReelWindow(context, reel)),
                onTap: () => unawaited(
                  context.push(
                    RouteNames.productDetail.replaceFirst(
                      ':productId',
                      product.id,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
