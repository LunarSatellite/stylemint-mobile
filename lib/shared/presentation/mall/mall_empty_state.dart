import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Polished, illustration-free empty state: an optional icon on a raised
/// disc, a display-face title (it stands in for a section title), body copy
/// and one primary action. Width is capped for tablets.
class MallEmptyState extends StatelessWidget {
  const MallEmptyState({
    required this.title,
    super.key,
    this.body,
    this.eyebrow,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? body;
  final String? eyebrow;
  final IconData? icon;

  /// The action shows only when both [actionLabel] and [onAction] are set.
  final String? actionLabel;
  final VoidCallback? onAction;

  static const TextStyle _bodyStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: DesignTokens.textMuted,
  );

  @override
  Widget build(BuildContext context) {
    final iconData = icon;
    final eyebrowText = eyebrow;
    final bodyText = body;
    final label = actionLabel;
    final action = onAction;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            DesignTokens.s24,
            DesignTokens.s32,
            DesignTokens.s24,
            DesignTokens.s32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconData != null) ...[
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: DesignTokens.surfaceRaised,
                    shape: BoxShape.circle,
                    boxShadow: DesignTokens.shadowCard,
                  ),
                  child: SizedBox.square(
                    dimension: 72,
                    child: Icon(
                      iconData,
                      size: 28,
                      color: DesignTokens.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.s20),
              ],
              if (eyebrowText != null) ...[
                MallEyebrow(eyebrowText, maxLines: 2),
                const SizedBox(height: DesignTokens.s8),
              ],
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: DesignTokens.displaySection,
                ),
              ),
              if (bodyText != null) ...[
                const SizedBox(height: DesignTokens.s8),
                Text(bodyText, textAlign: TextAlign.center, style: _bodyStyle),
              ],
              if (label != null && action != null) ...[
                const SizedBox(height: DesignTokens.s24),
                MallPrimaryCta(label: label, onPressed: action),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
