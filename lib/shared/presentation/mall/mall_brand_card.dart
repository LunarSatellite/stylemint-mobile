import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Brand card: 16:9 cover, overlapping logo tile, name with verified tick and
/// a two-line tagline.
class MallBrandCard extends StatelessWidget {
  const MallBrandCard({required this.brand, super.key, this.onTap});

  final MallBrandVm brand;
  final VoidCallback? onTap;

  /// Suggested rail item width.
  static const double defaultWidth = 260;

  /// Exact rendered height of a card [width] wide at the ambient text scale.
  static double heightFor(BuildContext context, {required double width}) =>
      _BrandMetrics(MallMetrics.scalerOf(context)).cardHeight(width);

  static const TextStyle _nameStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: DesignTokens.textWhite,
  );

  static const TextStyle _taglineStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: DesignTokens.textMuted,
  );

  @override
  Widget build(BuildContext context) {
    final strings = MallStrings.of(context);
    final metrics = _BrandMetrics(MallMetrics.scalerOf(context));
    final item = brand;
    final tagline = item.tagline?.trim();
    final radius = BorderRadius.circular(DesignTokens.cardRadius);
    final label = [
      item.name,
      if (item.isVerified) strings.verified,
      if (tagline != null && tagline.isNotEmpty) tagline,
    ].join(', ');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: radius,
        boxShadow: DesignTokens.shadowCard,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: _BrandMetrics.coverAspectRatio,
                    child: MallNetworkImage(url: item.coverUrl),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      _BrandMetrics.inset,
                      0,
                      _BrandMetrics.inset,
                      _BrandMetrics.bottomGap,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // The logo overlaps the cover by half its size.
                        SizedBox(
                          height: _BrandMetrics.logoSize / 2,
                          child: OverflowBox(
                            alignment: AlignmentDirectional.bottomStart,
                            maxHeight: _BrandMetrics.logoSize,
                            child: MallAvatar(
                              name: item.name,
                              imageUrl: item.logoUrl,
                              size: _BrandMetrics.logoSize,
                              shape: MallAvatarShape.roundedSquare,
                              ringColor: DesignTokens.surfaceRaised,
                              ringWidth: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: _BrandMetrics.logoGap),
                        SizedBox(
                          height: metrics.nameHeight,
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _nameStyle,
                                ),
                              ),
                              if (item.isVerified) ...[
                                const SizedBox(width: DesignTokens.s4),
                                const MallVerifiedBadge(size: 15),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: _BrandMetrics.nameGap),
                        SizedBox(
                          height: metrics.taglineHeight,
                          child: tagline == null
                              ? null
                              : Text(
                                  tagline,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: _taglineStyle,
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: MallTapOverlay(
                semanticLabel: label,
                onTap: onTap,
                borderRadius: radius,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMetrics {
  _BrandMetrics(TextScaler scaler)
    : nameHeight = MallMetrics.textHeight(
        scaler,
        fontSize: 15,
        lineHeight: 1.3,
      ),
      taglineHeight = MallMetrics.textHeight(
        scaler,
        fontSize: 12.5,
        lineHeight: 1.45,
        lines: 2,
      );

  static const double coverAspectRatio = 16 / 9;
  static const double logoSize = 52;
  static const double logoGap = 10;
  static const double nameGap = 4;
  static const double bottomGap = 14;
  static const double inset = 14;

  final double nameHeight;
  final double taglineHeight;

  double cardHeight(double width) =>
      (width / coverAspectRatio +
              logoSize / 2 +
              logoGap +
              nameHeight +
              nameGap +
              taglineHeight +
              bottomGap)
          .ceilToDouble();
}
