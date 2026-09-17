import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Compact category navigation kept to one horizontal row.
///
/// The home contract often carries no category artwork. Those destinations
/// use a quiet category-aware icon; real imagery takes over automatically
/// whenever the backend supplies it.
class MallCategoryMosaic extends StatelessWidget {
  const MallCategoryMosaic({
    required this.categories,
    required this.semanticLabel,
    super.key,
    this.onOpen,
  });

  final List<MallCategoryVm> categories;
  final String semanticLabel;
  final void Function(MallCategoryVm category)? onOpen;

  static const double gutter = DesignTokens.s16;
  static const double gap = DesignTokens.s8;
  static const double tileWidth = 116;

  static Key tileKey(MallCategoryVm category) =>
      ValueKey<String>('mall-category-${category.id}');

  static double tileHeightFor(BuildContext context) =>
      (MallMetrics.textHeight(
                MallMetrics.scalerOf(context),
                fontSize: _CategoryTile.labelStyle.fontSize!,
                lineHeight: _CategoryTile.labelStyle.height!,
                lines: 2,
              ) +
              62)
          .clamp(108, 136);

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: SizedBox(
        height: tileHeightFor(context),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: gutter),
          child: Row(
            children: [
              for (final (index, category) in categories.indexed) ...[
                if (index > 0) const SizedBox(width: gap),
                SizedBox(
                  key: tileKey(category),
                  width: tileWidth,
                  child: _CategoryTile(
                    category: category,
                    index: index,
                    onTap: onOpen == null ? null : () => onOpen!(category),
                  ),
                ),
              ],
            ],
          ),
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
  });

  final MallCategoryVm category;
  final int index;
  final VoidCallback? onTap;

  static const TextStyle labelStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    height: 1.18,
    color: DesignTokens.textWhite,
  );

  static const List<List<Color>> _palettes = [
    [Color(0xFF25322A), Color(0xFF151B17)],
    [Color(0xFF2C2932), Color(0xFF19171D)],
    [Color(0xFF202D38), Color(0xFF121A21)],
    [Color(0xFF352830), Color(0xFF1D161A)],
    [Color(0xFF312E23), Color(0xFF1A180F)],
  ];

  @override
  Widget build(BuildContext context) {
    final image = category.imageUrl?.trim();
    final hasImage = image != null && image.isNotEmpty;
    final radius = BorderRadius.circular(DesignTokens.cardRadius);

    return DecoratedBox(
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
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: _palettes[index % _palettes.length],
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
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x10000000), Color(0xD9000000)],
                    ),
                  ),
                ),
              ),
            ] else
              PositionedDirectional(
                top: DesignTokens.s12,
                end: DesignTokens.s12,
                child: ExcludeSemantics(
                  child: Icon(
                    _iconFor(category.label),
                    size: 38,
                    color: const Color(0x38FFFFFF),
                  ),
                ),
              ),
            PositionedDirectional(
              start: DesignTokens.s12,
              end: DesignTokens.s8,
              bottom: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ExcludeSemantics(
                      child: Text(
                        category.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s4),
                  const ExcludeSemantics(
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: 14,
                      color: Color(0xCCFFFFFF),
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
    if (value.contains('fashion') || value.contains('wear')) {
      return Icons.checkroom_rounded;
    }
    if (value.contains('home') || value.contains('living')) {
      return Icons.chair_alt_rounded;
    }
    if (value.contains('tech') || value.contains('electronic')) {
      return Icons.devices_rounded;
    }
    if (value.contains('beauty') || value.contains('skin')) {
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
