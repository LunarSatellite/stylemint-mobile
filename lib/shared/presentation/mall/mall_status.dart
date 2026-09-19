import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_signal.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// Status vocabulary for post-purchase surfaces (orders, returns, warranty,
// care, vendor fulfilment). The Mall's home page never needed one: a shopper
// browsing has no state to read. A buyer asking "where is my order" has
// nothing else.
//
// Rule, and the reason these live in the kit rather than in one feature: a
// status is **never carried by colour alone**. Every tone owns a glyph, and
// the pill always draws it. That holds for colour-blind users and for a phone
// in bright sun, and it means a vendor surface reusing this gets the same
// guarantee for free.

/// What a status means, in the Mall's one palette. Tone is meaning, not
/// decoration — [danger] is a real failure, not merely a stopped flow.
enum MallStatusTone {
  /// Nothing has happened yet, or the state carries no claim.
  neutral,

  /// Early, acknowledged, under way but not yet moving.
  info,

  /// Actively in motion (picked, shipped, out for delivery).
  progress,

  /// Finished well (delivered, refunded, completed).
  success,

  /// Needs the buyer, or is slipping (delayed, action required).
  caution,

  /// Ended badly or was stopped (cancelled, failed, rejected).
  danger,
}

/// Fill, ink and glyph for [tone]. The glyph is the non-colour carrier.
({Color background, Color foreground, IconData icon}) mallStatusStyle(
  MallStatusTone tone,
) => switch (tone) {
  MallStatusTone.neutral => (
    background: DesignTokens.bgAppBodyLight,
    foreground: DesignTokens.textLight,
    icon: Icons.remove_rounded,
  ),
  MallStatusTone.info => (
    background: DesignTokens.infoFillDark,
    foreground: DesignTokens.infoTextLight,
    icon: Icons.inventory_2_outlined,
  ),
  MallStatusTone.progress => (
    background: DesignTokens.primaryGreenDark,
    foreground: DesignTokens.primaryGreen,
    icon: Icons.local_shipping_outlined,
  ),
  MallStatusTone.success => (
    background: DesignTokens.primaryGreenDark,
    foreground: DesignTokens.primaryGreen,
    icon: Icons.check_circle_outline_rounded,
  ),
  MallStatusTone.caution => (
    background: DesignTokens.warningFillDark,
    foreground: DesignTokens.warning300,
    icon: Icons.schedule_rounded,
  ),
  MallStatusTone.danger => (
    background: DesignTokens.colorError.withValues(alpha: 0.16),
    foreground: DesignTokens.colorError,
    icon: Icons.cancel_outlined,
  ),
};

/// Compact status label: glyph, then text, on a tonal pill.
///
/// The glyph is not optional — pass [icon] to override the tone's default, but
/// there is no way to draw this without one. Text wraps rather than truncating
/// so a long label at 1.3× never overflows.
class MallStatusPill extends StatelessWidget {
  const MallStatusPill({
    required this.label,
    required this.tone,
    super.key,
    this.icon,
    this.semanticLabel,
    this.dense = false,
  });

  final String label;
  final MallStatusTone tone;

  /// Overrides the tone's glyph. The pill always draws one.
  final IconData? icon;

  /// Spoken form. Defaults to [label].
  final String? semanticLabel;

  /// Tighter padding and a smaller glyph, for list rows.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = mallStatusStyle(tone);
    final scaler = MallMetrics.scalerOf(context);
    final glyphSize = scaler.scale(dense ? 12 : 14);
    return Semantics(
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            dense ? 8 : 10,
            dense ? 4 : 6,
            dense ? 10 : 12,
            dense ? 4 : 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                // Optically centres the glyph against the first text line at
                // any text scale.
                padding: EdgeInsetsDirectional.only(
                  top: (scaler.scale(dense ? 11 : 12) * 1.3 - glyphSize) / 2,
                  end: 6,
                ),
                child: Icon(
                  icon ?? style.icon,
                  size: glyphSize,
                  color: style.foreground,
                ),
              ),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: dense ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    letterSpacing: 0.1,
                    color: style.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The answer to "where is my order", in one block.
///
/// A glyph on a tonal disc, the state named in the display face, one plain
/// supporting line (the promise, the date, the amount coming back) and an
/// optional pill for a secondary fact. Deliberately quiet: no photograph, no
/// gradient, no motion. It is read, not admired.
class MallStatusSummary extends StatelessWidget {
  const MallStatusSummary({
    required this.title,
    required this.tone,
    super.key,
    this.eyebrow,
    this.detail,
    this.icon,
    this.trailingPillLabel,
    this.footnote,
  });

  /// The state, named plainly: "Delivered", "Refund on the way".
  final String title;
  final MallStatusTone tone;

  /// Tracked capitals above the title — the order number, usually.
  final String? eyebrow;

  /// One line under the title. Keep it to a promise or a date.
  final String? detail;

  final IconData? icon;

  /// A second fact beside the disc, e.g. "3 items".
  final String? trailingPillLabel;

  /// Small print below, e.g. an updated-at stamp. Numerals are tabular.
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final style = mallStatusStyle(tone);
    final scaler = MallMetrics.scalerOf(context);
    final discSize = scaler.scale(48).clamp(48.0, 68.0);
    final detailText = detail;
    final eyebrowText = eyebrow;
    final pillLabel = trailingPillLabel;
    final footnoteText = footnote;
    return Semantics(
      container: true,
      label: [
        ?eyebrowText,
        title,
        ?detailText,
        ?pillLabel,
        ?footnoteText,
      ].join('. '),
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          boxShadow: DesignTokens.shadowCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: discSize,
                  height: discSize,
                  decoration: BoxDecoration(
                    color: style.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon ?? style.icon,
                    size: discSize * 0.46,
                    color: style.foreground,
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrowText != null) ...[
                        MallEyebrow(eyebrowText),
                        const SizedBox(height: DesignTokens.s4),
                      ],
                      Text(title, style: DesignTokens.displaySection),
                      if (detailText != null) ...[
                        const SizedBox(height: DesignTokens.s4),
                        Text(
                          detailText,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 13,
                            height: 1.45,
                            color: DesignTokens.textLight,
                            fontFeatures: mallTabularFigures,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (pillLabel != null) ...[
                  const SizedBox(width: DesignTokens.s8),
                  MallStatusPill(
                    label: pillLabel,
                    tone: MallStatusTone.neutral,
                    icon: Icons.shopping_bag_outlined,
                    dense: true,
                  ),
                ],
              ],
            ),
            if (footnoteText != null) ...[
              const SizedBox(height: DesignTokens.s12),
              Text(
                footnoteText,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 11.5,
                  height: 1.35,
                  color: DesignTokens.textMuted,
                  fontFeatures: mallTabularFigures,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
