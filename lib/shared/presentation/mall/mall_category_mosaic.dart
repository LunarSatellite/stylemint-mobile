import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// An editorial category gallery: one wide opening destination followed by a
/// balanced two-column grid.
///
/// The home contract often carries no category artwork. In that case each
/// destination gets a quiet, category-aware icon and tonal backdrop rather
/// than an empty rectangle. Real imagery takes over automatically whenever
/// the backend supplies it.
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
  static const double gap = 10;

  static Key tileKey(MallCategoryVm category) =>
      ValueKey<String>('mall-category-${category.id}');

  static double _labelHeight(BuildContext context) => MallMetrics.textHeight(
    MallMetrics.scalerOf(context),
    fontSize: _CategoryTile.labelStyle.fontSize!,
    lineHeight: _CategoryTile.labelStyle.height!,
    lines: 2,
  );

  static double featuredHeightFor(BuildContext context) =>
      (_labelHeight(context) + 92).clamp(156, 196);

  static double tileHeightFor(BuildContext context) =>
      (_labelHeight(context) + 64).clamp(122, 162);

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    final featured = categories.first;
    final remaining = categories.skip(1).toList(growable: false);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: gutter),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            if (!width.isFinite || width <= 0) {
              return const SizedBox.shrink();
            }
            final halfWidth = (width - gap) / 2;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: featuredHeightFor(context),
                  child: _CategoryTile(
                    key: tileKey(featured),
                    category: featured,
                    index: 0,
                    featured: true,
                    onTap: onOpen == null ? null : () => onOpen!(featured),
                  ),
                ),
                if (remaining.isNotEmpty) ...[
                  const SizedBox(height: gap),
                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final (position, category) in remaining.indexed)
                        SizedBox(
                          width: halfWidth,
                          height: tileHeightFor(context),
                          child: _CategoryTile(
                            key: tileKey(category),
                            category: category,
                            index: position + 1,
                            onTap: onOpen == null
                                ? null
                                : () => onOpen!(category),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.index,
    required this.onTap,
    this.featured = false,
    super.key,
  });

  final MallCategoryVm category;
  final int index;
  final bool featured;
  final VoidCallback? onTap;

  static const TextStyle labelStyle = TextStyle(
    fontFamily: DesignTokens.displayFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.12,
    letterSpacing: -0.25,
    color: DesignTokens.textWhite,
  );

  static const List<List<Color>> _palettes = [
    [Color(0xFF243229), Color(0xFF111713)],
    [Color(0xFF29272F), Color(0xFF17161B)],
    [Color(0xFF1F2B36), Color(0xFF111820)],
    [Color(0xFF34272E), Color(0xFF1C1519)],
    [Color(0xFF302D22), Color(0xFF19170F)],
    [Color(0xFF222D2E), Color(0xFF111718)],
  ];

  @override
  Widget build(BuildContext context) {
    final image = category.imageUrl?.trim();
    final hasImage = image != null && image.isNotEmpty;
    final palette = _palettes[index % _palettes.length];
    final radius = BorderRadius.circular(
      featured ? DesignTokens.radiusLarge : DesignTokens.cardRadius,
    );
    final icon = _iconFor(category.label);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: featured
            ? DesignTokens.shadowLifted
            : DesignTokens.shadowCard,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: palette,
                  ),
                ),
              ),
            ),
            if (hasImage) ...[
              ExcludeSemantics(child: MallNetworkImage(url: image)),
              const ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.topCenter,
                      end: AlignmentDirectional.bottomCenter,
                      colors: [Color(0x14000000), Color(0xD9000000)],
                      stops: [0.2, 1],
                    ),
                  ),
                ),
              ),
            ] else
              PositionedDirectional(
                top: featured ? 18 : 12,
                end: featured ? 18 : 12,
                child: ExcludeSemantics(
                  child: Icon(
                    icon,
                    size: featured ? 78 : 54,
                    color: const Color(0x26FFFFFF),
                  ),
                ),
              ),
            PositionedDirectional(
              start: featured ? 18 : 12,
              end: featured ? 16 : 10,
              bottom: featured ? 16 : 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ExcludeSemantics(
                      child: Text(
                        category.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle.copyWith(
                          fontSize: featured ? 24 : 18,
                          height: featured ? 1.08 : 1.12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  ExcludeSemantics(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: hasImage
                            ? const Color(0xB30B0E0C)
                            : const Color(0x18FFFFFF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: SizedBox.square(
                        dimension: featured ? 38 : 32,
                        child: Icon(
                          Icons.arrow_outward_rounded,
                          size: featured ? 18 : 15,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

  static IconData _iconFor(String label) {
    final value = label.toLowerCase();
    if (value.contains('fashion') ||
        value.contains('cloth') ||
        value.contains('wear')) {
      return Icons.checkroom_rounded;
    }
    if (value.contains('home') || value.contains('living')) {
      return Icons.chair_alt_rounded;
    }
    if (value.contains('tech') ||
        value.contains('electronic') ||
        value.contains('gadget')) {
      return Icons.devices_rounded;
    }
    if (value.contains('beauty') ||
        value.contains('skin') ||
        value.contains('wellness')) {
      return Icons.spa_rounded;
    }
    if (value.contains('shoe') ||
        value.contains('sneaker') ||
        value.contains('sport')) {
      return Icons.directions_run_rounded;
    }
    return Icons.category_outlined;
  }
}
