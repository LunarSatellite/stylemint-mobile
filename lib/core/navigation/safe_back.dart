import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// Back navigation that never dead-ends.
///
/// A page opened with `go` — a deep link, a notification, a shared link, or a
/// flow that clears history — is the only page on its stack, so a plain
/// `context.pop()` has nothing to pop and the back button silently does
/// nothing. [popOrHome] pops when there is history and otherwise goes to the
/// home of the area the page belongs to.
extension SafeBack on BuildContext {
  void popOrHome() {
    if (canPop()) {
      pop();
      return;
    }
    final path = GoRouter.maybeOf(this)?.state.uri.path ?? '';
    go(backFallbackFor(path));
  }
}

/// Home for [path]: creator pages return to the creator studio, vendor pages to
/// the vendor dashboard, everything else to the shopping feed.
String backFallbackFor(String path) {
  if (path.startsWith('/creator/') && path != RouteNames.creatorHome) {
    return RouteNames.creatorHome;
  }
  if (path.startsWith('/vendor/') && path != RouteNames.vendorHome) {
    return RouteNames.vendorHome;
  }
  return RouteNames.home;
}
