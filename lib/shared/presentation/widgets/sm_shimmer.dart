import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../theme/colors.dart';

/// Style Mint shimmer helpers — adapted from vpt-mydawa ShimmerWidget.
abstract class SmShimmer {
  static Widget rectangle({
    double? width,
    double? height,
    double radius = 8,
  }) =>
      _ShimmerBox(width: width, height: height, radius: radius);

  static Widget circle({double radius = 24}) =>
      _ShimmerCircle(radius: radius);

  static Widget text({double width = 120, double height = 14}) =>
      _ShimmerBox(width: width, height: height, radius: 4);
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({this.width, this.height, this.radius = 8});

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kShimmerBase,
      highlightColor: kShimmerHighlight,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 16,
        decoration: BoxDecoration(
          color: kGrey100,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _ShimmerCircle extends StatelessWidget {
  const _ShimmerCircle({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kShimmerBase,
      highlightColor: kShimmerHighlight,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: kGrey100,
      ),
    );
  }
}
