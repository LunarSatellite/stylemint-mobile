import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stylemint_mobile_frontend/theme/colors.dart';

/// Style Mint shimmer helpers — adapted from vpt-mydawa ShimmerWidget.
///
/// Colours are tuned for the dark foundation. Pass `enabled: false` (for
/// example when `MediaQuery.disableAnimationsOf(context)` is true) to render
/// the static base tone without the sweep. The sweep follows the ambient text
/// direction.
abstract class SmShimmer {
  static Widget rectangle({
    double? width,
    double? height,
    double radius = 8,
    bool enabled = true,
  }) => _ShimmerBox(
    width: width,
    height: height,
    radius: radius,
    enabled: enabled,
  );

  static Widget circle({double radius = 24, bool enabled = true}) =>
      _ShimmerCircle(radius: radius, enabled: enabled);

  static Widget text({
    double width = 120,
    double height = 14,
    bool enabled = true,
  }) => _ShimmerBox(width: width, height: height, radius: 4, enabled: enabled);
}

ShimmerDirection _directionOf(BuildContext context) =>
    Directionality.maybeOf(context) == TextDirection.rtl
    ? ShimmerDirection.rtl
    : ShimmerDirection.ltr;

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.enabled,
    this.width,
    this.height,
    this.radius = 8,
  });

  final double? width;
  final double? height;
  final double radius;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kShimmerBase,
      highlightColor: kShimmerHighlight,
      direction: _directionOf(context),
      enabled: enabled,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 16,
        decoration: BoxDecoration(
          color: kShimmerBase,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _ShimmerCircle extends StatelessWidget {
  const _ShimmerCircle({required this.radius, required this.enabled});

  final double radius;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kShimmerBase,
      highlightColor: kShimmerHighlight,
      direction: _directionOf(context),
      enabled: enabled,
      child: CircleAvatar(radius: radius, backgroundColor: kShimmerBase),
    );
  }
}
