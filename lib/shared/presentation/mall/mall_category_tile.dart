import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

enum MallTileShape {
  /// 1:1.
  square,

  /// 3:4 portrait.
  tall,
}

/// Image tile with a scrim and a bottom-aligned label.
class MallCategoryTile extends StatelessWidget {
  const MallCategoryTile({
    required this.category,
    super.key,
    this.shape = MallTileShape.square,
    this.onTap,
  });

  final MallCategoryVm category;
  final MallTileShape shape;
  final VoidCallback? onTap;

  static double aspectRatioOf(MallTileShape shape) =>
      shape == MallTileShape.square ? 1 : 3 / 4;

  static double heightFor(
    double width, {
    MallTileShape shape = MallTileShape.square,
  }) => width / aspectRatioOf(shape);

  static const TextStyle _labelStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: DesignTokens.textWhite,
  );

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(DesignTokens.cardRadius);
    return AspectRatio(
      aspectRatio: aspectRatioOf(shape),
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
              ExcludeSemantics(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MallNetworkImage(url: category.imageUrl),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: DesignTokens.imageScrim,
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
                        style: _labelStyle,
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
      ),
    );
  }
}
