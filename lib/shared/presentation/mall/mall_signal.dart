import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// Live signals for the dense-discovery zone.
//
// A signal is only ever built from a value the API actually sent. There is no
// client-side guessing here: if the data does not carry a number, no number is
// drawn. See `mall_zones.dart` for the derivations.

/// How loud a signal reads. Tone is meaning, not decoration: [urgent] is
/// reserved for a real deadline or genuinely low stock.
enum MallSignalTone { neutral, accent, urgent }

/// One scannable fact about a card or a section.
@immutable
class MallSignal {
  const MallSignal({
    required this.label,
    this.tone = MallSignalTone.neutral,
    this.icon,
    this.semanticLabel,
  });

  /// Short display text, e.g. "12 reviews" or "Ends in 4h 12m".
  final String label;
  final MallSignalTone tone;
  final IconData? icon;

  /// Spoken form when [label] is abbreviated. Defaults to [label].
  final String? semanticLabel;

  String get spoken => semanticLabel ?? label;

  @override
  bool operator ==(Object other) =>
      other is MallSignal &&
      other.label == label &&
      other.tone == tone &&
      other.icon == icon &&
      other.semanticLabel == semanticLabel;

  @override
  int get hashCode => Object.hash(label, tone, icon, semanticLabel);

  @override
  String toString() => 'MallSignal($label, $tone)';
}

/// Fill and ink for [tone], drawn from the one Mall palette.
({Color background, Color foreground}) mallSignalColors(MallSignalTone tone) =>
    switch (tone) {
      MallSignalTone.neutral => (
        background: DesignTokens.bgAppBody,
        foreground: DesignTokens.textLight,
      ),
      MallSignalTone.accent => (
        background: DesignTokens.primaryGreenDark,
        foreground: DesignTokens.primaryGreen,
      ),
      MallSignalTone.urgent => (
        background: DesignTokens.warningFillDark,
        foreground: DesignTokens.warning300,
      ),
    };

/// Numerals line up column to column, which is what makes a dense rail
/// scannable rather than noisy.
const List<FontFeature> mallTabularFigures = [FontFeature.tabularFigures()];

/// A signal as a small pill — for section headers, where signals sit in a row
/// of their own.
class MallSignalChip extends StatelessWidget {
  const MallSignalChip({required this.signal, super.key});

  final MallSignal signal;

  static const TextStyle _style = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.1,
    fontFeatures: mallTabularFigures,
  );

  @override
  Widget build(BuildContext context) {
    final colors = mallSignalColors(signal.tone);
    final icon = signal.icon;
    return Semantics(
      label: signal.spoken,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: MallMetrics.scalerOf(context).scale(11),
                  color: colors.foreground,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  signal.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _style.copyWith(color: colors.foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A signal as one bare line — for product cards, where a pill per card would
/// read as clutter and cost a decoration per tile.
class MallSignalLine extends StatelessWidget {
  const MallSignalLine({required this.signal, super.key});

  final MallSignal signal;

  /// Type the line is set in; [heightFor] measures exactly this.
  static const TextStyle style = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    height: 1.3,
    fontFeatures: mallTabularFigures,
  );

  /// Exact rendered height at the ambient text scale, for card metrics.
  static double heightFor(BuildContext context) => MallMetrics.textHeight(
    MallMetrics.scalerOf(context),
    fontSize: style.fontSize!,
    lineHeight: style.height!,
  );

  @override
  Widget build(BuildContext context) {
    final colors = mallSignalColors(signal.tone);
    final icon = signal.icon;
    final ink = signal.tone == MallSignalTone.neutral
        ? DesignTokens.textMuted
        : colors.foreground;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: MallMetrics.scalerOf(context).scale(11),
            color: ink,
          ),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            signal.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style.copyWith(color: ink),
          ),
        ),
      ],
    );
  }
}

/// Time left until [left] runs out, e.g. "3d 4h", "4h 12m", "12m 30s".
///
/// Null once the deadline has passed, and null beyond 30 days out, where a
/// countdown tells the reader nothing. Never rounds up, so the number shown
/// is never more time than there really is.
String? formatMallCountdown(Duration left) {
  if (left <= Duration.zero || left.inDays > 30) return null;
  if (left.inDays >= 1) return '${left.inDays}d ${left.inHours % 24}h';
  if (left.inHours >= 1) return '${left.inHours}h ${left.inMinutes % 60}m';
  return '${left.inMinutes}m ${left.inSeconds % 60}s';
}

/// Spoken form of [formatMallCountdown], e.g. "4 hours 12 minutes".
String? spokenMallCountdown(Duration left) {
  if (left <= Duration.zero || left.inDays > 30) return null;
  String unit(int value, String name) =>
      '$value $name${value == 1 ? '' : 's'}';
  if (left.inDays >= 1) {
    return '${unit(left.inDays, 'day')} ${unit(left.inHours % 24, 'hour')}';
  }
  if (left.inHours >= 1) {
    return '${unit(left.inHours, 'hour')} '
        '${unit(left.inMinutes % 60, 'minute')}';
  }
  return '${unit(left.inMinutes, 'minute')} '
      '${unit(left.inSeconds % 60, 'second')}';
}

/// Time left, in the form it is shown and the form it is spoken.
@immutable
class MallRemaining {
  const MallRemaining({required this.text, required this.spoken});

  /// Compact display text, e.g. "4h 12m".
  final String text;

  /// Full spoken form, e.g. "4 hours 12 minutes".
  final String spoken;

  /// Both forms of [left], or null when there is nothing worth counting.
  static MallRemaining? of(Duration left) {
    final text = formatMallCountdown(left);
    if (text == null) return null;
    return MallRemaining(text: text, spoken: spokenMallCountdown(left) ?? text);
  }

  @override
  bool operator ==(Object other) =>
      other is MallRemaining && other.text == text && other.spoken == spoken;

  @override
  int get hashCode => Object.hash(text, spoken);
}

/// A live countdown to a real deadline the server sent.
///
/// Ticks every second inside the last hour and every minute before that, so a
/// deal ending tomorrow costs one rebuild a minute. The timer stops when the
/// deadline passes and whenever `TickerMode` mutes this subtree (the Mall is
/// muted while Reels is showing), so a backgrounded page ticks nothing.
///
/// A countdown is information, not decoration, so it still runs under reduced
/// motion — there is simply nothing animated about it.
class MallCountdown extends StatefulWidget {
  const MallCountdown({
    required this.endsUtc,
    required this.builder,
    super.key,
    this.now,
  });

  final DateTime endsUtc;

  /// Called with the time left, or null once it has run out.
  final Widget Function(BuildContext context, MallRemaining? remaining)
  builder;

  /// Clock behind the countdown; tests pin it.
  final DateTime Function()? now;

  @override
  State<MallCountdown> createState() => _MallCountdownState();
}

class _MallCountdownState extends State<MallCountdown> {
  Timer? _timer;
  Duration _left = Duration.zero;
  bool _ticking = true;

  @override
  void initState() {
    super.initState();
    _left = _remaining();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ticking = TickerMode.valuesOf(context).enabled;
    _schedule();
  }

  @override
  void didUpdateWidget(MallCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsUtc != widget.endsUtc) {
      _left = _remaining();
      _schedule();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _remaining() =>
      widget.endsUtc.toUtc().difference((widget.now ?? DateTime.now)().toUtc());

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (!_ticking || _left <= Duration.zero) return;
    final period = _left.inHours >= 1
        ? const Duration(minutes: 1)
        : const Duration(seconds: 1);
    _timer = Timer.periodic(period, (_) => _tick());
  }

  void _tick() {
    final left = _remaining();
    final wasCoarse = _left.inHours >= 1;
    if (!mounted) return;
    setState(() => _left = left);
    // Crossing into the last hour switches the tick to seconds.
    if (left <= Duration.zero || (wasCoarse && left.inHours < 1)) _schedule();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, MallRemaining.of(_left));
}
