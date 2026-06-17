import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// Wraps a screen that can legitimately end up as the *only* page on the
/// navigation stack — e.g. the creator/vendor dashboards, which are reached via
/// `context.go(...)` after the onboarding/apply flow clears the back history,
/// or via a cold-start deep link.
///
/// Without this guard, pressing the Android system back button on such a screen
/// finds nothing to pop and **exits the app**. This intercepts that case: it
/// pops normally when there is history, and otherwise routes to [fallback]
/// (the customer home by default) so back is never a dead-end.
class RootBackGuard extends StatelessWidget {
  const RootBackGuard({
    super.key,
    required this.child,
    this.fallback = RouteNames.home,
  });

  final Widget child;

  /// Where to go when there is no page to pop back to.
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallback);
        }
      },
      child: child,
    );
  }
}
