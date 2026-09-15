import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_reel.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

const BorderRadius _tileRadius = BorderRadius.all(Radius.circular(6));

/// Tight editorial grid of 9:16 reel posters: 3 columns on phones, 4 from
/// 600dp, 5 from 900dp.
class StorefrontSliverReelGrid extends StatelessWidget {
  const StorefrontSliverReelGrid({
    required this.reels,
    required this.onReelTap,
    super.key,
  });

  final List<StorefrontReel> reels;
  final ValueChanged<StorefrontReel> onReelTap;

  static const double gap = 3;

  static int columnsFor(double width) => width >= 900
      ? 5
      : width >= 600
      ? 4
      : 3;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: gap),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnsFor(constraints.crossAxisExtent),
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            childAspectRatio: 9 / 16,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final reel = reels[index];
            return StorefrontReelTile(
              key: ValueKey(reel.id),
              reel: reel,
              onTap: () => onReelTap(reel),
            );
          }, childCount: reels.length),
        ),
      ),
    );
  }
}

/// Skeleton of [StorefrontSliverReelGrid].
class StorefrontSliverReelGridSkeleton extends StatelessWidget {
  const StorefrontSliverReelGridSkeleton({super.key, this.count = 9});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: StorefrontSliverReelGrid.gap,
        ),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: StorefrontSliverReelGrid.columnsFor(
              constraints.crossAxisExtent,
            ),
            mainAxisSpacing: StorefrontSliverReelGrid.gap,
            crossAxisSpacing: StorefrontSliverReelGrid.gap,
            childAspectRatio: 9 / 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => const SmSkeleton.box(radius: 6),
            childCount: count,
          ),
        ),
      ),
    );
  }
}

/// One reel poster: likes, a bag mark when products are tagged, and the
/// "AI-generated" label when the caption discloses it.
class StorefrontReelTile extends StatelessWidget {
  const StorefrontReelTile({
    required this.reel,
    required this.onTap,
    super.key,
  });

  final StorefrontReel reel;
  final VoidCallback onTap;

  static const TextStyle _countStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: DesignTokens.textWhite,
  );

  /// Spoken label: hook, AI disclosure, likes and tagged products.
  static String semanticsFor(MallStrings strings, StorefrontReel reel) => [
    reel.hook ?? 'Reel',
    if (reel.isAiGenerated) strings.aiGenerated,
    strings.likes(reel.likeCount),
    if (reel.taggedProductCount > 0)
      strings.taggedProducts(reel.taggedProductCount),
  ].join(', ');

  @override
  Widget build(BuildContext context) {
    final strings = MallStrings.of(context);
    final poster = reel.posterUrl;
    return ClipRRect(
      borderRadius: _tileRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: DesignTokens.surfaceRaised),
                if (poster != null)
                  MallNetworkImage(url: poster)
                else
                  const MallImagePlaceholder(),
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    widthFactor: 1,
                    heightFactor: 0.45,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: DesignTokens.imageScrim,
                      ),
                    ),
                  ),
                ),
                if (reel.isAiGenerated)
                  PositionedDirectional(
                    top: 6,
                    start: 6,
                    end: 6,
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      // Wraps as needed; the disclosure is never cut off.
                      child: MallBadge(
                        label: strings.aiGenerated,
                        maxLines: null,
                      ),
                    ),
                  ),
                PositionedDirectional(
                  start: 8,
                  end: 8,
                  bottom: 6,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 13,
                        color: DesignTokens.textWhite,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          formatCompactNumber(reel.likeCount),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: _countStyle,
                        ),
                      ),
                      if (reel.taggedProductCount > 0)
                        const Icon(
                          Icons.shopping_bag_outlined,
                          size: 13,
                          color: DesignTokens.textWhite,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          MallTapOverlay(
            semanticLabel: semanticsFor(strings, reel),
            onTap: onTap,
            borderRadius: _tileRadius,
          ),
        ],
      ),
    );
  }
}
