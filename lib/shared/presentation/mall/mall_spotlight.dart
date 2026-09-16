import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_motion.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_quick_add.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_reel_play_slot.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_signal.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_type_tile.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// **The Mall's counter.** One product, given a whole block: the name set at
/// hero size, the price as a display numeral, the saving as a green slab, the
/// deadline ticking, and the bag one tap away.
///
/// It exists because the catalogue is small and honest about it. A rail makes
/// twelve products look like twelve twelfths of a screen; the spotlight makes
/// one product look like a decision, which is what a thin catalogue needs and
/// what a deep one still rewards. Nothing here is invented — every figure is
/// a field the server populated, and a product with no saving, no rating and
/// no deadline simply shows its name and its price, large.
///
/// Composition is deliberately off-grid: the media panel runs past the
/// trailing edge of the screen rather than sitting in a card, and the copy
/// column is set against it. Below 360 dp the two stack, media first.
class MallSpotlight extends StatelessWidget {
  const MallSpotlight({
    required this.product,
    super.key,
    this.eyebrow,
    this.signal,
    this.endsUtc,
    this.now,
    this.onTap,
    this.onReelTap,
    this.onSaveTap,
    this.onQuickAdd,
    this.playSlotController,
  });

  final MallProductVm product;

  /// Why this product earned the block, e.g. "Biggest saving here". The
  /// caller derives it from the block's own items; the kit claims nothing.
  final String? eyebrow;

  /// One live fact, shown when there is no [endsUtc] to count down.
  final MallSignal? signal;

  /// A real sale deadline, counted down live.
  final DateTime? endsUtc;

  /// Clock behind the countdown; tests pin it.
  final DateTime Function()? now;

  /// Opens the product.
  final VoidCallback? onTap;

  /// Plays the product's reel, when it has one.
  final void Function(MallReelRef reel)? onReelTap;

  /// Shows the save heart when non-null.
  final VoidCallback? onSaveTap;

  /// Adds the product to the bag from here. Hidden when null.
  final Future<bool> Function()? onQuickAdd;

  /// Defaults to [MallReelPlaySlotController.instance].
  final MallReelPlaySlotController? playSlotController;

  /// Below this the copy column has no room beside the media.
  static const double stackBelowWidth = 360;

  /// Shortest the block ever gets, so the media panel has presence even
  /// against a one-line product name.
  static const double minPanelHeight = 300;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final stacked = width < stackBelowWidth;
        final copy = _Copy(
          product: product,
          eyebrow: eyebrow,
          signal: signal,
          endsUtc: endsUtc,
          now: now,
          onTap: onTap,
          onQuickAdd: onQuickAdd,
        );
        final panel = _Panel(
          product: product,
          onReelTap: onReelTap,
          onSaveTap: onSaveTap,
          playSlotController: playSlotController,
          gradientFromStart: !stacked,
        );

        final body = stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(aspectRatio: 3 / 2, child: panel),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      20,
                      20,
                      20,
                      24,
                    ),
                    child: copy,
                  ),
                ],
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(minHeight: minPanelHeight),
                child: Stack(
                  children: [
                    // Runs past the trailing edge: the block is a composition,
                    // not a card in a list of cards.
                    PositionedDirectional(
                      top: 0,
                      bottom: 0,
                      end: -width * 0.08,
                      width: width * 0.5,
                      child: panel,
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        20,
                        24,
                        width * 0.46,
                        26,
                      ),
                      child: copy,
                    ),
                  ],
                ),
              );

        return RepaintBoundary(
          child: ClipRect(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: DesignTokens.surfaceRaised,
              ),
              // A tap anywhere the block is not already a control opens the
              // product, the way every other Mall surface behaves. The
              // nested controls — play, save, buy, View — sit deeper in the
              // tree and take their own taps first. Hidden from semantics on
              // purpose: the block already exposes an explicit "View"
              // button, and a second node saying the same thing makes the
              // block harder to read aloud rather than easier.
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                child: body,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The media: the product's reel poster where it has one, the designed tonal
/// ground where it does not. Never a product photo.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.product,
    required this.onReelTap,
    required this.onSaveTap,
    required this.playSlotController,
    required this.gradientFromStart,
  });

  final MallProductVm product;
  final void Function(MallReelRef reel)? onReelTap;
  final VoidCallback? onSaveTap;
  final MallReelPlaySlotController? playSlotController;

  /// Fades the panel into the copy column beside it rather than into the
  /// block below it.
  final bool gradientFromStart;

  @override
  Widget build(BuildContext context) {
    final strings = MallStrings.of(context);
    final reel = product.reel;
    final saveTap = onSaveTap;
    final playTap = onReelTap;
    final source = (product.brandName?.trim().isNotEmpty ?? false)
        ? product.brandName!.trim()
        : product.name.trim();
    final monogram = source.isEmpty
        ? ''
        : source.characters.first.toUpperCase();

    return Stack(
      fit: StackFit.expand,
      children: [
        // The panel breathes. One composited transform on an already
        // rasterised layer, so it costs no repaint, and it stops with
        // TickerMode and under reduced motion like everything else.
        ExcludeSemantics(
          child: MallKenBurns(
            amplitude: 1.06,
            period: const Duration(seconds: 20),
            child: reel == null
                ? MallTypeGround(seed: product.id, monogram: monogram)
                : MallNetworkImage(
                    url: reel.posterUrl,
                    placeholder: MallTypeGround(
                      seed: product.id,
                      monogram: monogram,
                    ),
                  ),
          ),
        ),
        // One flat gradient, no blur: the seam between panel and copy.
        ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: gradientFromStart
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.bottomCenter,
                end: gradientFromStart
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.topCenter,
                colors: const [
                  DesignTokens.surfaceRaised,
                  Color(0x00000000),
                ],
                stops: const [0, 0.45],
              ),
            ),
          ),
        ),
        if (reel != null && reel.isAiGenerated)
          PositionedDirectional(
            top: DesignTokens.s8,
            start: DesignTokens.s8,
            end: DesignTokens.s8,
            child: Row(
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
          ),
        if (reel != null && playTap != null)
          Center(
            child: SizedBox.square(
              dimension: DesignTokens.s48,
              child: Semantics(
                button: true,
                label: strings.watchReel,
                excludeSemantics: true,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkResponse(
                    key: MallSpotlightKeys.play,
                    onTap: () => playTap(reel),
                    radius: DesignTokens.s48 / 2,
                    child: MallReelPlaySlot(
                      id: reel.reelId,
                      controller: playSlotController,
                      builder: (context, {required holdsSlot}) => MallPlayMark(
                        primed: holdsSlot,
                        size: DesignTokens.s48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (saveTap != null)
          PositionedDirectional(
            bottom: DesignTokens.s4,
            end: DesignTokens.s4,
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
}

/// Keys the spotlight's nested controls answer to.
abstract final class MallSpotlightKeys {
  static const Key play = Key('mall-spotlight-play');
  static const Key open = Key('mall-spotlight-open');
}

/// Eyebrow, the name at hero size, the price as a numeral, the saving as a
/// slab, the deadline, and the two actions.
class _Copy extends StatelessWidget {
  const _Copy({
    required this.product,
    required this.eyebrow,
    required this.signal,
    required this.endsUtc,
    required this.now,
    required this.onTap,
    required this.onQuickAdd,
  });

  final MallProductVm product;
  final String? eyebrow;
  final MallSignal? signal;
  final DateTime? endsUtc;
  final DateTime Function()? now;
  final VoidCallback? onTap;
  final Future<bool> Function()? onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final strings = MallStrings.of(context);
    final scaler = MallMetrics.scalerOf(context);
    final reason = eyebrow?.trim();
    final brand = product.brandName?.trim();
    final discount = product.discountPercent;
    final compareAt = discount == null ? null : product.compareAtPrice;
    final ends = endsUtc;
    final open = onTap;
    // Adds, or opens the page to choose — decided by the card, not the block.
    // The pill spells out whichever it is.
    final buy = MallQuickAdd.forProduct(
      product: product,
      strings: strings,
      onAdd: onQuickAdd,
      onChoose: open,
      withLabel: true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (reason != null && reason.isNotEmpty) ...[
          MallEyebrow(reason, color: DesignTokens.primaryGreen),
          const SizedBox(height: DesignTokens.s8),
        ] else if (brand != null && brand.isNotEmpty) ...[
          MallEyebrow(brand, color: DesignTokens.textMuted),
          const SizedBox(height: DesignTokens.s8),
        ],
        Text(
          product.name,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: DesignTokens.displayFontFamily,
            fontSize: 32,
            fontWeight: FontWeight.w400,
            height: 1.08,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        // Price and the saving on one line where they fit, wrapping rather
        // than shrinking to illegibility at a large text scale.
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: DesignTokens.s12,
          runSpacing: DesignTokens.s8,
          children: [
            MoneyText(
              product.price,
              decimalDigits: MallMetrics.priceDigits(product.price),
              maxLines: 1,
              style: const TextStyle(
                fontFamily: DesignTokens.displayFontFamily,
                fontSize: 30,
                fontWeight: FontWeight.w400,
                height: 1.1,
                color: DesignTokens.textWhite,
                fontFeatures: mallTabularFigures,
              ),
            ),
            if (compareAt != null)
              MoneyText(
                compareAt,
                decimalDigits: MallMetrics.priceDigits(compareAt),
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                  color: DesignTokens.textMuted,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: DesignTokens.textMuted,
                  fontFeatures: mallTabularFigures,
                ),
              ),
            if (discount != null) _DiscountSlab(percent: discount),
          ],
        ),
        if (ends != null) ...[
          const SizedBox(height: DesignTokens.s12),
          MallCountdown(
            endsUtc: ends,
            now: now,
            builder: (context, remaining) => remaining == null
                ? const SizedBox.shrink()
                : MallSignalLine(
                    signal: MallSignal(
                      label: strings.endsIn(remaining.text),
                      semanticLabel: strings.endsIn(remaining.spoken),
                      tone: MallSignalTone.urgent,
                      icon: Icons.schedule_rounded,
                    ),
                  ),
          ),
        ] else if (signal != null) ...[
          const SizedBox(height: DesignTokens.s12),
          MallSignalLine(signal: signal!),
        ],
        const SizedBox(height: DesignTokens.s20),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: DesignTokens.s12,
          runSpacing: DesignTokens.s8,
          children: [
            ?buy,
            if (open != null)
              SizedBox(
                height: DesignTokens.minTouchTarget,
                child: TextButton(
                  key: MallSpotlightKeys.open,
                  onPressed: open,
                  style: TextButton.styleFrom(
                    foregroundColor: DesignTokens.textWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(DesignTokens.minTouchTarget, 44),
                    textStyle: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: scaler.scale(14).clamp(14.0, 18.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(strings.viewItem),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// The saving, set as the graphic it is. The one oversized numeral on the
/// page, and only ever a floored discount the server's own prices support.
class _DiscountSlab extends StatelessWidget {
  const _DiscountSlab({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final strings = MallStrings.of(context);
    return Semantics(
      label: strings.percentOff(percent),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DesignTokens.primaryGreen,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 2, 10, 4),
          child: Text(
            strings.discountBadge(percent),
            maxLines: 1,
            style: const TextStyle(
              fontFamily: DesignTokens.displayFontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              height: 1.15,
              color: DesignTokens.buttonPrimaryText,
              fontFeatures: mallTabularFigures,
            ),
          ),
        ),
      ),
    );
  }
}
