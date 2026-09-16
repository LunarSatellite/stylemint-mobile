import 'package:flutter/widgets.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/sm_skeleton.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Horizontal, lazily built rail of fixed-width items that snaps item by
/// item.
///
/// Size [height] with the item card's `heightFor` so the rail accounts for
/// the ambient text scale. While [isLoading] it shows [skeletonCount]
/// skeletons; when loaded and empty it shows [emptyState].
class MallRail<T> extends StatelessWidget {
  const MallRail({
    required this.items,
    required this.itemBuilder,
    required this.itemWidth,
    required this.height,
    required this.semanticLabel,
    super.key,
    this.isLoading = false,
    this.skeletonBuilder,
    this.skeletonCount = 4,
    this.emptyState,
    this.spacing = DesignTokens.s12,
    this.padding = const EdgeInsetsDirectional.fromSTEB(
      DesignTokens.s16,
      0,
      DesignTokens.s16,
      0,
    ),
    this.snap = true,
    this.controller,
    this.stagger = 0,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double itemWidth;
  final double height;

  /// Names the rail for assistive technology, e.g. "Trending products".
  final String semanticLabel;
  final bool isLoading;

  /// Builds one loading placeholder. Defaults to a full-size skeleton box.
  final IndexedWidgetBuilder? skeletonBuilder;
  final int skeletonCount;

  /// Shown instead of the rail when loaded with no items.
  final Widget? emptyState;
  final double spacing;
  final EdgeInsetsGeometry padding;
  final bool snap;
  final ScrollController? controller;

  /// Drops every second item by this many pixels, so the rail reads as a
  /// composed row rather than a filmstrip of identical boxes.
  ///
  /// Purely typographic rhythm: nothing is hidden, the items keep their
  /// order and their size, and the rail simply grows by [stagger] to hold
  /// the offset — pass the same value to [heightForStaggered] when sizing.
  /// Zero, the default, leaves the row flush.
  final double stagger;

  /// The offset the Mall's shopping rails use. Enough to break the line,
  /// small enough that the row still scans left to right.
  static const double defaultStagger = 18;

  /// The height a rail needs to carry [itemHeight] items with [stagger].
  static double heightForStaggered(
    double itemHeight, [
    double stagger = defaultStagger,
  ]) => itemHeight + stagger;

  @override
  Widget build(BuildContext context) {
    if (!isLoading && items.isEmpty) {
      final empty = emptyState;
      if (empty == null) return const SizedBox.shrink();
      return Semantics(container: true, label: semanticLabel, child: empty);
    }
    final label = [
      semanticLabel,
      if (isLoading) MallStrings.of(context).loading,
    ].where((part) => part.isNotEmpty).join(', ');
    final physics = isLoading
        ? const NeverScrollableScrollPhysics()
        : (snap
              ? MallSnapScrollPhysics(itemExtent: itemWidth + spacing)
              : null);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: SizedBox(
        height: height,
        child: ListView.separated(
          controller: controller,
          scrollDirection: Axis.horizontal,
          padding: padding,
          physics: physics,
          itemCount: isLoading ? skeletonCount : items.length,
          separatorBuilder: (_, _) => SizedBox(width: spacing),
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsetsDirectional.only(
              top: stagger > 0 && index.isOdd ? stagger : 0,
            ),
            child: SizedBox(
              width: itemWidth,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: isLoading
                    ? _skeleton(context, index)
                    : itemBuilder(context, items[index], index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _skeleton(BuildContext context, int index) =>
      skeletonBuilder?.call(context, index) ??
      SmSkeleton.box(width: itemWidth, height: height);
}

/// Snaps a horizontal list so an item's leading edge rests at the list's
/// leading padding after a fling. [itemExtent] is item width plus spacing.
class MallSnapScrollPhysics extends ScrollPhysics {
  const MallSnapScrollPhysics({required this.itemExtent, super.parent});

  final double itemExtent;

  @override
  MallSnapScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      MallSnapScrollPhysics(
        itemExtent: itemExtent,
        parent: buildParent(ancestor),
      );

  double _targetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    var item = position.pixels / itemExtent;
    if (velocity < -tolerance.velocity) {
      item -= 0.5;
    } else if (velocity > tolerance.velocity) {
      item += 0.5;
    }
    return (item.roundToDouble() * itemExtent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final atStart = position.pixels <= position.minScrollExtent;
    final atEnd = position.pixels >= position.maxScrollExtent;
    if (itemExtent <= 0 ||
        (velocity <= 0 && atStart) ||
        (velocity >= 0 && atEnd)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final target = _targetPixels(position, tolerance, velocity);
    if ((target - position.pixels).abs() < tolerance.distance &&
        velocity.abs() < tolerance.velocity) {
      return null;
    }
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
