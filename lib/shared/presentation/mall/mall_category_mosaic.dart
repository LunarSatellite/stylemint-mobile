import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Compact category shortcuts: useful navigation, never a competing content
/// section. Each destination is a round image or category-aware icon with its
/// real server label underneath, all kept to one horizontal row.
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
  static const double tileWidth = 76;
  static const double imageSize = 54;

  static Key tileKey(MallCategoryVm category) =>
      ValueKey<String>('mall-category-${category.id}');

  static double tileHeightFor(BuildContext context) =>
      (imageSize +
              DesignTokens.s8 +
              MallMetrics.textHeight(
                MallMetrics.scalerOf(context),
                fontSize: _CategoryShortcut.labelStyle.fontSize!,
                lineHeight: _CategoryShortcut.labelStyle.height!,
                lines: 2,
              ))
          .clamp(92, 112);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, category) in categories.indexed) ...[
                if (index > 0) const SizedBox(width: gap),
                SizedBox(
                  key: tileKey(category),
                  width: tileWidth,
                  child: _CategoryShortcut(
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

class _CategoryShortcut extends StatelessWidget {
  const _CategoryShortcut({
    required this.category,
    required this.index,
    required this.onTap,
  });

  final MallCategoryVm category;
  final int index;
  final VoidCallback? onTap;

  static const TextStyle labelStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    height: 1.16,
    color: DesignTokens.textWhite,
  );

  static const List<List<Color>> _palettes = [
    [Color(0xFF31453A), Color(0xFF1B2720)],
    [Color(0xFF3A3542), Color(0xFF211E26)],
    [Color(0xFF293C4A), Color(0xFF17232B)],
    [Color(0xFF46343D), Color(0xFF291E24)],
    [Color(0xFF423D2D), Color(0xFF252219)],
  ];

  @override
  Widget build(BuildContext context) {
    final image = category.imageUrl?.trim();
    final hasImage = image != null && image.isNotEmpty;
    final enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: category.label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x38FFFFFF)),
                    boxShadow: DesignTokens.shadowCard,
                  ),
                  child: ClipOval(
                    child: SizedBox.square(
                      dimension: MallCategoryMosaic.imageSize,
                      child: hasImage
                          ? MallNetworkImage(url: image)
                          : DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: AlignmentDirectional.topStart,
                                  end: AlignmentDirectional.bottomEnd,
                                  colors: _palettes[index % _palettes.length],
                                ),
                              ),
                              child: Icon(
                                _iconFor(category.label),
                                size: 25,
                                color: const Color(0xE6FFFFFF),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  category.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: labelStyle,
                ),
              ],
            ),
          ),
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
