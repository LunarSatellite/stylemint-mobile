import 'package:flutter/widgets.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_product_card.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_rail.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_reel_card.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_shimmer.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

enum _SkeletonShape { box, line, circle }

/// Loading placeholder primitives built on [SmShimmer]. The shimmer sweep
/// follows the text direction and stops (static tone) under reduced motion.
/// Skeletons are hidden from assistive technology — announce loading on the
/// surrounding rail or grid instead.
class SmSkeleton extends StatelessWidget {
  const SmSkeleton.box({
    super.key,
    this.width,
    this.height,
    this.radius = DesignTokens.radiusMedium,
  }) : _shape = _SkeletonShape.box;

  const SmSkeleton.line({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 4,
  }) : _shape = _SkeletonShape.line;

  const SmSkeleton.circle({required double diameter, super.key})
    : width = diameter,
      height = diameter,
      radius = diameter / 2,
      _shape = _SkeletonShape.circle;

  final double? width;
  final double? height;
  final double radius;
  final _SkeletonShape _shape;

  @override
  Widget build(BuildContext context) {
    final enabled = !MallMetrics.reduceMotion(context);
    return ExcludeSemantics(
      child: switch (_shape) {
        _SkeletonShape.circle => SmShimmer.circle(
          radius: radius,
          enabled: enabled,
        ),
        _SkeletonShape.box || _SkeletonShape.line => SmShimmer.rectangle(
          width: width,
          height: height,
          radius: radius,
          enabled: enabled,
        ),
      },
    );
  }
}

/// Skeleton matching [MallProductCard]'s footprint exactly.
class SmSkeletonProductCard extends StatelessWidget {
  const SmSkeletonProductCard({
    required this.width,
    super.key,
    this.size = MallCardSize.regular,
  });

  final double width;
  final MallCardSize size;

  @override
  Widget build(BuildContext context) {
    final height = MallProductCard.heightFor(context, width: width, size: size);
    final imageHeight = width / MallProductCard.imageAspectRatio;
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmSkeleton.box(
            width: width,
            height: imageHeight,
            radius: size == MallCardSize.compact
                ? DesignTokens.radiusMedium
                : DesignTokens.cardRadius,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SmSkeleton.line(width: width * 0.4, height: 8),
                SmSkeleton.line(width: width * 0.9, height: 10),
                SmSkeleton.line(width: width * 0.6, height: 10),
                SmSkeleton.line(width: width * 0.35),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton matching [MallReelCard]'s 9:16 footprint.
class SmSkeletonReelCard extends StatelessWidget {
  const SmSkeletonReelCard({required this.width, super.key});

  final double width;

  @override
  Widget build(BuildContext context) => SmSkeleton.box(
    width: width,
    height: MallReelCard.heightFor(width),
    radius: DesignTokens.cardRadius,
  );
}

/// A loading [MallRail]: [count] placeholders that do not scroll, announced
/// as loading.
class SmSkeletonRail extends StatelessWidget {
  const SmSkeletonRail({
    required this.itemWidth,
    required this.height,
    super.key,
    this.count = 4,
    this.itemBuilder,
    this.semanticLabel = '',
    this.spacing = DesignTokens.s12,
    this.padding = const EdgeInsetsDirectional.fromSTEB(
      DesignTokens.s16,
      0,
      DesignTokens.s16,
      0,
    ),
  });

  final double itemWidth;
  final double height;
  final int count;

  /// Builds one placeholder; defaults to a full-size box.
  final IndexedWidgetBuilder? itemBuilder;
  final String semanticLabel;
  final double spacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return MallRail<Object>(
      items: const [],
      itemBuilder: (_, _, _) => const SizedBox.shrink(),
      itemWidth: itemWidth,
      height: height,
      semanticLabel: semanticLabel,
      isLoading: true,
      skeletonCount: count,
      skeletonBuilder: itemBuilder,
      spacing: spacing,
      padding: padding,
    );
  }
}
