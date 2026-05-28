import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Reusable bottom action bar (Figma "Sticky Button").
///
/// Renders a full-width primary green pill, with an optional secondary gray
/// pill below it, and an optional top divider. Used by onboarding, interests,
/// follow-creators and other "sticky CTA" screens.
class SmStickyBottomBar extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryEnabled;
  final Widget? primaryTrailing;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool showTopDivider;

  const SmStickyBottomBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryEnabled = true,
    this.primaryTrailing,
    this.secondaryLabel,
    this.onSecondary,
    this.showTopDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        border: showTopDivider
            ? const Border(
                top: BorderSide(color: DesignTokens.borderDefault, width: 1))
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16, DesignTokens.s24, DesignTokens.s16, DesignTokens.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: primaryEnabled ? 1 : 0.5,
            child: _Pill(
              label: primaryLabel,
              fill: DesignTokens.primaryGreen,
              textColor: DesignTokens.buttonPrimaryText,
              trailing: primaryTrailing,
              onTap: primaryEnabled ? onPrimary : null,
            ),
          ),
          if (secondaryLabel != null) ...[
            const SizedBox(height: DesignTokens.s16),
            _Pill(
              label: secondaryLabel!,
              fill: DesignTokens.buttonGrayFill,
              textColor: DesignTokens.buttonGrayText,
              onTap: onSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color fill;
  final Color textColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Pill({
    required this.label,
    required this.fill,
    required this.textColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s32, vertical: DesignTokens.s16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: DesignTokens.oneLinerSemibold.copyWith(color: textColor)),
              if (trailing != null) ...[
                const SizedBox(width: DesignTokens.s8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
