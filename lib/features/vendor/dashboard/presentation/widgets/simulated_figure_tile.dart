import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/domain/entities/simulated_figure.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One figure from the simulation engine, drawn so it cannot be mistaken for
/// a measurement.
///
/// ## The marking, and why it is where it is
///
/// The word **Simulated** and a flask glyph sit in the *same line as the
/// number*, immediately before it, inside a [MallStatusPill]. Not a footnote,
/// not a heading over a group, not a tint:
///
///   * a footnote is read after the number, if at all, and this dialog opens
///     beside Store Pulse — the vendor's eye lands on the figure first;
///   * a group heading survives exactly until someone adds a fifth row under
///     it, or a screenshot crops it off;
///   * a tint vanishes in greyscale, under a colour-blind reading and on a
///     washed-out screen in a shop, and the kit's rule is state by glyph *and*
///     word, never colour alone.
///
/// Putting the word inside the value line means there is no way to read the
/// numeral without the word entering the same glance.
///
/// ## How it differs from a measured Store Pulse figure, in greyscale
///
/// Store Pulse draws a counted figure as a large white numeral centred over a
/// tiny caption, with no border and no pill. This tile is deliberately a
/// different object: left-aligned, inside a **dashed** border, the numeral a
/// step smaller and lighter, preceded by the pill, and followed by a plain
/// sentence naming the model, the unit and the measure key. The two do not
/// read as the same kind of thing with a colour swapped.
class SimulatedFigureTile extends StatelessWidget {
  const SimulatedFigureTile({
    required this.label,
    required this.figure,
    super.key,
  });

  /// What the figure is about, e.g. `Conversion`.
  final String label;

  final SimulatedFigure figure;

  /// The glyph carried beside the word. A flask, because the figure came out
  /// of a model rather than off a shelf.
  static const IconData simulatedGlyph = Icons.science_outlined;

  /// The glyph for the measured branch, which this endpoint never takes
  /// today. It exists so that `isSimulated == false` is a real, tested path
  /// rather than an assumption.
  static const IconData measuredGlyph = Icons.verified_outlined;

  /// The numeral itself, so a test can assert what a figure renders as — and,
  /// by its absence, that a missing figure renders nothing at all.
  static const Key valueKey = Key('simulated-figure-value');

  /// The simulated numeral's face. Deliberately smaller and lighter than the
  /// 21px, w600, white Store Pulse numeral it may end up beside: the
  /// difference is type, not tint, so it survives greyscale.
  static const TextStyle valueStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 15,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: DesignTokens.textLight,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    final simulated = figure.isSimulated;
    return Semantics(
      container: true,
      label: figure.semanticsSentence(label),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s6),
        child: CustomPaint(
          painter: _FigureBorderPainter(dashed: simulated),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: DesignTokens.s6),
                // The marker and the number share one line. A Wrap rather
                // than a Row so that at 320dp and 1.3x text the pill drops
                // above the numeral instead of overflowing — it never
                // detaches from it.
                Wrap(
                  spacing: DesignTokens.s8,
                  runSpacing: DesignTokens.s4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MallStatusPill(
                      label: figure.provenanceWord,
                      tone: simulated
                          ? MallStatusTone.caution
                          : MallStatusTone.success,
                      icon: simulated ? simulatedGlyph : measuredGlyph,
                      semanticLabel: figure.provenanceWord,
                      dense: true,
                    ),
                    Text(
                      figure.displayValue,
                      key: valueKey,
                      style: valueStyle,
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s6),
                Text(
                  _detail,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _detail => [
    figure.provenanceSentence,
    figure.unitSentence,
    if (figure.measureKey != null) 'Measure: ${figure.measureKey}.',
  ].join(' ');
}

/// The tile's frame. Dashed for a simulated figure, solid for a measured one.
///
/// The dash is the second non-colour carrier after the glyph and the word: it
/// survives a greyscale screenshot, and nothing else on the vendor dashboard
/// is drawn with a broken line.
class _FigureBorderPainter extends CustomPainter {
  const _FigureBorderPainter({required this.dashed});

  final bool dashed;

  static const double _radius = DesignTokens.radiusSmall;
  static const double _dashLength = 5;
  static const double _gapLength = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = dashed ? const Color(0x66FFFFFF) : const Color(0x33FFFFFF);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      const Radius.circular(_radius),
    );
    if (!dashed) {
      canvas.drawRRect(rect, stroke);
      return;
    }
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), stroke);
        distance = end + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_FigureBorderPainter oldDelegate) =>
      oldDelegate.dashed != dashed;
}
