import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_mark_outline.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Network image for the Mall kit: cached, decoded at display size, faded in
/// (instantly under reduced motion) over a branded placeholder.
///
/// Fills its parent — give it bounded constraints.
class MallNetworkImage extends StatelessWidget {
  const MallNetworkImage({
    required this.url,
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder = const MallImagePlaceholder(),
  });

  final String? url;
  final BoxFit fit;
  final Alignment alignment;

  /// Shown while loading, on error, and when [url] is null or blank.
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final source = url?.trim() ?? '';
    if (source.isEmpty) return placeholder;
    final reduceMotion = MallMetrics.reduceMotion(context);
    final pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    return LayoutBuilder(
      builder: (context, constraints) => CachedNetworkImage(
        imageUrl: source,
        fit: fit,
        alignment: alignment,
        memCacheWidth: _cacheWidth(constraints, pixelRatio),
        fadeInDuration: reduceMotion
            ? Duration.zero
            : DesignTokens.motionMedium,
        fadeOutDuration: reduceMotion ? Duration.zero : DesignTokens.motionFast,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }

  /// Decode width in physical pixels. Uses the longer box side so a
  /// landscape image covering a portrait box stays sharp, bucketed to 100px so
  /// small layout changes reuse the cached bitmap.
  static int? _cacheWidth(BoxConstraints constraints, double pixelRatio) {
    final sides = [
      constraints.maxWidth,
      constraints.maxHeight,
    ].where((side) => side.isFinite && side > 0);
    if (sides.isEmpty) return null;
    final physical = sides.reduce(math.max) * pixelRatio;
    return (physical / 100).ceil() * 100;
  }
}

/// Branded, illustration-free image placeholder: a quiet tonal gradient with
/// the StyleMint mark traced faintly at its centre. Fills its parent.
class MallImagePlaceholder extends StatelessWidget {
  const MallImagePlaceholder({super.key, this.showMark = true});

  final bool showMark;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [DesignTokens.surfaceRaised, DesignTokens.bgAppBody],
          ),
        ),
        child: showMark
            ? const CustomPaint(
                painter: _BrandMarkPainter(),
                child: SizedBox.expand(),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * 0.3;
    if (side < 16) return;
    final origin = Offset(
      (size.width - side) / 2,
      (size.height - side) / 2,
    );
    final path = smBrandMarkOutlinePath(Size.square(side)).shift(origin);
    canvas
      ..drawPath(path, Paint()..color = const Color(0x0AFFFFFF))
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0x1FFFFFFF),
      );
  }

  @override
  bool shouldRepaint(_BrandMarkPainter oldDelegate) => false;
}
