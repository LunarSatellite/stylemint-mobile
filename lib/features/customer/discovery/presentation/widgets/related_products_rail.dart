import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/related_products_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/pdp_bleed.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_window.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/widgets/saveable_product_card.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/product_reel_vm.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "You may also like" (`GET /v1/public/products/{id}/related`): skeleton
/// cards while loading, hidden on failure or when nothing is related.
class RelatedProductsRail extends ConsumerWidget {
  const RelatedProductsRail({
    required this.productId,
    super.key,
    this.padding = EdgeInsets.zero,
  });

  static const String title = 'You may also like';

  final String productId;
  final EdgeInsetsGeometry padding;

  static MallProductVm toVm(RelatedProduct product) => MallProductVm(
    id: product.id,
    name: product.name,
    price: product.price,
    imageUrl: product.imageUrl.isEmpty ? null : product.imageUrl,
    rating: product.rating > 0 ? product.rating : null,
    reel: product.reel?.toVm(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(relatedProductsProvider(productId));
    final loading = state.maybeWhen(
      initial: () => true,
      loadInProgress: () => true,
      orElse: () => false,
    );
    final products = state.maybeWhen(
      loadSuccess: (items) =>
          items.where((p) => p.id != productId).toList(growable: false),
      orElse: () => const <RelatedProduct>[],
    );
    if (!loading && products.isEmpty) return const SizedBox.shrink();

    const size = MallCardSize.compact;
    const width = MallProductCard.compactWidth;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MallSectionHeader(title: title, padding: EdgeInsets.zero),
          const SizedBox(height: DesignTokens.s12),
          PdpBleed(
            child: MallRail<RelatedProduct>(
              items: products,
              isLoading: loading,
              skeletonBuilder: (_, _) =>
                  const SmSkeletonProductCard(width: width, size: size),
              itemWidth: width,
              height: MallProductCard.heightFor(
                context,
                width: width,
                size: size,
              ),
              semanticLabel: title,
              itemBuilder: (context, product, _) => SaveableMallProductCard(
                product: toVm(product),
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
