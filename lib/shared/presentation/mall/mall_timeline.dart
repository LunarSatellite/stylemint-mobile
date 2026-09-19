import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_signal.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// The order timeline and the compact stepper. The Mall kit had no way to draw
// "this happened, this is happening, this has not happened yet" because the
// browsing surfaces have no such thing. Every post-purchase surface does, and
// so does every vendor fulfilment surface, which is why this belongs here and
// not inside one screen.
//
// Same rule as `MallStatusPill`: state is carried by the **mark**, not the
// colour. Done is a filled tick, current is a ring with a dot, upcoming is a
// hollow outline, failed is a cross. Turn the screen greyscale and the
// timeline still reads.

/// Where a step sits relative to now.
enum MallStepState {
  /// Happened. Filled disc, tick.
  done,

  /// Happening. Ringed disc, solid centre; the rail below it is dashed.
  current,

  /// Not yet. Hollow disc, dashed rail.
  upcoming,

  /// Stopped or failed here. Cross.
  failed,

  /// Skipped — it will not happen, and that is fine (e.g. a cancelled order's
  /// remaining stages).
  skipped,
}

/// One row of a [MallTimeline].
@immutable
class MallTimelineStep {
  const MallTimelineStep({
    required this.title,
    required this.state,
    this.detail,
    this.timestamp,
    this.icon,
    this.markKey,
    this.trailing,
  });

  final String title;
  final MallStepState state;

  /// One supporting line — a place, a courier, a reason.
  final String? detail;

  /// Already-formatted date/time. Rendered with tabular figures so a column
  /// of stamps lines up.
  final String? timestamp;

  /// Overrides the state mark's glyph for a done step only; current, upcoming
  /// and failed keep their marks so the state stays unambiguous.
  final IconData? icon;

  /// Key placed on the step's mark, so a screen (or a test) can address one
  /// stage of a timeline directly — scrolling to it, for instance.
  final Key? markKey;

  /// Evidence hanging off the step: a seal photo, a proof-of-delivery thumb.
  /// Rendered under the copy, inside the step's own semantics container.
  final Widget? trailing;

  /// Plain-language state word, spoken to screen readers and appended to the
  /// visible title's semantics. Never relies on the mark being seen.
  String get stateWord => switch (state) {
    MallStepState.done => 'completed',
    MallStepState.current => 'in progress',
    MallStepState.upcoming => 'not started',
    MallStepState.failed => 'failed',
    MallStepState.skipped => 'skipped',
  };
}

/// Vertical order timeline: a rail of marks with copy beside it.
///
/// Draws only what it is given — no invented stages, no estimated stamps.
class MallTimeline extends StatelessWidget {
  const MallTimeline({
    required this.steps,
    super.key,
    this.semanticLabel,
    this.compact = false,
  });

  final List<MallTimelineStep> steps;
  final String? semanticLabel;

  /// Tighter vertical rhythm, for a card rather than a page section.
  final bool compact;

  static const double _railWidth = 28;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            _TimelineRow(
              step: steps[i],
              isLast: i == steps.length - 1,
              compact: compact,
              railWidth: _railWidth,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.isLast,
    required this.compact,
    required this.railWidth,
  });

  final MallTimelineStep step;
  final bool isLast;
  final bool compact;
  final double railWidth;

  @override
  Widget build(BuildContext context) {
    final scaler = MallMetrics.scalerOf(context);
    final detail = step.detail;
    final timestamp = step.timestamp;
    final trailing = step.trailing;
    final isMuted =
        step.state == MallStepState.upcoming ||
        step.state == MallStepState.skipped;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: railWidth,
            child: Column(
              children: [
                _StepMark(
                  key: step.markKey,
                  state: step.state,
                  icon: step.icon,
                  scaler: scaler,
                ),
                if (!isLast)
                  Expanded(
                    child: _Connector(
                      // The rail below a step is solid only once that step has
                      // actually happened.
                      solid: step.state == MallStepState.done,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast
                    ? 0
                    : (compact ? DesignTokens.s16 : DesignTokens.s20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The copy is one spoken node that names the state in
                  // words; `trailing` stays outside it, because a step's
                  // evidence can be a control of its own.
                  Semantics(
                    container: true,
                    label: [
                      step.title,
                      step.stateWord,
                      ?timestamp,
                      ?detail,
                    ].join('. '),
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: compact ? 13 : 14,
                            fontWeight: step.state == MallStepState.current
                                ? FontWeight.w600
                                : FontWeight.w500,
                            height: 1.35,
                            color: isMuted
                                ? DesignTokens.textMuted
                                : DesignTokens.textWhite,
                            decoration: step.state == MallStepState.skipped
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: DesignTokens.textMuted,
                          ),
                        ),
                        if (timestamp != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            timestamp,
                            style: const TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 12,
                              height: 1.35,
                              color: DesignTokens.textMuted,
                              fontFeatures: mallTabularFigures,
                            ),
                          ),
                        ],
                        if (detail != null) ...[
                          const SizedBox(height: DesignTokens.s4),
                          Text(
                            detail,
                            style: const TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 12.5,
                              height: 1.45,
                              color: DesignTokens.textLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepMark extends StatelessWidget {
  const _StepMark({
    required this.state,
    required this.icon,
    required this.scaler,
    super.key,
  });

  final MallStepState state;
  final IconData? icon;
  final TextScaler scaler;

  @override
  Widget build(BuildContext context) {
    final size = scaler.scale(22).clamp(22.0, 30.0);
    switch (state) {
      case MallStepState.done:
        return _Disc(
          size: size,
          fill: DesignTokens.primaryGreen,
          glyph: icon ?? Icons.check_rounded,
          glyphColor: DesignTokens.buttonPrimaryText,
        );
      case MallStepState.current:
        return SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: DesignTokens.primaryGreenDark,
              shape: BoxShape.circle,
              border: Border.all(color: DesignTokens.primaryGreen, width: 2),
            ),
            child: Center(
              child: SizedBox.square(
                dimension: size * 0.34,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        );
      case MallStepState.failed:
        return _Disc(
          size: size,
          fill: DesignTokens.colorError.withValues(alpha: 0.18),
          glyph: Icons.close_rounded,
          glyphColor: DesignTokens.colorError,
        );
      case MallStepState.skipped:
        return _Disc(
          size: size,
          fill: DesignTokens.bgAppBodyLight,
          glyph: Icons.remove_rounded,
          glyphColor: DesignTokens.textMuted,
        );
      case MallStepState.upcoming:
        return SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: DesignTokens.borderDefault, width: 1.5),
            ),
          ),
        );
    }
  }
}

class _Disc extends StatelessWidget {
  const _Disc({
    required this.size,
    required this.fill,
    required this.glyph,
    required this.glyphColor,
  });

  final double size;
  final Color fill;
  final IconData glyph;
  final Color glyphColor;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: Icon(glyph, size: size * 0.62, color: glyphColor),
    ),
  );
}

/// The rail between two marks. Solid behind history, dashed ahead of it — the
/// second non-colour cue that a step has not happened yet.
class _Connector extends StatelessWidget {
  const _Connector({required this.solid});

  final bool solid;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Center(
      child: SizedBox(
        width: 2,
        child: CustomPaint(
          painter: _RailPainter(solid: solid),
          size: Size.infinite,
        ),
      ),
    ),
  );
}

/// The rail, painted rather than built from widgets: it lives inside an
/// `IntrinsicHeight`, and a `LayoutBuilder` cannot run under intrinsics.
/// Solid behind history, dashed ahead of it.
class _RailPainter extends CustomPainter {
  const _RailPainter({required this.solid});

  final bool solid;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0) return;
    final x = size.width / 2;
    final paint = Paint()
      ..color = solid ? DesignTokens.primaryGreen : DesignTokens.borderDefault
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    if (solid) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      return;
    }
    const dash = 4.0;
    const gap = 4.0;
    var y = 0.0;
    while (y < size.height) {
      final end = (y + dash).clamp(0.0, size.height);
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RailPainter oldDelegate) =>
      oldDelegate.solid != solid;
}

/// Horizontal stepper: the same stages as [MallTimeline] compressed to a
/// single band, for a card or an app-bar-adjacent summary. Labels sit under
/// the marks and wrap to two lines rather than truncating.
class MallStatusStepper extends StatelessWidget {
  const MallStatusStepper({
    required this.steps,
    super.key,
    this.semanticLabel,
  });

  final List<MallTimelineStep> steps;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    final scaler = MallMetrics.scalerOf(context);
    final markSize = scaler.scale(22).clamp(22.0, 30.0);
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            Expanded(
              child: Semantics(
                label: '${steps[i].title}. ${steps[i].stateWord}',
                excludeSemantics: true,
                child: Column(
                  children: [
                    SizedBox(
                      height: markSize,
                      child: Row(
                        children: [
                          Expanded(
                            child: i == 0
                                ? const SizedBox.shrink()
                                : _HorizontalRail(
                                    solid:
                                        steps[i - 1].state ==
                                        MallStepState.done,
                                  ),
                          ),
                          _StepMark(
                            key: steps[i].markKey,
                            state: steps[i].state,
                            icon: steps[i].icon,
                            scaler: scaler,
                          ),
                          Expanded(
                            child: i == steps.length - 1
                                ? const SizedBox.shrink()
                                : _HorizontalRail(
                                    solid: steps[i].state == MallStepState.done,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        steps[i].title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 10.5,
                          height: 1.25,
                          fontWeight: steps[i].state == MallStepState.current
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: steps[i].state == MallStepState.upcoming
                              ? DesignTokens.textMuted
                              : DesignTokens.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HorizontalRail extends StatelessWidget {
  const _HorizontalRail({required this.solid});

  final bool solid;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      height: 2,
      child: ColoredBox(
        color: solid ? DesignTokens.primaryGreen : DesignTokens.borderDefault,
      ),
    ),
  );
}
