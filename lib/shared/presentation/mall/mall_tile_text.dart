import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_signal.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Type and slot heights for one product-tile density at one text scale.
///
/// One source of truth for every product-shaped tile — the photo card, the
/// reel tile and the type tile — so a rail or a grid row can mix them and
/// still be sized once. Text slots have fixed heights, so prices align
/// across a grid row and [tileHeight] is exact.
class MallTileMetrics {
  factory MallTileMetrics(
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
    return MallTileMetrics._(
      size: size,
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

  const MallTileMetrics._({
    required this.size,
    required this.brandStyle,
    required this.nameStyle,
    required this.priceStyle,
    required this.compareStyle,
    required this.brandHeight,
    required this.nameHeight,
    required this.priceHeight,
    required this.signalHeight,
  });

  /// The metrics for [size] at [context]'s text scale.
  factory MallTileMetrics.of(
    BuildContext context, {
    MallCardSize size = MallCardSize.regular,
    bool withSignal = false,
  }) => MallTileMetrics(
    MallMetrics.scalerOf(context),
    size,
    withSignal: withSignal,
    signalHeight: withSignal ? MallSignalLine.heightFor(context) : 0,
  );

  /// Media width : height. Every product tile uses the same box, so reel
  /// posters and type tiles line up in one grid row.
  static const double mediaAspectRatio = 4 / 5;

  static const double imageGap = 10;
  static const double brandGap = 2;
  static const double nameGap = 6;
  static const double signalGap = 5;
  static const double bottomGap = 2;

  final MallCardSize size;
  final TextStyle brandStyle;
  final TextStyle nameStyle;
  final TextStyle priceStyle;
  final TextStyle compareStyle;
  final double brandHeight;
  final double nameHeight;
  final double priceHeight;

  /// Zero when the tile reserves no signal slot.
  final double signalHeight;

  bool get isCompact => size == MallCardSize.compact;

  /// Height of the brand / name / price (/ signal) stack under the media.
  double get textHeight =>
      brandHeight +
      brandGap +
      nameHeight +
      nameGap +
      priceHeight +
      (signalHeight > 0 ? signalGap + signalHeight : 0) +
      bottomGap;

  /// Exact rendered height of a tile [width] wide.
  double tileHeight(double width) =>
      (width / mediaAspectRatio + imageGap + textHeight).ceilToDouble();

  /// Exact rendered height of a [width]-wide tile at [context]'s text scale.
  static double heightFor(
    BuildContext context, {
    required double width,
    MallCardSize size = MallCardSize.regular,
    bool withSignal = false,
  }) => MallTileMetrics.of(
    context,
    size: size,
    withSignal: withSignal,
  ).tileHeight(width);
}

/// Brand, a two-line name and the price (with the struck-through original
/// when on sale) — the text every product tile carries under its media.
class MallTileText extends StatelessWidget {
  const MallTileText({
    required this.product,
    required this.metrics,
    super.key,
    this.signal,
    this.showSignal = false,
  });

  final MallProductVm product;
  final MallTileMetrics metrics;

  /// One live fact under the price.
  final MallSignal? signal;

  /// Keeps the signal slot even with nothing to say, so every tile in a rail
  /// is the same height.
  final bool showSignal;

  @override
  Widget build(BuildContext context) {
    final brand = product.brandName;
    final fact = signal;
    final compareAt = product.discountPercent == null
        ? null
        : product.compareAtPrice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
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
        const SizedBox(height: MallTileMetrics.brandGap),
        SizedBox(
          height: metrics.nameHeight,
          child: Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: metrics.nameStyle,
          ),
        ),
        const SizedBox(height: MallTileMetrics.nameGap),
        SizedBox(
          height: metrics.priceHeight,
          child: MallTilePriceRow(
            price: product.price,
            compareAtPrice: compareAt,
            priceStyle: metrics.priceStyle,
            compareStyle: metrics.compareStyle,
          ),
        ),
        if (showSignal) ...[
          const SizedBox(height: MallTileMetrics.signalGap),
          SizedBox(
            height: metrics.signalHeight,
            child: fact == null ? null : MallSignalLine(signal: fact),
          ),
        ],
        const SizedBox(height: MallTileMetrics.bottomGap),
      ],
    );
  }
}

/// Price, and the original struck through beside it when on sale. Both
/// scale down rather than truncate.
class MallTilePriceRow extends StatelessWidget {
  const MallTilePriceRow({
    required this.price,
    required this.priceStyle,
    required this.compareStyle,
    super.key,
    this.compareAtPrice,
  });

  final Money price;
  final Money? compareAtPrice;
  final TextStyle priceStyle;
  final TextStyle compareStyle;

  @override
  Widget build(BuildContext context) {
    final compareAt = compareAtPrice;
    return Row(
      children: [
        Flexible(
          flex: 3,
          child: MallScaleDownStart(
            child: MoneyText(
              price,
              decimalDigits: MallMetrics.priceDigits(price),
              maxLines: 1,
              style: priceStyle,
            ),
          ),
        ),
        if (compareAt != null) ...[
          const SizedBox(width: DesignTokens.s6),
          Flexible(
            flex: 2,
            child: MallScaleDownStart(
              child: MoneyText(
                compareAt,
                decimalDigits: MallMetrics.priceDigits(compareAt),
                maxLines: 1,
                style: compareStyle,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Shrinks its child rather than letting it truncate, kept at the leading
/// edge.
class MallScaleDownStart extends StatelessWidget {
  const MallScaleDownStart({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: child,
  );
}

/// Discount, New and Low stock pills, in that order. Empty when the product
/// earns none of them.
List<Widget> mallTileBadges(MallStrings strings, MallProductVm product) {
  final discount = product.discountPercent;
  return [
    if (discount != null)
      MallBadge(
        label: strings.discountBadge(discount),
        tone: MallBadgeTone.accent,
      ),
    if (product.isNew)
      MallBadge(label: strings.newBadge, tone: MallBadgeTone.light),
    if (product.isLowStock)
      MallBadge(label: strings.lowStockBadge, tone: MallBadgeTone.warning),
  ];
}

/// The one spoken label for a product tile: brand, name, price, the original
/// price, the discount, its badges, the rating, its signal and anything the
/// tile adds ([extras], e.g. the reel and its length).
String mallTileSemanticLabel(
  MallStrings strings,
  MallProductVm product, {
  double? rating,
  MallSignal? signal,
  List<String> extras = const [],
}) {
  final compareAt = product.discountPercent == null
      ? null
      : product.compareAtPrice;
  final discount = product.discountPercent;
  return [
    ?product.brandName,
    product.name,
    formatMoney(
      product.price,
      decimalDigits: MallMetrics.priceDigits(product.price),
    ),
    if (compareAt != null)
      strings.wasPrice(
        formatMoney(
          compareAt,
          decimalDigits: MallMetrics.priceDigits(compareAt),
        ),
      ),
    if (discount != null) strings.percentOff(discount),
    if (product.isNew) strings.newBadge,
    if (product.isLowStock) strings.lowStockBadge,
    if (rating != null) strings.rating(rating),
    ?signal?.spoken,
    ...extras,
  ].join(', ');
}
