import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The designed failure state.
///
/// A raw exception string is not a message to a buyer, and a bare spinner that
/// never resolves is not a state at all. This says what did not load, in the
/// same voice as the rest of the page, and offers the one action that can fix
/// it. The technical [detail] is optional and always secondary — it is there
/// for a support conversation, not for the buyer to decode.
class MallErrorState extends StatelessWidget {
  const MallErrorState({
    required this.title,
    super.key,
    this.body,
    this.detail,
    this.retryLabel = 'Try again',
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  /// Plain language, e.g. "We couldn't load this order".
  final String title;

  /// What the buyer can do about it.
  final String? body;

  /// Short technical hint, set small and muted. Never the only thing shown.
  final String? detail;

  final String retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final detailText = detail;
    final retry = onRetry;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s24,
            vertical: DesignTokens.s32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MallEmptyState(
                title: title,
                body: body,
                icon: icon,
                actionLabel: retry == null ? null : retryLabel,
                onAction: retry,
              ),
              if (detailText != null) ...[
                const SizedBox(height: DesignTokens.s16),
                Text(
                  detailText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 11.5,
                    height: 1.4,
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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
    final content = Center(
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

    // At 320dp with a large text scale the column is taller than the box a
    // bounded parent (an `Expanded`, a `SliverFillRemaining`) hands it, and
    // centred content clips instead of scrolling. Own that here so no caller
    // has to wrap this in its own `SingleChildScrollView`.
    //
    // Only when the height is actually bounded: given unbounded height (a
    // plain `Column`, or a caller that is already scrolling) a scroll view
    // has no viewport to size against, so the content goes through as-is and
    // nothing nests two scrollables.
    //
    // A caller must not ask this widget for an intrinsic height — put it in
    // a `SliverFillRemaining` scroll body rather than one with
    // `hasScrollBody: false`, and not under an `IntrinsicHeight`.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) return content;
        return SingleChildScrollView(
          // Carrying the incoming `minHeight` through keeps both normal
          // cases pixel-identical. Under a tight parent (an `Expanded`)
          // min == max, so the content still fills and centres within the
          // full height, and only grows past it — and scrolls — when it
          // genuinely does not fit. Under a loose parent (a `Flexible`, a
          // sheet) min is 0, so it still shrink-wraps to its content
          // instead of stretching to fill.
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.minHeight),
            child: content,
          ),
        );
      },
    );
  }
}
