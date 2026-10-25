import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/domain/entities/ai_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/pdp_bleed.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_reels_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_window.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Reels on the item page, from `GET v1/public/products/{id}/reels` (AI
/// features contract v1.0 §4.2): reels that **feature** (tag) the product,
/// then reels **like** it by meaning.
///
/// Two rails, because they are two different claims: "Reels with this
/// product" is a fact (the creator tagged it); "Reels like this product" is
/// a similarity, drawn only when the server says meaning matching ran.
///
/// A server without the endpoint (404, or any failure) gets exactly what the
/// page showed before: the tagged-reels rail ([ProductReelsRail]). Nothing
/// is drawn while the answer is on its way, as before.
class ProductMatchedReelsRail extends ConsumerWidget {
  const ProductMatchedReelsRail({
    required this.productId,
    super.key,
    this.padding = EdgeInsets.zero,
  });

  static const String featuredTitle = 'Reels with this product';
  static const String meaningTitle = 'Reels like this product';
  static const Key featuredKey = Key('product-reels-featured');
  static const Key meaningKey = Key('product-reels-meaning');

  final String productId;
  final EdgeInsetsGeometry padding;

  static MallReelRef toRef(Reel reel) {
    final caption = reel.caption.trim();
    return MallReelRef(
      reelId: reel.id,
      posterUrl: reel.thumbnailUrl.isEmpty ? null : reel.thumbnailUrl,
      hook: caption.isEmpty ? null : caption,
      isAiGenerated: ProductReelsRail.isAiGenerated(caption),
    );
  }

  static MallReelVm toVm(Reel reel) {
    final creator = reel.creatorName.trim();
    final caption = reel.caption.trim();
    return MallReelVm(
      id: reel.id,
      creatorName: creator.isEmpty ? 'StyleMint creator' : creator,
      posterUrl: reel.thumbnailUrl.isEmpty ? null : reel.thumbnailUrl,
      caption: caption.isEmpty ? null : caption,
      isAiGenerated: ProductReelsRail.isAiGenerated(caption),
      likeCount: reel.likeCount > 0 ? reel.likeCount : null,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answer = ref
        .watch(productMatchedReelsProvider(productId))
        .asData
        ?.value;
    if (answer == null) return const SizedBox.shrink();
    if (answer.notDeployed) {
      return ProductReelsRail(productId: productId, padding: padding);
    }
    final featured = answer.featured;
    final featuredIds = {for (final m in featured) m.reel.id};
    final byMeaning = [
      for (final m in answer.byMeaning)
        if (!featuredIds.contains(m.reel.id)) m,
    ];
    if (featured.isEmpty && byMeaning.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (featured.isNotEmpty)
            _ReelRow(key: featuredKey, title: featuredTitle, reels: featured),
          if (featured.isNotEmpty && byMeaning.isNotEmpty)
            const SizedBox(height: DesignTokens.s24),
          if (byMeaning.isNotEmpty)
            _ReelRow(
              key: meaningKey,
              title: meaningTitle,
              subtitle: 'Matched by meaning',
              reels: byMeaning,
            ),
        ],
      ),
    );
  }
}

class _ReelRow extends StatelessWidget {
  const _ReelRow({
    required this.title,
    required this.reels,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<MatchedReel> reels;

  @override
  Widget build(BuildContext context) {
    const width = MallReelCard.compactWidth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MallSectionHeader(
          title: title,
          subtitle: subtitle,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: DesignTokens.s12),
        PdpBleed(
          child: MallRail<MatchedReel>(
            items: reels,
            itemWidth: width,
            height: MallReelCard.heightFor(width),
            semanticLabel: title,
            itemBuilder: (context, match, _) => MallReelCard(
              reel: ProductMatchedReelsRail.toVm(match.reel),
              onTap: () => unawaited(
                openMallReelWindow(
                  context,
                  ProductMatchedReelsRail.toRef(match.reel),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
