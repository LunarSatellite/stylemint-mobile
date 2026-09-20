import 'package:flutter/material.dart';

import '../../../theme/design_tokens.dart';
import 'sm_button.dart';
import 'sm_empty_state.dart';

/// Style Mint failure view — the third of the app's three absence states.
///
/// This one, and only this one, is retryable: the data exists somewhere, the
/// app just could not reach it this time. An empty list is not this — use
/// [SmEmptyState] for "nothing recorded yet" and for "does not apply to you",
/// neither of which a retry would change.
///
/// [message] is rendered verbatim; [title] is an optional heading above it.
class SmErrorView extends StatelessWidget {
  const SmErrorView({
    super.key,
    this.message,
    this.title,
    this.onRetry,
    this.retryLabel = 'Tap to retry',
    this.compact = false,
  });

  final String? message;

  /// Optional short heading above [message].
  final String? title;

  final VoidCallback? onRetry;

  /// Label on the retry control. Kept as the original wording by default.
  final String retryLabel;

  /// Tightens the vertical rhythm for a failure inside a card or tab body.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.s24,
          vertical: compact
              ? DesignTokens.s24
              : DesignTokens.stateVerticalGap,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: DesignTokens.stateMaxWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kept as Icons.error_outline: three clienteling guards assert
              // on this exact mark to prove a failure is not rendered as an
              // empty list. The tone around it changed; the mark did not.
              const SmStateMark(icon: Icons.error_outline, failure: true),
              const SizedBox(height: DesignTokens.s20),
              if (title != null) ...[
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: DesignTokens.sectionInnerTitle,
                ),
                const SizedBox(height: DesignTokens.s8),
              ],
              if (message != null)
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              if (onRetry != null) ...[
                const SizedBox(height: DesignTokens.s24),
                SmOutlinedButton(
                  label: retryLabel,
                  onPressed: onRetry!,
                  prefixIcon: const Icon(
                    Icons.refresh,
                    size: DesignTokens.iconSmall,
                    color: DesignTokens.primaryGreen,
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
