import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// First-load placeholder with the Mall's shape: greeting, hero, a lead
/// product rail, a reel rail and a compact product rail.
class MallHomeSkeleton extends StatelessWidget {
  const MallHomeSkeleton({required this.topInset, super.key});

  final double topInset;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: MallStrings.of(context).loading,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsetsDirectional.only(top: topInset),
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: SmSkeleton.line(width: 180, height: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
            child: SmSkeleton.box(
              height: MallCampaignHero.heightFor(context),
              radius: DesignTokens.radiusLarge,
            ),
          ),
          const SizedBox(height: DesignTokens.s40),
          const _HeaderSkeleton(),
          SmSkeletonRail(
            itemWidth: MallProductCard.regularWidth,
            height: MallProductCard.heightFor(
              context,
              width: MallProductCard.regularWidth,
            ),
            itemBuilder: (_, _) => const SmSkeletonProductCard(
              width: MallProductCard.regularWidth,
            ),
          ),
          const SizedBox(height: DesignTokens.s40),
          const _HeaderSkeleton(),
          SmSkeletonRail(
            itemWidth: MallReelCard.regularWidth,
            height: MallReelCard.heightFor(MallReelCard.regularWidth),
            itemBuilder: (_, _) =>
                const SmSkeletonReelCard(width: MallReelCard.regularWidth),
          ),
          const SizedBox(height: DesignTokens.s40),
          const _HeaderSkeleton(),
          SmSkeletonRail(
            itemWidth: MallProductCard.compactWidth,
            height: MallProductCard.heightFor(
              context,
              width: MallProductCard.compactWidth,
              size: MallCardSize.compact,
            ),
            itemBuilder: (_, _) => const SmSkeletonProductCard(
              width: MallProductCard.compactWidth,
              size: MallCardSize.compact,
            ),
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
      padding: EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmSkeleton.line(width: 72, height: 10),
          SizedBox(height: DesignTokens.s8),
          SmSkeleton.line(width: 200, height: 22),
        ],
      ),
    );
  }
}
