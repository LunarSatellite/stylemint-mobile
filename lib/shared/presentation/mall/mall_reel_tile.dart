import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_reel_play_slot.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_signal.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_tile_text.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_type_tile.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The product tile for a product sold through a reel: the reel's poster
/// with a play affordance, its length, and — whenever the reel is flagged —
/// the "AI-generated" disclosure, which is always shown in full.
///
/// The poster is the product's picture in the Mall; no product photo is
/// built here (owner directive, 2026-09-16). Tapping opens the reel.
///
/// At most one tile on screen holds the play slot ([MallReelPlaySlot]) and
/// its play mark fills with brand green; the rest stay resting posters.
class MallReelTile extends StatelessWidget {
  const MallReelTile({
    required this.product,
    required this.reel,
    super.key,
    this.size = MallCardSize.regular,
    this.onTap,
    this.onPlayTap,
    this.onSaveTap,
    this.showRating = true,
    this.signal,
    this.reserveSignal = false,
    this.playSlotController,
  });

  final MallProductVm product;

  /// The product's reel. Non-null by construction — a product without one
  /// gets a [MallTypeTile].
  final MallReelRef reel;

  final MallCardSize size;

  /// Opens the product. Playing the reel is [onPlayTap]'s job.
  final VoidCallback? onTap;

  /// Plays the reel in a window over the Mall. The play mark is its target
  /// and the only part of the tile that plays anything.
  final VoidCallback? onPlayTap;

  /// Shows the save heart when non-null.
  final VoidCallback? onSaveTap;
  final bool showRating;

  /// One live fact under the price.
  final MallSignal? signal;

  /// Keeps the signal slot so every tile in a rail is the same height.
  final bool reserveSignal;

  /// Defaults to [MallReelPlaySlotController.instance].
  final MallReelPlaySlotController? playSlotController;

  /// The play affordance's tap target.
  static const Key playKey = Key('mall-reel-play');

  /// Suggested rail item widths — the same as every other product tile.
  static const double compactWidth = 148;
  static const double regularWidth = 184;

  static double heightFor(
    BuildContext context, {
    required double width,
    MallCardSize size = MallCardSize.regular,
    bool withSignal = false,
  }) => MallTileMetrics.heightFor(
    context,
    width: width,
    size: size,
    withSignal: withSignal,
  );

  @override
  Widget build(BuildContext context) {
    final strings = MallStrings.of(context);
    final fact = signal;
    final showSignal = reserveSignal || fact != null;
    final metrics = MallTileMetrics.of(
      context,
      size: size,
      withSignal: showSignal,
    );
    final radius = BorderRadius.circular(
      size == MallCardSize.compact
          ? DesignTokens.radiusMedium
          : DesignTokens.cardRadius,
    );
    final saveTap = onSaveTap;
    final playTap = onPlayTap;
    final playSize = metrics.isCompact
        ? DesignTokens.minTouchTarget
        : DesignTokens.s48;
    final rating = showRating ? product.rating : null;
    final badges = mallTileBadges(strings, product);
    final hook = reel.hook?.trim();
    final label = mallTileSemanticLabel(
      strings,
      product,
      rating: rating,
      signal: fact,
      extras: [
        // Once the tile carries its own play affordance, the tile's tap
        // opens the product and "Watch reel" belongs to that affordance
        // alone — saying it twice would read as two ways to play.
        if (playTap == null) strings.watchReel,
        if (reel.isAiGenerated) strings.aiGenerated,
        if (reel.hasDuration) strings.spokenReelDuration(reel.durationSeconds),
        if (hook != null && hook.isNotEmpty) hook,
      ],
    );

    final poster = Stack(
      fit: StackFit.expand,
      children: [
        MallNetworkImage(
          url: reel.posterUrl,
          placeholder: MallTypeGround(seed: product.id, monogram: _monogram),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(gradient: DesignTokens.imageScrimTop),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(gradient: DesignTokens.imageScrim),
        ),
        PositionedDirectional(
          top: DesignTokens.s8,
          start: DesignTokens.s8,
          end: saveTap == null
              ? DesignTokens.s8
              : DesignTokens.minTouchTarget + DesignTokens.s4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: DesignTokens.s4,
            children: [
              if (reel.isAiGenerated)
                // Disclosure: wraps, never truncates.
                Row(
                  children: [
                    Flexible(
                      child: MallBadge(
                        label: strings.aiGenerated,
                        icon: Icons.auto_awesome_rounded,
                        maxLines: null,
                      ),
                    ),
                  ],
                ),
              ...badges,
            ],
          ),
        ),
        Center(
          child: MallReelPlaySlot(
            id: reel.reelId,
            controller: playSlotController,
            builder: (context, {required holdsSlot}) =>
                MallPlayMark(primed: holdsSlot, size: playSize),
          ),
        ),
        PositionedDirectional(
          start: DesignTokens.s8,
          end: DesignTokens.s8,
          bottom: DesignTokens.s8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hook != null && hook.isNotEmpty) ...[
                Text(
                  hook,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _hookStyle,
                ),
                const SizedBox(height: DesignTokens.s6),
              ],
              Row(
                children: [
                  if (rating != null)
                    Flexible(
                      child: MallBadge(
                        label: rating.toStringAsFixed(1),
                        icon: Icons.star_rounded,
                      ),
                    ),
                  const Spacer(),
                  if (reel.hasDuration)
                    Flexible(
                      child: MallBadge(
                        label: strings.reelDuration(reel.durationSeconds),
                        icon: Icons.play_circle_outline_rounded,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final visual = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: MallTileMetrics.mediaAspectRatio,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: DesignTokens.shadowCard,
            ),
            child: ClipRRect(borderRadius: radius, child: poster),
          ),
        ),
        const SizedBox(height: MallTileMetrics.imageGap),
        MallTileText(
          product: product,
          metrics: metrics,
          signal: fact,
          showSignal: showSignal,
        ),
      ],
    );

    return Stack(
      children: [
        ExcludeSemantics(child: visual),
        Positioned.fill(
          child: MallTapOverlay(
            semanticLabel: label,
            onTap: onTap,
            borderRadius: radius,
          ),
        ),
        if (playTap != null)
          // The play mark is its own target, above the tile's tap layer: it
          // plays the reel in a window, while the rest of the tile keeps
          // opening the product. Positioned rather than laid out in a column
          // so a tile squeezed by its parent clips instead of overflowing.
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mediaHeight =
                    constraints.maxWidth / MallTileMetrics.mediaAspectRatio;
                return Stack(
                  children: [
                    Positioned(
                      left: (constraints.maxWidth - playSize) / 2,
                      top: (mediaHeight - playSize) / 2,
                      width: playSize,
                      height: playSize,
                      child: Semantics(
                        button: true,
                        label: strings.watchReel,
                        child: Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            key: playKey,
                            onTap: playTap,
                            customBorder: const CircleBorder(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (saveTap != null)
          PositionedDirectional(
            top: 2,
            end: 2,
            child: MallSaveButton(
              isSaved: product.isSaved,
              onPressed: saveTap,
              semanticLabel: product.isSaved
                  ? strings.unsaveItem(product.name)
                  : strings.saveItem(product.name),
            ),
          ),
      ],
    );
  }

  static const TextStyle _hookStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    height: 1.25,
    color: DesignTokens.textWhite,
  );

  String get _monogram {
    final source = (product.brandName?.trim().isNotEmpty ?? false)
        ? product.brandName!.trim()
        : product.name.trim();
    return source.isEmpty ? '' : source.characters.first.toUpperCase();
  }
}
