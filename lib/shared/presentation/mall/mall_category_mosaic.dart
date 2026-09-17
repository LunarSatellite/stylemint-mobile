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
  static const double gap = 10;
  static const double tileWidth = 80;
  static const double orbSize = 60;
  static const double imageSize = 54;

  static Key tileKey(MallCategoryVm category) =>
      ValueKey<String>('mall-category-${category.id}');

  static double tileHeightFor(BuildContext context) =>
      (orbSize +
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
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.16,
    letterSpacing: 0.05,
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
                SizedBox.square(
                  dimension: MallCategoryMosaic.orbSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: AlignmentDirectional.topStart,
                              end: AlignmentDirectional.bottomEnd,
                              colors: [
                                Color(0x70FFFFFF),
                                Color(0x6032D477),
                                Color(0x24FFFFFF),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x5C000000),
                                offset: Offset(0, 8),
                                blurRadius: 18,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(1.5),
                            child: ClipOval(
                              child: SizedBox.square(
                                dimension: MallCategoryMosaic.imageSize,
                                child: hasImage
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          MallNetworkImage(url: image),
                                          DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Color(0x00000000),
                                                  Color(0x38000000),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin:
                                                AlignmentDirectional.topStart,
                                            end: AlignmentDirectional.bottomEnd,
                                            colors:
                                                _palettes[index %
                                                    _palettes.length],
                                          ),
                                        ),
                                        child: Icon(
                                          _iconFor(category.label),
                                          size: 25,
                                          color: const Color(0xF2FFFFFF),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        end: -1,
                        bottom: 1,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: DesignTokens.primaryGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x6632D477),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: SizedBox.square(
                            dimension: 19,
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 11,
                              color: DesignTokens.buttonPrimaryText,
                            ),
                          ),
                        ),
                      ),
                    ],
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
