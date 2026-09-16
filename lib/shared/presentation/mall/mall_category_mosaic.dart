import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Categories as a graphic mosaic of uneven tiles.
///
/// Catalog categories carry no artwork — `imageUrl` is null on every card the
/// home contract sends today — so this block is built to be typographic
/// first: tone, width and weight do the work a photograph would. A tile that
/// *does* arrive with an image uses it, so the block needs no rewrite when
/// the backend starts sending them.
///
/// Tile heights are measured from the ambient text scale, so a two-line
/// category name at 1.3x still fits its box.
class MallCategoryMosaic extends StatelessWidget {
  const MallCategoryMosaic({
    required this.categories,
    required this.semanticLabel,
    super.key,
    this.onOpen,
  });

  final List<MallCategoryVm> categories;

  /// Names the block for assistive technology, e.g. "Shop by category".
  final String semanticLabel;
  final void Function(MallCategoryVm category)? onOpen;

  static const double gutter = DesignTokens.s16;
  static const double gap = DesignTokens.s8;

  /// The repeating rhythm of row shapes. Uneven by design: a mosaic that
  /// tiles evenly is just a grid.
  static const List<List<double>> rhythm = [
    [0.58, 0.42],
    [0.42, 0.58],
    [0.34, 0.33, 0.33],
  ];

  /// Exact tile height at the ambient text scale.
  static double tileHeightFor(BuildContext context) =>
      MallMetrics.textHeight(
        MallMetrics.scalerOf(context),
        fontSize: _MosaicTile.labelStyle.fontSize!,
        lineHeight: _MosaicTile.labelStyle.height!,
        lines: 2,
      ) +
      44;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    final height = tileHeightFor(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth - gutter * 2;
          if (available <= 0) return const SizedBox.shrink();
          final rows = <Widget>[];
          var index = 0;
          var step = 0;
          while (index < categories.length) {
            final shape = rhythm[step % rhythm.length];
            final take = categories.length - index < shape.length
                ? categories.length - index
                : shape.length;
            rows.add(
              _MosaicRow(
                categories: categories.sublist(index, index + take),
                shares: shape.take(take).toList(),
                available: available,
                height: height,
                firstIndex: index,
                onOpen: onOpen,
              ),
            );
            index += take;
            step++;
          }
          return Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: gutter,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (position, row) in rows.indexed) ...[
                  if (position > 0) const SizedBox(height: gap),
                  row,
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// One row of the mosaic, its tiles sharing the width by [shares].
class _MosaicRow extends StatelessWidget {
  const _MosaicRow({
    required this.categories,
    required this.shares,
    required this.available,
    required this.height,
    required this.firstIndex,
    required this.onOpen,
  });

  final List<MallCategoryVm> categories;
  final List<double> shares;
  final double available;
  final double height;
  final int firstIndex;
  final void Function(MallCategoryVm category)? onOpen;

  @override
  Widget build(BuildContext context) {
    const gap = MallCategoryMosaic.gap;
    final total = shares.reduce((a, b) => a + b);
    final free = available - gap * (categories.length - 1);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (position, category) in categories.indexed) ...[
          if (position > 0) const SizedBox(width: gap),
          SizedBox(
            width: free * (shares[position] / total),
            height: height,
            child: _MosaicTile(
              category: category,
              toneIndex: firstIndex + position,
              onTap: onOpen == null ? null : () => onOpen!(category),
            ),
          ),
        ],
      ],
    );
  }
}

/// One mosaic tile: a block of tone (or the category's image, when one ever
/// arrives) carrying the name and a direction mark.
class _MosaicTile extends StatelessWidget {
  const _MosaicTile({
    required this.category,
    required this.toneIndex,
    required this.onTap,
  });

  final MallCategoryVm category;
  final int toneIndex;
  final VoidCallback? onTap;

  static const TextStyle labelStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: DesignTokens.textWhite,
  );

  /// Tones cycle so the block has rhythm without any tile being decorative
  /// noise; every fourth tile takes the accent.
  static const List<Color> _tones = [
    DesignTokens.surfaceRaised,
    DesignTokens.bgAppBody,
    DesignTokens.bgAppBodyLight,
    DesignTokens.primaryGreenDark,
  ];

  @override
  Widget build(BuildContext context) {
    final image = category.imageUrl;
    final hasImage = image != null && image.trim().isNotEmpty;
    final tone = _tones[toneIndex % _tones.length];
    final accent = tone == DesignTokens.primaryGreenDark;
    final radius = BorderRadius.circular(DesignTokens.radiusMedium);

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, color: tone),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage) ...[
                    MallNetworkImage(url: image),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: DesignTokens.imageScrim,
                      ),
                    ),
                  ],
                  PositionedDirectional(
                    top: DesignTokens.s12,
                    end: DesignTokens.s12,
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: 14,
                      color: accent
                          ? DesignTokens.primaryGreen
                          : DesignTokens.sectionOnBase,
                    ),
                  ),
                  PositionedDirectional(
                    start: DesignTokens.s12,
                    end: DesignTokens.s12,
                    bottom: DesignTokens.s12,
                    child: Text(
                      category.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle,
                    ),
                  ),
                ],
              ),
            ),
            MallTapOverlay(
              semanticLabel: category.label,
              onTap: onTap,
              borderRadius: radius,
            ),
          ],
        ),
      ),
    );
  }
}
