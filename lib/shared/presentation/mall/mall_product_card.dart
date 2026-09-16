import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_signal.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Product card: a 4:5 image with badges, rating and save heart, then brand,
/// a two-line name and the price (with strikethrough original when on sale).
///
/// Text sits on the page rather than in a boxed card — the image carries the
/// depth. Text slots have fixed heights, so prices align across a grid row
/// and [heightFor] is exact.
class MallProductCard extends StatelessWidget {
  const MallProductCard({
    required this.product,
    super.key,
    this.size = MallCardSize.regular,
    this.onTap,
    this.onSaveTap,
    this.showRating = true,
    this.signal,
    this.reserveSignal = false,
  });

  final MallProductVm product;
  final MallCardSize size;
  final VoidCallback? onTap;

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

  /// Image width : height.
  static const double imageAspectRatio = 4 / 5;

  /// Exact rendered height of a card [width] wide at the ambient text scale.
  ///
  /// Pass [withSignal] to match cards built with a signal slot.
  static double heightFor(
    BuildContext context, {
    required double width,
    MallCardSize size = MallCardSize.regular,
    bool withSignal = false,
  }) => _ProductCardMetrics(
    MallMetrics.scalerOf(context),
    size,
    withSignal: withSignal,
    signalHeight: withSignal ? MallSignalLine.heightFor(context) : 0,
  ).cardHeight(width);

  @override
  Widget build(BuildContext context) {
    final strings = MallStrings.of(context);
    final fact = signal;
    final showSignal = reserveSignal || fact != null;
    final metrics = _ProductCardMetrics(
      MallMetrics.scalerOf(context),
      size,
      withSignal: showSignal,
      signalHeight: showSignal ? MallSignalLine.heightFor(context) : 0,
    );
    final item = product;
    final discount = item.discountPercent;
    final compareAt = discount == null ? null : item.compareAtPrice;
    final rating = showRating ? item.rating : null;
    final saveTap = onSaveTap;
    final radius = BorderRadius.circular(
      size == MallCardSize.compact
          ? DesignTokens.radiusMedium
          : DesignTokens.cardRadius,
    );

    final badges = <Widget>[
      if (discount != null)
        MallBadge(
          label: strings.discountBadge(discount),
          tone: MallBadgeTone.accent,
        ),
      if (item.isNew)
        MallBadge(label: strings.newBadge, tone: MallBadgeTone.light),
      if (item.isLowStock)
        MallBadge(label: strings.lowStockBadge, tone: MallBadgeTone.warning),
    ];

    final brand = item.brandName;
    final visual = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: imageAspectRatio,
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
                  MallNetworkImage(url: item.imageUrl),
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
        const SizedBox(height: _ProductCardMetrics.imageGap),
        SizedBox(
          height: metrics.brandHeight,
          child: brand == null
              ? null
              : Text(
                  brand.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metrics.brandStyle,
                ),
        ),
        const SizedBox(height: _ProductCardMetrics.brandGap),
        SizedBox(
          height: metrics.nameHeight,
          child: Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: metrics.nameStyle,
          ),
        ),
        const SizedBox(height: _ProductCardMetrics.nameGap),
        SizedBox(
          height: metrics.priceHeight,
          child: Row(
            children: [
              Flexible(
                flex: 3,
                child: _ScaleDownStart(
                  child: MoneyText(
                    item.price,
                    decimalDigits: MallMetrics.priceDigits(item.price),
                    maxLines: 1,
                    style: metrics.priceStyle,
                  ),
                ),
              ),
              if (compareAt != null) ...[
                const SizedBox(width: DesignTokens.s6),
                Flexible(
                  flex: 2,
                  child: _ScaleDownStart(
                    child: MoneyText(
                      compareAt,
                      decimalDigits: MallMetrics.priceDigits(compareAt),
                      maxLines: 1,
                      style: metrics.compareStyle,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showSignal) ...[
          const SizedBox(height: _ProductCardMetrics.signalGap),
          SizedBox(
            height: metrics.signalHeight,
            child: fact == null ? null : MallSignalLine(signal: fact),
          ),
        ],
        const SizedBox(height: _ProductCardMetrics.bottomGap),
      ],
    );

    return Stack(
      children: [
        ExcludeSemantics(child: visual),
        Positioned.fill(
          child: MallTapOverlay(
            semanticLabel: _semanticLabel(strings, compareAt, discount, rating),
            onTap: onTap,
            borderRadius: radius,
          ),
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

  String _semanticLabel(
    MallStrings strings,
    Money? compareAt,
    int? discount,
    double? rating,
  ) {
    final item = product;
    final brand = item.brandName;
    return [
      ?brand,
      item.name,
      formatMoney(
        item.price,
        decimalDigits: MallMetrics.priceDigits(item.price),
      ),
      if (compareAt != null)
        strings.wasPrice(
          formatMoney(
            compareAt,
            decimalDigits: MallMetrics.priceDigits(compareAt),
          ),
        ),
      if (discount != null) strings.percentOff(discount),
      if (item.isNew) strings.newBadge,
      if (item.isLowStock) strings.lowStockBadge,
      if (rating != null) strings.rating(rating),
      ?signal?.spoken,
    ].join(', ');
  }
}

class _ScaleDownStart extends StatelessWidget {
  const _ScaleDownStart({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: child,
  );
}

/// Type and slot heights for one card density at one text scale.
class _ProductCardMetrics {
  factory _ProductCardMetrics(
    TextScaler scaler,
    MallCardSize size, {
    required bool withSignal,
    required double signalHeight,
  }) {
    final compact = size == MallCardSize.compact;
    final brandStyle = DesignTokens.eyebrow.copyWith(
      fontSize: compact ? 10 : 10.5,
      letterSpacing: 0.8,
    );
    final nameStyle = TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: compact ? 13 : 14,
      fontWeight: FontWeight.w500,
      height: 1.35,
      color: DesignTokens.textWhite,
    );
    final priceStyle = TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: compact ? 14 : 15.5,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: DesignTokens.textWhite,
    );
    final compareStyle = TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: compact ? 11.5 : 12,
      fontWeight: FontWeight.w400,
      height: 1.3,
      color: DesignTokens.textMuted,
      decoration: TextDecoration.lineThrough,
      decorationColor: DesignTokens.textMuted,
    );
    double lines(TextStyle style, [int count = 1]) => MallMetrics.textHeight(
      scaler,
      fontSize: style.fontSize!,
      lineHeight: style.height!,
      lines: count,
    );
    final price = lines(priceStyle);
    final compare = lines(compareStyle);
    return _ProductCardMetrics._(
      brandStyle: brandStyle,
      nameStyle: nameStyle,
      priceStyle: priceStyle,
      compareStyle: compareStyle,
      brandHeight: lines(brandStyle),
      nameHeight: lines(nameStyle, 2),
      priceHeight: price > compare ? price : compare,
      signalHeight: withSignal ? signalHeight : 0,
    );
  }

  const _ProductCardMetrics._({
    required this.brandStyle,
    required this.nameStyle,
    required this.priceStyle,
    required this.compareStyle,
    required this.brandHeight,
    required this.nameHeight,
    required this.priceHeight,
    required this.signalHeight,
  });

  static const double imageGap = 10;
  static const double brandGap = 2;
  static const double nameGap = 6;
  static const double signalGap = 5;
  static const double bottomGap = 2;

  final TextStyle brandStyle;
  final TextStyle nameStyle;
  final TextStyle priceStyle;
  final TextStyle compareStyle;
  final double brandHeight;
  final double nameHeight;
  final double priceHeight;

  /// Zero when the card reserves no signal slot.
  final double signalHeight;

  double cardHeight(double width) =>
      (width / MallProductCard.imageAspectRatio +
              imageGap +
              brandHeight +
              brandGap +
              nameHeight +
              nameGap +
              priceHeight +
              (signalHeight > 0 ? signalGap + signalHeight : 0) +
              bottomGap)
          .ceilToDouble();
}
