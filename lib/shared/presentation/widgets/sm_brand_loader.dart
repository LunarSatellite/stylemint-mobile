import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_mark_outline.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The StyleMint mark. Its silhouette is traced in [smBrandMarkOutline].
const smBrandMarkAsset = 'assets/branding/stylemint-mark.png';

/// The StyleMint mark with light travelling along its edge.
///
/// [lap] is where the light is around the outline, from 0 to 1. [brightness],
/// when given, takes the mark from dimmed (0) to fully lit (1), and the light
/// and [halo] fade in with it.
class SmLuminousMark extends StatefulWidget {
  const SmLuminousMark({
    required this.lap,
    this.brightness,
    this.halo = false,
    super.key,
  });

  final Animation<double> lap;
  final Animation<double>? brightness;

  /// A soft green bloom behind the mark.
  final bool halo;

  @override
  State<SmLuminousMark> createState() => _SmLuminousMarkState();
}

class _SmLuminousMarkState extends State<SmLuminousMark> {
  Size? _outlineSize;
  late Path _outline;
  late ui.PathMetric _metric;

  void _traceFor(Size size) {
    if (_outlineSize == size) return;
    _outlineSize = size;
    _outline = smBrandMarkOutlinePath(size);
    _metric = _outline.computeMetrics().first;
  }

  @override
  Widget build(BuildContext context) {
    final dimmable = widget.brightness;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.isFinite
            ? constraints.biggest
            : const Size.square(64);
        _traceFor(size);
        final mark = Image.asset(
          smBrandMarkAsset,
          width: size.width,
          height: size.height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
        );
        return AnimatedBuilder(
          animation: Listenable.merge([widget.lap, ?dimmable]),
          builder: (context, child) {
            final lit = (dimmable?.value ?? 1).clamp(0.0, 1.0);
            return CustomPaint(
              painter: widget.halo ? _HaloPainter(lit) : null,
              foregroundPainter: _EdgeLightPainter(
                outline: _outline,
                metric: _metric,
                lap: widget.lap.value,
                intensity: lit,
              ),
              child: dimmable == null
                  ? child
                  : ColorFiltered(colorFilter: _dimmed(lit), child: child),
            );
          },
          child: mark,
        );
      },
    );
  }

  static ColorFilter _dimmed(double lit) {
    final gain = 0.16 + 0.84 * lit;
    return ColorFilter.matrix(<double>[
      gain, 0, 0, 0, 0, //
      0, gain, 0, 0, 0, //
      0, 0, gain, 0, 0, //
      0, 0, 0, 0.5 + 0.5 * lit, 0, //
    ]);
  }
}

class _HaloPainter extends CustomPainter {
  const _HaloPainter(this.lit);

  final double lit;

  @override
  void paint(Canvas canvas, Size size) {
    if (lit <= 0) return;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.66;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            DesignTokens.primaryGreen.withValues(alpha: 0.28 * lit),
            DesignTokens.primaryGreen.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_HaloPainter oldDelegate) => oldDelegate.lit != lit;
}

class _EdgeLightPainter extends CustomPainter {
  _EdgeLightPainter({
    required this.outline,
    required this.metric,
    required this.lap,
    required this.intensity,
  });

  final Path outline;
  final ui.PathMetric metric;
  final double lap;
  final double intensity;

  static const _spark = Color(0xFFB9F7D3);

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.01) return;
    final width = size.shortestSide;
    final length = metric.length;

    // A faint glow along the whole edge, so the light reads as running on it.
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.012
        ..color = DesignTokens.primaryGreen.withValues(alpha: 0.18 * intensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.012),
    );

    _comet(
      canvas,
      width,
      head: lap * length,
      tail: length * 0.3,
      strength: intensity,
      slices: 7,
    );
    _comet(
      canvas,
      width,
      head: (lap + 0.5) * length,
      tail: length * 0.14,
      strength: 0.4 * intensity,
      slices: 4,
    );
  }

  /// A streak of light whose head is at [head] along the outline and whose
  /// tail fades out over [tail].
  void _comet(
    Canvas canvas,
    double width, {
    required double head,
    required double tail,
    required double strength,
    required int slices,
  }) {
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.022);
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < slices; i++) {
      final nearHead = (i + 1) / slices;
      final segment = _extract(
        head - tail * (1 - i / slices),
        head - tail * (1 - nearHead),
      );
      final fade = nearHead * nearHead * strength;
      glow
        ..strokeWidth = width * (0.02 + 0.035 * nearHead)
        ..color = DesignTokens.primaryGreen.withValues(alpha: 0.75 * fade);
      canvas.drawPath(segment, glow);
      core
        ..strokeWidth = width * (0.004 + 0.012 * nearHead)
        ..color = Color.lerp(
          DesignTokens.primaryGreen,
          _spark,
          nearHead,
        )!.withValues(alpha: fade);
      canvas.drawPath(segment, core);
    }

    final tip = metric.getTangentForOffset(_wrap(head));
    if (tip != null) {
      canvas.drawCircle(
        tip.position,
        width * 0.016,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85 * strength)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.014),
      );
    }
  }

  double _wrap(double offset) {
    final length = metric.length;
    final value = offset % length;
    return value < 0 ? value + length : value;
  }

  Path _extract(double from, double to) {
    final length = metric.length;
    final start = _wrap(from);
    final end = start + (to - from);
    if (end <= length) return metric.extractPath(start, end);
    return Path()
      ..addPath(metric.extractPath(start, length), Offset.zero)
      ..addPath(metric.extractPath(0, end - length), Offset.zero);
  }

  @override
  bool shouldRepaint(_EdgeLightPainter oldDelegate) =>
      oldDelegate.lap != lap ||
      oldDelegate.intensity != intensity ||
      !identical(oldDelegate.outline, outline);
}

/// The StyleMint loader: the mark with light running around its edge.
class SmBrandLoader extends StatefulWidget {
  const SmBrandLoader({
    this.size = 64,
    this.semanticLabel = 'Loading',
    super.key,
  });

  final double size;
  final String semanticLabel;

  @override
  State<SmBrandLoader> createState() => _SmBrandLoaderState();
}

class _SmBrandLoaderState extends State<SmBrandLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool? _still;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still == _still) return;
    _still = still;
    if (still) {
      _lap
        ..stop()
        ..value = 0.12;
    } else {
      unawaited(_lap.repeat());
    }
  }

  @override
  void dispose() {
    _lap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: widget.size,
            child: SmLuminousMark(lap: _lap),
          ),
        ),
      ),
    );
  }
}

/// A centred [SmBrandLoader] for a page or section that is loading.
class SmPageLoader extends StatelessWidget {
  const SmPageLoader({this.size = 64, super.key});

  final double size;

  @override
  Widget build(BuildContext context) =>
      Center(child: SmBrandLoader(size: size));
}
