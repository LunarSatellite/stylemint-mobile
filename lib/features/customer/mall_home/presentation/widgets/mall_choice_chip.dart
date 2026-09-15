import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A single-choice pill (sort order, rating). Selected reads as light on
/// dark, keeping green for primary actions. 44dp tall hit area.
class MallChoiceChip extends StatelessWidget {
  const MallChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.semanticLabel,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Spoken instead of [label], e.g. "Price, low to high" for "Price ↑".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: AnimatedContainer(
            duration: MallMetrics.reduceMotion(context)
                ? Duration.zero
                : DesignTokens.motionFast,
            curve: DesignTokens.motionCurve,
            constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? DesignTokens.textWhite
                  : DesignTokens.surfaceRaised,
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.25,
                color: selected
                    ? DesignTokens.textDark
                    : DesignTokens.textLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
