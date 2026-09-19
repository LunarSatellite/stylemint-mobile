import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Tone of a notice. Colour is the only thing that changes; the wording still
/// has to say what happened on its own, because colour is not a sentence.
enum UnitMarkerNoticeTone { neutral, good, warn, bad }

/// A headed block of prose — the shape every state on these screens lands in:
/// an empty register, a tag bound to nothing, a reading with no place, a
/// failure.
///
/// Laid out as a [Row] with an [Expanded] body so that at 320dp with a 1.3
/// text scale the sentence wraps under its own width instead of overflowing
/// past the icon.
class UnitMarkerNotice extends StatelessWidget {
  const UnitMarkerNotice({
    required this.icon,
    required this.heading,
    required this.body,
    this.tone = UnitMarkerNoticeTone.neutral,
    this.action,
    super.key,
  });

  final IconData icon;
  final String heading;
  final String body;
  final UnitMarkerNoticeTone tone;

  /// An optional control under the prose — dismissing an outcome, retrying a
  /// call. Stacked below rather than beside, so a long label has the full
  /// width.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      UnitMarkerNoticeTone.neutral => DesignTokens.textLight,
      UnitMarkerNoticeTone.good => DesignTokens.colorSuccess,
      UnitMarkerNoticeTone.warn => DesignTokens.warning300,
      UnitMarkerNoticeTone.bad => DesignTokens.colorError,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: DesignTokens.s20, color: color),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      heading,
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: color,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      body,
                      style: DesignTokens.mediumRegular.copyWith(
                        color: DesignTokens.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (action case final control?) ...[
            const SizedBox(height: DesignTokens.s12),
            control,
          ],
        ],
      ),
    );
  }
}

/// A label above a value, for a fact that came off the wire.
///
/// There is no "absent" rendering here on purpose: a caller with nothing to
/// show must not build this widget at all, rather than build it with a dash
/// or a zero in the value.
class UnitMarkerFact extends StatelessWidget {
  const UnitMarkerFact({
    required this.label,
    required this.value,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DesignTokens.s12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(
          value,
          style: DesignTokens.body.copyWith(color: valueColor),
        ),
      ],
    ),
  );
}
