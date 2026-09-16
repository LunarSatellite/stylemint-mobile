import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// The Mall's motion language. Three rules hold everywhere:
//
//  * depth comes from differential speed, never from blur;
//  * a block introduces itself once, then stops costing anything;
//  * `MediaQuery.disableAnimations` removes motion, never information.
//
// Every animated piece sits inside its own `RepaintBoundary` and listens to a
// notifier rather than rebuilding its parent, so scrolling the page never
// repaints the page.

/// Publishes the Mall page's vertical scroll offset to the blocks that use it
/// for depth.
///
/// Consumers listen to [offset] themselves (see [MallParallax]); depending on
/// this widget only rebuilds them when the notifier *instance* changes, so a
/// scroll tick never rebuilds the tree.
class MallScrollLink extends InheritedWidget {
  const MallScrollLink({
    required this.offset,
    required super.child,
    super.key,
  });

  /// Pixels scrolled from the top of the page, never negative.
  final ValueListenable<double> offset;

  /// The nearest link, or null when the block is drawn outside a Mall page
  /// (a test harness, a storefront). Blocks degrade to no parallax.
  static ValueListenable<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MallScrollLink>()?.offset;

  @override
  bool updateShouldNotify(MallScrollLink oldWidget) =>
      oldWidget.offset != offset;
}

/// Moves [child] with the page at a fraction of its speed, so it reads as
/// sitting behind the copy in front of it.
///
/// The child is scaled by [overscan] first so the slower layer never exposes
/// an edge. Without a [MallScrollLink] ancestor, or under reduced motion, the
/// child is returned untouched.
class MallParallax extends StatelessWidget {
  const MallParallax({
    required this.child,
    super.key,
    this.factor = 0.32,
    this.maxShift = 160,
    this.overscan = 1.16,
  });

  final Widget child;

  /// Share of the page's scroll this layer keeps. 0.32 reads as roughly a
  /// 3:1 depth ratio against copy that scrolls at full speed.
  final double factor;

  /// Ceiling on the lag, so a long page never drags the layer off its box.
  final double maxShift;

  /// Scale applied before the shift, covering [maxShift] of travel.
  final double overscan;

  @override
  Widget build(BuildContext context) {
    final link = MallScrollLink.maybeOf(context);
    if (link == null || MallMetrics.reduceMotion(context)) return child;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: link,
        builder: (_, inner) {
          final shift = math.min<double>(
            maxShift,
            math.max<double>(0, link.value * factor),
          );
          return Transform.translate(
            offset: Offset(0, shift),
            child: inner,
          );
        },
        child: Transform.scale(scale: overscan, child: child),
      ),
    );
  }
}

/// Fades [child] out as the page scrolls past it, so hero copy hands over to
/// the content below instead of sliding away under it.
class MallScrollFade extends StatelessWidget {
  const MallScrollFade({
    required this.child,
    required this.distance,
    super.key,
  });

  final Widget child;

  /// Pixels of scrolling over which the child reaches fully transparent.
  final double distance;

  @override
  Widget build(BuildContext context) {
    final link = MallScrollLink.maybeOf(context);
    if (link == null || distance <= 0 || MallMetrics.reduceMotion(context)) {
      return child;
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: link,
        builder: (_, inner) {
          final progress = math.min<double>(
            1,
            math.max<double>(0, link.value / distance),
          );
          return Opacity(opacity: 1 - progress, child: inner);
        },
        child: child,
      ),
    );
  }
}

/// A very slow scale drift over imagery — the "living photograph" of the
/// cinematic zone.
///
/// The drift is one composited transform on an already-rasterised layer, so
/// it costs no repaint. It stops with `TickerMode` (the Mall is muted while
/// Reels is showing) and never runs under reduced motion.
class MallKenBurns extends StatefulWidget {
  const MallKenBurns({
    required this.child,
    super.key,
    this.enabled = true,
    this.amplitude = 1.05,
    this.period = const Duration(seconds: 16),
  });

  final Widget child;

  /// Off for layers that are not the active slide.
  final bool enabled;

  /// Scale reached at the far end of the drift.
  final double amplitude;
  final Duration period;

  @override
  State<MallKenBurns> createState() => _MallKenBurnsState();
}

class _MallKenBurnsState extends State<MallKenBurns>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(vsync: this, duration: widget.period);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MallMetrics.reduceMotion(context);
    _sync();
  }

  @override
  void didUpdateWidget(MallKenBurns oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) _drift.duration = widget.period;
    _sync();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  void _sync() {
    if (widget.enabled && !_reduceMotion) {
      if (!_drift.isAnimating) unawaited(_drift.repeat(reverse: true));
    } else if (_drift.isAnimating) {
      _drift.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _reduceMotion) return widget.child;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _drift,
        builder: (_, inner) => Transform.scale(
          scale: 1 + (widget.amplitude - 1) * _drift.value,
          child: inner,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Introduces a block once, as it is first built — which, inside a lazily
/// built sliver list, means as it first comes into view.
///
/// Once the entrance finishes the wrapper drops out of the way entirely, so a
/// long page never accumulates opacity layers.
class MallEnter extends StatefulWidget {
  const MallEnter({required this.child, super.key, this.rise = 18});

  final Widget child;

  /// Distance the block travels up into place.
  final double rise;

  @override
  State<MallEnter> createState() => _MallEnterState();
}

class _MallEnterState extends State<MallEnter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: DesignTokens.motionMedium,
    )..addStatusListener(_onStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MallMetrics.reduceMotion(context)) {
      _enter.value = 1;
    } else {
      unawaited(_enter.forward());
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    // Swap back to the bare child so the finished block costs nothing.
    if (status == AnimationStatus.completed && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_enter.isCompleted) return widget.child;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _enter,
        builder: (_, inner) {
          final progress = DesignTokens.motionCurve.transform(_enter.value);
          return Opacity(
            opacity: progress,
            child: Transform.translate(
              offset: Offset(0, (1 - progress) * widget.rise),
              child: inner,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
