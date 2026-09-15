import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Editorial collection card: full-bleed cover with eyebrow, title, preview
/// thumbnails and item count set over a scrim.
class MallCollectionCard extends StatelessWidget {
  const MallCollectionCard({
    required this.collection,
    super.key,
    this.onTap,
    this.aspectRatio = 4 / 5,
  });

  final MallCollectionVm collection;
  final VoidCallback? onTap;

  /// Width : height of the card.
  final double aspectRatio;

  /// Suggested rail item width.
  static const double defaultWidth = 240;

  static double heightFor(double width, {double aspectRatio = 4 / 5}) =>
      width / aspectRatio;

  static const TextStyle _titleStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: DesignTokens.textWhite,
  );

  static const TextStyle _countStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: DesignTokens.textLight,
  );

  @override
  Widget build(BuildContext context) {
    final strings = MallStrings.of(context);
    final item = collection;
    final eyebrow = item.eyebrow;
    final count = item.itemCount;
    final previews = item.previewImageUrls
        .where((url) => url.trim().isNotEmpty)
        .take(3)
        .toList();
    final radius = BorderRadius.circular(DesignTokens.cardRadius);
    final label = [
      ?eyebrow,
      item.title,
      if (count != null) strings.itemCount(count),
    ].join(', ');

    return AspectRatio(
      aspectRatio: aspectRatio,
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
                    MallNetworkImage(url: item.coverUrl),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: DesignTokens.imageScrim,
                      ),
                    ),
                    PositionedDirectional(
                      start: DesignTokens.s16,
                      end: DesignTokens.s16,
                      bottom: DesignTokens.s16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (eyebrow != null) ...[
                            MallEyebrow(eyebrow, color: DesignTokens.textLight),
                            const SizedBox(height: DesignTokens.s6),
                          ],
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _titleStyle,
                          ),
                          if (previews.isNotEmpty) ...[
                            const SizedBox(height: DesignTokens.s12),
                            _PreviewStrip(urls: previews),
                          ],
                          if (count != null) ...[
                            const SizedBox(height: DesignTokens.s8),
                            Text(
                              strings.itemCount(count),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _countStyle,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              MallTapOverlay(
                semanticLabel: label,
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

/// Up to three thumbnails — as many as fit the available width.
class _PreviewStrip extends StatelessWidget {
  const _PreviewStrip({required this.urls});

  final List<String> urls;

  static const double _thumb = 36;
  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fit = ((constraints.maxWidth + _gap) / (_thumb + _gap))
            .floor()
            .clamp(0, urls.length);
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: _gap,
          children: [
            for (final url in urls.take(fit))
              SizedBox.square(
                dimension: _thumb,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  child: MallNetworkImage(
                    url: url,
                    placeholder: const MallImagePlaceholder(showMark: false),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
