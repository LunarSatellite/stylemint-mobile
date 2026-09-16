import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The Mall's signage band: a slow, continuous line of what the page is
/// actually holding — brands, edits, categories, counts — running edge to
/// edge between two zones.
///
/// Every word comes from the response the page was built from, so the band
/// says more the fuller the catalogue gets and stays truthful while it is
/// small. It is the one piece of the page that moves on its own without being
/// scrolled, which is what stops a long column of blocks reading as a
/// document.
///
/// Cheap by construction: the line is built once and then only translated, so
/// the marquee is a composited transform on a rasterised layer inside its own
/// [RepaintBoundary] — no text is re-laid-out per frame. It holds still under
/// `MediaQuery.disableAnimations` and stops entirely whenever `TickerMode`
/// mutes the subtree (the Mall is muted while Reels is showing).
class MallTicker extends StatefulWidget {
  const MallTicker({
    required this.words,
    required this.semanticLabel,
    super.key,
    this.pixelsPerSecond = 26,
  });

  /// Real strings from the page's own data, in reading order.
  final List<String> words;

  /// What the band is, spoken before the words.
  final String semanticLabel;

  /// Travel speed. Slow enough to read, fast enough to be alive.
  final double pixelsPerSecond;

  static const double _fontSize = 26;
  static const double _lineHeight = 1.15;
  static const double _verticalPadding = DesignTokens.s16;
  static const double _gap = DesignTokens.s16;
  static const double _dot = 5;

  /// Exact rendered height at [context]'s text scale.
  static double heightFor(BuildContext context) =>
      MallMetrics.textHeight(
        MallMetrics.scalerOf(context),
        fontSize: _fontSize,
        lineHeight: _lineHeight,
      ) +
      _verticalPadding * 2 +
      2;

  @override
  State<MallTicker> createState() => _MallTickerState();
}

class _MallTickerState extends State<MallTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    // Built here rather than lazily: a band that never animates (reduced
    // motion) would otherwise create its controller for the first time
    // inside dispose, which is too late to reach the ticker mode above it.
    _drift = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  /// Width of one pass of the line, measured rather than guessed: the band
  /// draws the line twice and hands back exactly one pass of travel, so the
  /// loop has no seam.
  double _runWidth(
    List<String> words,
    TextStyle style,
    TextScaler scaler,
    TextDirection direction,
  ) {
    var total = 0.0;
    for (final word in words) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      total += painter.width;
      painter.dispose();
      total += MallTicker._gap * 2 + MallTicker._dot;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.words;
    if (words.isEmpty) return const SizedBox.shrink();

    final scaler = MallMetrics.scalerOf(context);
    final direction = Directionality.of(context);
    const style = TextStyle(
      fontFamily: DesignTokens.displayFontFamily,
      fontSize: MallTicker._fontSize,
      fontWeight: FontWeight.w400,
      height: MallTicker._lineHeight,
      letterSpacing: 0.6,
      color: DesignTokens.textLight,
    );
    // Set as signage is: capitals, tracked, one long line. It also keeps the
    // band from reading as a second copy of the headings under it.
    final display = [for (final word in words) word.toUpperCase()];
    final run = _TickerRun(words: display, style: style);
    final height = MallTicker.heightFor(context);
    final reduceMotion = MallMetrics.reduceMotion(context);

    Widget line;
    if (reduceMotion) {
      line = run;
    } else {
      final width = _runWidth(display, style, scaler, direction);
      final seconds = (width / widget.pixelsPerSecond).clamp(8.0, 240.0);
      final period = Duration(milliseconds: (seconds * 1000).round());
      if (_drift.duration != period) _drift.duration = period;
      if (!_drift.isAnimating) unawaited(_drift.repeat());
      final sign = direction == TextDirection.rtl ? 1.0 : -1.0;
      line = AnimatedBuilder(
        animation: _drift,
        builder: (_, inner) => Transform.translate(
          offset: Offset(sign * width * _drift.value, 0),
          child: inner,
        ),
        // Two passes side by side: as the first leaves, the second is
        // already in place, so the loop never shows a gap. Its own boundary,
        // so the line rasterises once and every frame after that is a
        // composited transform rather than a re-layout of 30-odd words.
        child: RepaintBoundary(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [run, run],
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: '${widget.semanticLabel}: ${words.join(', ')}',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: DesignTokens.bgAppBody,
              border: Border.symmetric(
                horizontal: BorderSide(color: DesignTokens.borderDefault),
              ),
            ),
            child: SizedBox(
              height: height,
              child: ClipRect(
                child: OverflowBox(
                  maxWidth: double.infinity,
                  alignment: AlignmentDirectional.centerStart,
                  child: line,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One pass of the line: each word, and a brand-green dot between them.
class _TickerRun extends StatelessWidget {
  const _TickerRun({required this.words, required this.style});

  final List<String> words;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final word in words) ...[
        Text(word, maxLines: 1, style: style),
        const SizedBox(width: MallTicker._gap),
        const DecoratedBox(
          decoration: BoxDecoration(
            color: DesignTokens.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(dimension: MallTicker._dot),
        ),
        const SizedBox(width: MallTicker._gap),
      ],
    ],
  );
}
