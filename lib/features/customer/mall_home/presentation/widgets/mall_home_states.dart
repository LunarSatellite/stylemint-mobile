import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The Mall's non-content states.
///
/// Each one is a designed page in the Mall's own voice rather than a spinner
/// or a bare error string: the same display face, the same single accent, the
/// same one primary action. They scroll, so pull-to-refresh still works, and
/// they clear the Home switch by the page's top inset.

/// Why the Mall has nothing to draw.
enum MallHomeProblem {
  /// No connection at all.
  offline,

  /// Reached the server and it could not compose the page.
  unreachable,

  /// Loaded fine, but every section came back empty.
  empty,
}

/// A full-page Mall state with one action.
class MallHomeStateView extends StatelessWidget {
  const MallHomeStateView({
    required this.problem,
    required this.onRetry,
    required this.topInset,
    super.key,
  });

  final MallHomeProblem problem;
  final VoidCallback onRetry;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final (:icon, :eyebrow, :title, :body, :action) = switch (problem) {
      MallHomeProblem.offline => (
        icon: Icons.wifi_off_rounded,
        eyebrow: 'Offline',
        title: 'The Mall is waiting for you',
        body:
            "You're not connected right now. Check your connection and the "
            'page will pick up where it left off.',
        action: 'Try again',
      ),
      MallHomeProblem.unreachable => (
        icon: Icons.storefront_outlined,
        eyebrow: 'Closed for a moment',
        title: "We couldn't open the Mall",
        body:
            'Something went wrong on our side. Nothing is lost — give it '
            'another go.',
        action: 'Try again',
      ),
      MallHomeProblem.empty => (
        icon: Icons.auto_awesome_outlined,
        eyebrow: 'Opening soon',
        title: 'The Mall is getting ready',
        body:
            'New arrivals, drops, creators and brands will appear here as '
            'they go live.',
        action: 'Refresh',
      ),
    };

    return ListView(
      // Always scrollable so pull-to-refresh works from every state.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsetsDirectional.only(
        top: topInset + DesignTokens.s48,
        bottom: DesignTokens.s48,
      ),
      children: [
        MallEmptyState(
          icon: icon,
          eyebrow: eyebrow,
          title: title,
          body: body,
          actionLabel: action,
          onAction: onRetry,
        ),
      ],
    );
  }
}
