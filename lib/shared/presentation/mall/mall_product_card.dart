import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_quick_add.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_signal.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_tile_text.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Product card: a 4:5 photo with badges, rating and save heart, then brand,
/// a two-line name and the price (with strikethrough original when on sale).
///
/// Image-led Mall card used wherever product photography is the primary
/// discovery cue. Reel-backed products keep the same image but add a real
/// centered play action; products without reel metadata remain honest photos.
///
/// Text sits on the page rather than in a boxed card — the photo carries the
/// depth. Text slots have fixed heights, so prices align across a grid row
/// and [heightFor] is exact.
class MallProductCard extends StatelessWidget {
  const MallProductCard({
    required this.product,
    super.key,
    this.size = MallCardSize.regular,
    this.onTap,
    this.onReelTap,
    this.onQuickAdd,
    this.onSaveTap,
    this.showRating = true,
    this.signal,
    this.reserveSignal = false,
  });

  final MallProductVm product;
  final MallCardSize size;
  final VoidCallback? onTap;

  /// Plays the product's reel while the rest of the card opens the product.
  final void Function(MallReelRef reel)? onReelTap;

  /// Adds immediately or opens product options, using the shared Mall control.
  final Future<bool> Function()? onQuickAdd;

  /// Shows the save heart when non-null.
  final VoidCallback? onSaveTap;
  final bool showRating;

  /// One live fact under the price — the dense-discovery zone's payload.
  /// Always derived from data the API sent; see `mall_zones.dart`.
  final MallSignal? signal;

  /// Keeps the signal slot even when this card has nothing to say, so every
  /// card in a rail is the same height. Pass it for the whole rail alongside
  /// `heightFor(withSignal: true)`.
  final bool reserveSignal;

  /// Suggested rail item widths.
  static const double compactWidth = 148;
  static const double regularWidth = 184;

  static const Key playKey = Key('mall-product-card-play');

  /// Image width : height.
  static const double imageAspectRatio = MallTileMetrics.mediaAspectRatio;

  /// Exact rendered height of a card [width] wide at the ambient text scale.
  ///
  /// Pass [withSignal] to match cards built with a signal slot. Shared with
  /// every other product tile, so a rail can mix them.
  static double heightFor(
    BuildContext context, {
    required double width,
    MallCardSize size = MallCardSize.regular,
    bool withSignal = false,
    bool withAction = false,
  }) => MallTileMetrics.heightFor(
    context,
    width: width,
    size: size,
    withSignal: withSignal,
    withAction: withAction,
  );

  @override
  Widget build(BuildContext context) {
    final strings = MallStrings.of(context);
    final fact = signal;
    final showSignal = reserveSignal || fact != null;
    final quickAdd = onQuickAdd;
    final metrics = MallTileMetrics.of(
      context,
      size: size,
      withSignal: showSignal,
      withAction: quickAdd != null,
    );
    final item = product;
    final rating = showRating ? item.rating : null;
    final saveTap = onSaveTap;
    final buy = MallQuickAdd.forProduct(
      product: item,
      strings: strings,
      onAdd: quickAdd,
      onChoose: onTap,
    );
    final reel = item.reel;
    final reelTap = onReelTap;
    final hasRealReel = reel != null && reelTap != null;
    final VoidCallback? playTap = hasRealReel ? () => reelTap(reel) : onTap;
    final playLabel = hasRealReel ? strings.watchReel : 'Open ${item.name}';
    final playSize = metrics.isCompact
        ? DesignTokens.minTouchTarget
        : DesignTokens.s48;
    final radius = BorderRadius.circular(
      size == MallCardSize.compact
          ? DesignTokens.radiusMedium
          : DesignTokens.cardRadius,
    );
    final badges = mallTileBadges(strings, item);

    final visual = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: imageAspectRatio,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: DesignTokens.shadowLifted,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MallNetworkImage(url: item.imageUrl),
                  if (playTap != null) ...[
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: DesignTokens.imageScrim,
                      ),
                    ),
                    Center(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Color(0x66000000), Color(0x00000000)],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: MallPlayMark(size: playSize),
                        ),
                      ),
                    ),
                  ],
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          border: Border.all(color: const Color(0x24FFFFFF)),
                        ),
                      ),
                    ),
                  ),
                  if (badges.isNotEmpty)
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
                        children: badges,
                      ),
                    ),
                  if (rating != null)
                    PositionedDirectional(
                      start: DesignTokens.s8,
                      end: DesignTokens.s8,
                      bottom: DesignTokens.s8,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: MallBadge(
                          label: rating.toStringAsFixed(1),
                          icon: Icons.star_rounded,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: MallTileMetrics.imageGap),
        MallTileText(
          product: item,
          metrics: metrics,
          signal: fact,
          showSignal: showSignal,
          action: buy == null
              ? null
              : const SizedBox(width: DesignTokens.minTouchTarget),
        ),
      ],
    );

    return Stack(
      children: [
        ExcludeSemantics(child: visual),
        Positioned.fill(
          child: MallTapOverlay(
            semanticLabel: mallTileSemanticLabel(
              strings,
              item,
              rating: rating,
              signal: fact,
            ),
            onTap: onTap,
            borderRadius: radius,
          ),
        ),
        if (playTap != null)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mediaHeight =
                    constraints.maxWidth / MallProductCard.imageAspectRatio;
                return Stack(
                  children: [
                    Positioned(
                      left: (constraints.maxWidth - playSize) / 2,
                      top: (mediaHeight - playSize) / 2,
                      width: playSize,
                      height: playSize,
                      child: Semantics(
                        button: true,
                        label: playLabel,
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
        if (buy != null)
          PositionedDirectional(
            end: 0,
            bottom: metrics.bottomSlotOffset,
            child: buy,
          ),
        if (saveTap != null)
          PositionedDirectional(
            top: 2,
            end: 2,
            child: MallSaveButton(
              isSaved: item.isSaved,
              onPressed: saveTap,
              semanticLabel: item.isSaved
                  ? strings.unsaveItem(item.name)
                  : strings.saveItem(item.name),
            ),
          ),
      ],
    );
  }
}
