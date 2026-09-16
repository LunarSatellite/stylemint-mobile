import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_quick_add.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_signal.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_tile_text.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The product tile for the majority of the catalogue: the pieces with no
/// reel. No photo — by directive the Mall is video-first and photos live on
/// the product details page only.
///
/// It is a designed object rather than a gap where an image failed: a tonal
/// ground drawn from the palette and picked deterministically from the
/// product id, the brand set as a tracked eyebrow, the product name set
/// large in Instrument Serif as the tile's subject, a hairline, and the
/// price closing it. Same footprint as `MallReelTile`, so a rail or grid
/// row mixes the two without a seam.
class MallTypeTile extends StatelessWidget {
  const MallTypeTile({
    required this.product,
    super.key,
    this.size = MallCardSize.regular,
    this.onTap,
    this.onSaveTap,
    this.onQuickAdd,
    this.showRating = true,
    this.signal,
    this.reserveSignal = false,
  });

  final MallProductVm product;
  final MallCardSize size;
  final VoidCallback? onTap;

  /// Shows the save heart when non-null.
  final VoidCallback? onSaveTap;

  /// Adds the product to the bag from the tile. Shows the buy control on the
  /// price line when non-null; size the tile with `withAction: true`.
  final Future<bool> Function()? onQuickAdd;

  /// Kept for parity with the other tiles; the rating rides in the spoken
  /// label here rather than crowding the composition.
  final bool showRating;

  /// One live fact under the price.
  final MallSignal? signal;

  /// Keeps the signal slot so every tile in a rail is the same height.
  final bool reserveSignal;

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
    final radius = BorderRadius.circular(
      size == MallCardSize.compact
          ? DesignTokens.radiusMedium
          : DesignTokens.cardRadius,
    );
    final saveTap = onSaveTap;
    final badges = mallTileBadges(strings, product);
    final label = mallTileSemanticLabel(
      strings,
      product,
      rating: showRating ? product.rating : null,
      signal: fact,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MallTypeTile.regularWidth;
        return SizedBox(
          height: metrics.tileHeight(width),
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
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
                          MallTypeGround(
                            seed: product.id,
                            monogram: _monogram,
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                              metrics.isCompact ? 12 : 14,
                              metrics.isCompact ? 12 : 14,
                              metrics.isCompact ? 12 : 14,
                              metrics.isCompact ? 12 : 14,
                            ),
                            child: _Composition(
                              product: product,
                              metrics: metrics,
                              badges: badges,
                              signal: fact,
                              showSignal: showSignal,
                              hasSaveButton: saveTap != null,
                              hasQuickAdd: quickAdd != null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: MallTapOverlay(
                  semanticLabel: label,
                  onTap: onTap,
                  borderRadius: radius,
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
              // Above the tap layer, on the price line, in the slot the
              // composition reserved for it.
              if (quickAdd != null)
                PositionedDirectional(
                  end: metrics.isCompact ? 8 : 10,
                  bottom:
                      (metrics.isCompact ? 12 : 14) +
                      metrics.bottomSlotOffset -
                      MallTileMetrics.bottomGap,
                  child: MallQuickAdd(
                    onAdd: quickAdd,
                    semanticLabel: strings.addItem(product.name),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Suggested rail item widths — the same as every other product tile.
  static const double compactWidth = 148;
  static const double regularWidth = 184;

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

  /// The letter drawn behind the type: the brand's initial, else the
  /// product's.
  String get _monogram {
    final source = (product.brandName?.trim().isNotEmpty ?? false)
        ? product.brandName!.trim()
        : product.name.trim();
    return source.isEmpty ? '' : source.characters.first.toUpperCase();
  }
}

/// Brand, the name as the tile's subject, a hairline and the price.
class _Composition extends StatelessWidget {
  const _Composition({
    required this.product,
    required this.metrics,
    required this.badges,
    required this.signal,
    required this.showSignal,
    required this.hasSaveButton,
    required this.hasQuickAdd,
  });

  final MallProductVm product;
  final MallTileMetrics metrics;
  final List<Widget> badges;
  final MallSignal? signal;
  final bool showSignal;
  final bool hasSaveButton;

  /// Keeps the trailing slot on the price line clear for the buy control,
  /// which the tile draws above its own tap layer.
  final bool hasQuickAdd;

  @override
  Widget build(BuildContext context) {
    final brand = product.brandName?.trim();
    final fact = signal;
    final compareAt = product.discountPercent == null
        ? null
        : product.compareAtPrice;
    final serif = TextStyle(
      fontFamily: DesignTokens.displayFontFamily,
      fontSize: metrics.isCompact ? 21 : 25,
      fontWeight: FontWeight.w400,
      height: 1.14,
      color: DesignTokens.textWhite,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: metrics.brandHeight,
          child: Row(
            children: [
              if (brand != null && brand.isNotEmpty)
                Flexible(
                  child: MallEyebrow(brand, color: DesignTokens.textLight),
                )
              else
                const Spacer(),
              // Clear of the save heart, which sits in the same corner.
              if (hasSaveButton) const SizedBox(width: DesignTokens.s32),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.bottomStart,
            child: ClipRect(
              child: Text(
                product.name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: serif,
              ),
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        const _Hairline(),
        const SizedBox(height: DesignTokens.s8),
        SizedBox(
          height: metrics.priceRowHeight,
          child: Row(
            children: [
              Expanded(
                child: MallTilePriceRow(
                  price: product.price,
                  compareAtPrice: compareAt,
                  priceStyle: metrics.priceStyle,
                  compareStyle: metrics.compareStyle,
                ),
              ),
              if (badges.isNotEmpty) ...[
                const SizedBox(width: DesignTokens.s6),
                Flexible(
                  child: MallScaleDownStart(child: badges.first),
                ),
              ],
              if (hasQuickAdd)
                SizedBox(width: metrics.actionHeight + DesignTokens.s6),
            ],
          ),
        ),
        if (showSignal) ...[
          const SizedBox(height: MallTileMetrics.signalGap),
          SizedBox(
            height: metrics.signalHeight,
            child: fact == null ? null : MallSignalLine(signal: fact),
          ),
        ],
      ],
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(color: DesignTokens.borderDefault),
    child: SizedBox(height: 1, width: double.infinity),
  );
}

/// The tonal ground a type tile is built on, with the monogram traced into
/// its corner. Also stands in for a reel poster that has not arrived.
///
/// The pair of tones is picked from the palette by [seed], so a product
/// always gets the same ground and a rail never repeats itself twice in a
/// row. No colour here is new: every tone is a `DesignTokens` value.
class MallTypeGround extends StatelessWidget {
  const MallTypeGround({required this.seed, super.key, this.monogram});

  final String seed;
  final String? monogram;

  static const List<List<Color>> _grounds = [
    [DesignTokens.surfaceRaised, DesignTokens.bgAppFoundation],
    [DesignTokens.bgAppBodyLight, DesignTokens.bgAppBody],
    [DesignTokens.primaryGreenDark, DesignTokens.bgAppFoundation],
    [DesignTokens.infoFillDark, DesignTokens.bgAppBody],
    [DesignTokens.primaryGreenLight, DesignTokens.bgAppFoundation],
    [DesignTokens.warningFillDark, DesignTokens.bgAppBody],
  ];

  /// Stable across runs and platforms — `String.hashCode` is not.
  static int groundIndexFor(String seed) {
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) % 100003;
    }
    return hash % _grounds.length;
  }

  @override
  Widget build(BuildContext context) {
    final tones = _grounds[groundIndexFor(seed)];
    final letter = monogram?.trim() ?? '';
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: tones,
          ),
        ),
        child: letter.isEmpty
            ? const SizedBox.expand()
            : LayoutBuilder(
                builder: (context, constraints) => Stack(
                  fit: StackFit.expand,
                  children: [
                    PositionedDirectional(
                      end: -constraints.maxWidth * 0.14,
                      bottom: -constraints.maxHeight * 0.2,
                      child: Text(
                        letter,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontFamily: DesignTokens.displayFontFamily,
                          fontSize: constraints.maxHeight * 0.72,
                          height: 1,
                          color: DesignTokens.textWhite.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
