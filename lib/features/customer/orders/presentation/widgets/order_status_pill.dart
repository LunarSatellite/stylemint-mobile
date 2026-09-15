import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Semantic tone of a status pill. Only existing status tokens are used: the
/// brand green for progress and success, info blue for early stages, the
/// error red for negative endings and the warning tone for returns.
enum OrderPillTone { info, progress, success, negative, caution, neutral }

/// Compact rounded status label. Wraps rather than truncating so a long
/// label at a large text scale never overflows.
class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill({required this.label, required this.tone, super.key});

  final String label;
  final OrderPillTone tone;

  static (Color, Color) colorsFor(OrderPillTone tone) => switch (tone) {
    OrderPillTone.info => (
      DesignTokens.infoFillDark,
      DesignTokens.infoTextLight,
    ),
    OrderPillTone.progress => (
      DesignTokens.primaryGreen.withValues(alpha: 0.16),
      DesignTokens.primaryGreen,
    ),
    OrderPillTone.success => (
      DesignTokens.primaryGreen,
      DesignTokens.buttonPrimaryText,
    ),
    OrderPillTone.negative => (
      DesignTokens.colorError.withValues(alpha: 0.16),
      DesignTokens.colorError,
    ),
    OrderPillTone.caution => (
      DesignTokens.warningFillDark,
      DesignTokens.warningTextLight,
    ),
    OrderPillTone.neutral => (
      DesignTokens.bgAppBodyLight,
      DesignTokens.textLight,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = colorsFor(tone);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 10, 4),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: 0.1,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
