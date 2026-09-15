import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/pdp_bleed.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/product_reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "See it in reels": published reels that tag this product
/// (`GET /v1/public/reels/by-product/{productId}`). Each opens StyleMint's
/// own reel screen. Nothing shows while loading, on failure or when no reel
/// tags the product.
class ProductReelsRail extends ConsumerWidget {
  const ProductReelsRail({
    required this.productId,
    super.key,
    this.padding = EdgeInsets.zero,
  });

  static const String title = 'See it in reels';

  final String productId;
  final EdgeInsetsGeometry padding;

  /// Creators disclose AI-generated reels with `#AIgenerated` in the caption.
  static bool isAiGenerated(String caption) =>
      caption.toLowerCase().contains('#aigenerated');

  static MallReelVm toVm(ProductReel reel) {
    final creator = reel.creatorName.trim();
    final caption = reel.caption.trim();
    return MallReelVm(
      id: reel.id,
      creatorName: creator.isEmpty ? 'StyleMint creator' : creator,
      posterUrl: reel.thumbnailUrl,
      caption: caption.isEmpty ? null : caption,
      isAiGenerated: isAiGenerated(caption),
      likeCount: reel.likeCount > 0 ? reel.likeCount : null,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productReelsNotifierProvider(productId));
    final reels = switch (state) {
      ProductReelsLoaded(:final reels) => reels,
      _ => const <ProductReel>[],
    };
    if (reels.isEmpty) return const SizedBox.shrink();

    const width = MallReelCard.compactWidth;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MallSectionHeader(title: title, padding: EdgeInsets.zero),
          const SizedBox(height: DesignTokens.s12),
          PdpBleed(
            child: MallRail<ProductReel>(
              items: reels,
              itemWidth: width,
              height: MallReelCard.heightFor(width),
              semanticLabel: title,
              itemBuilder: (context, reel, _) => MallReelCard(
                reel: toVm(reel),
                onTap: () => unawaited(
                  context.push(
                    RouteNames.reelDetail.replaceFirst(':reelId', reel.id),
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
