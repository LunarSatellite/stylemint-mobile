import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// 9:16 reel poster with a play mark, the creator, the tagged-product count,
/// an optional like count and — whenever the reel is flagged — the
/// "AI-generated" disclosure, which is always shown in full.
///
/// Presentational only: [onTap] decides how the reel opens. With
/// [onTaggedProductsTap] the tagged-products pill becomes its own button
/// (e.g. to shop the reel without leaving the page).
class MallReelCard extends StatelessWidget {
  const MallReelCard({
    required this.reel,
    super.key,
    this.onTap,
    this.onTaggedProductsTap,
  });

  final MallReelVm reel;
  final VoidCallback? onTap;

  /// Makes the tagged-products pill a separate 44dp button. Ignored when the
  /// reel has no tagged products.
  final VoidCallback? onTaggedProductsTap;

  /// Suggested rail item widths.
  static const double compactWidth = 140;
  static const double regularWidth = 172;

  static double heightFor(double width) => width * 16 / 9;

  static const TextStyle _creatorStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: DesignTokens.textWhite,
  );

  static const TextStyle _likesStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: DesignTokens.textWhite,
  );

  @override
  Widget build(BuildContext context) {
    final strings = MallStrings.of(context);
    final item = reel;
    final likes = item.likeCount;
    final tagged = item.taggedProductCount;
    final caption = item.caption?.trim();
    final productsTap = tagged > 0 ? onTaggedProductsTap : null;
    final radius = BorderRadius.circular(DesignTokens.cardRadius);
    final creatorRow = Row(
      children: [
        MallAvatar(
          name: item.creatorName,
          imageUrl: item.creatorAvatarUrl,
          size: 24,
          ringColor: const Color(0x66FFFFFF),
          ringWidth: 1,
        ),
        const SizedBox(width: DesignTokens.s6),
        Expanded(
          child: Text(
            item.creatorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _creatorStyle,
          ),
        ),
        if (likes != null) ...[
          const SizedBox(width: DesignTokens.s6),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 13,
                  color: DesignTokens.textWhite,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    formatCompactNumber(likes),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _likesStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
    final label = [
      strings.reelBy(item.creatorName),
      if (item.isAiGenerated) strings.aiGenerated,
      if (tagged > 0) strings.taggedProducts(tagged),
      if (likes != null) strings.likes(likes),
      if (caption != null && caption.isNotEmpty) caption,
    ].join(', ');

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: DesignTokens.shadowCard,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeSemantics(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MallNetworkImage(url: item.posterUrl),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: DesignTokens.imageScrimTop,
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: DesignTokens.imageScrim,
                      ),
                    ),
                    if (item.isAiGenerated)
                      PositionedDirectional(
                        top: DesignTokens.s8,
                        start: DesignTokens.s8,
                        end: DesignTokens.s8,
                        child: Row(
                          children: [
                            Flexible(
                              // Disclosure: wraps, never truncates.
                              child: MallBadge(
                                label: strings.aiGenerated,
                                icon: Icons.auto_awesome_rounded,
                                maxLines: null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Center(child: MallPlayMark()),
                    if (productsTap == null)
                      PositionedDirectional(
                        start: 10,
                        end: 10,
                        bottom: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (tagged > 0) ...[
                              MallBadge(
                                label: strings.taggedProducts(tagged),
                                icon: Icons.shopping_bag_outlined,
                              ),
                              const SizedBox(height: DesignTokens.s8),
                            ],
                            creatorRow,
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              MallTapOverlay(
                semanticLabel: label,
                onTap: onTap,
                borderRadius: radius,
              ),
              if (productsTap != null)
                PositionedDirectional(
                  start: 10,
                  end: 10,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TaggedProductsButton(
                        label: strings.taggedProducts(tagged),
                        onTap: productsTap,
                      ),
                      // Taps on the creator row still open the reel.
                      IgnorePointer(child: ExcludeSemantics(child: creatorRow)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tagged-products pill as its own button, with a 44dp-tall hit area.
class _TaggedProductsButton extends StatelessWidget {
  const _TaggedProductsButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: DesignTokens.minTouchTarget,
            minHeight: DesignTokens.minTouchTarget,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            heightFactor: 1,
            child: MallBadge(label: label, icon: Icons.shopping_bag_outlined),
          ),
        ),
      ),
    );
  }
}
