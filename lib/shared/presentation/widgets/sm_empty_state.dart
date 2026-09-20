import 'package:flutter/material.dart';

import '../../../theme/design_tokens.dart';
import 'sm_button.dart';

/// Which kind of absence this is.
///
/// The app distinguishes three states that used to look identical. Two of them
/// live here; the third — *could not load* — is `SmErrorView`, because only
/// that one is retryable.
enum SmEmptyKind {
  /// Nothing has been recorded yet. The surface works; it has no entries.
  nothingYet,

  /// This does not apply to the person looking at it — a feature they have not
  /// joined, a record that was never attached, a section their role never uses.
  /// Offering a retry here would be a lie: nothing is going to change.
  notApplicable,
}

/// The restrained round mark that heads a state view.
class SmStateMark extends StatelessWidget {
  const SmStateMark({super.key, required this.icon, this.failure = false});

  final IconData icon;

  /// Uses the warmer failure tone instead of the quiet neutral one.
  final bool failure;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: DesignTokens.stateMarkSize,
      height: DesignTokens.stateMarkSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: failure
            ? DesignTokens.stateFailureMarkFill
            : DesignTokens.stateNeutralMarkFill,
        border: Border.all(
          color: failure
              ? DesignTokens.stateFailureMarkBorder
              : DesignTokens.stateNeutralMarkBorder,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: DesignTokens.stateMarkIconSize,
        color: failure
            ? DesignTokens.stateFailureIcon
            : DesignTokens.stateNeutralIcon,
      ),
    );
  }
}

/// Generic empty state widget — used across feeds, lists, search.
///
/// The [message] is rendered verbatim. These sentences are deliberately honest
/// ("Not tracked for this brand yet"), and a heading may sit above one but must
/// never replace or soften it. An optional [title] labels the surface; it is
/// not a claim about the data.
class SmEmptyState extends StatelessWidget {
  const SmEmptyState({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.kind = SmEmptyKind.nothingYet,
    this.compact = false,
  });

  /// The explanatory sentence. Shown unchanged.
  final String message;

  /// Optional short heading above [message].
  final String? title;

  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final SmEmptyKind kind;

  /// Tightens the vertical rhythm for a state that sits inside a card or a tab
  /// body rather than filling the page.
  final bool compact;

  IconData get _icon =>
      icon ??
      switch (kind) {
        SmEmptyKind.nothingYet => Icons.inbox_outlined,
        SmEmptyKind.notApplicable => Icons.remove_circle_outline,
      };

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onAction != null;

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
              SmStateMark(icon: _icon),
              const SizedBox(height: DesignTokens.s20),
              if (title != null) ...[
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: DesignTokens.sectionInnerTitle,
                ),
                const SizedBox(height: DesignTokens.s8),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              if (hasAction) ...[
                const SizedBox(height: DesignTokens.s24),
                SmOutlinedButton(label: actionLabel!, onPressed: onAction!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
