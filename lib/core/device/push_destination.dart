/// Resolves the destination a tapped notification should open.
///
/// Kept apart from the widget that uses it so it can be tested: the tap
/// handling itself lives on the app's State, next to the deep-link path it
/// reuses, and is not reachable from a unit test.
///
/// **The server's FCM data keys are not pinned by any contract in this repo.**
/// The notifications documentation covers the inbox API
/// (`GET /api/v1/notifications/inbox`, `NotificationDispatchDto`) and says
/// nothing about the push payload, so this accepts the spellings a backend
/// plausibly sends and returns null for anything else. Returning null is not a
/// failure: a notification that only tells the user something has no
/// destination, and opening the app is the right outcome.
///
/// When the contract is confirmed, narrow [_keys] to what the server actually
/// sends rather than leaving the guesses in place.
///
/// Since 2026-10-09 the server routes by `type` instead (see
/// `notification_route.dart`, which tries these keys first).
library;

import 'package:stylemint_mobile_frontend/features/scan/domain/style_mint_code.dart';
import 'package:stylemint_mobile_frontend/routes/deep_links.dart';

const List<String> _keys = ['deepLink', 'deep_link', 'link', 'url', 'route'];

Uri? pushDestinationUri(Map<String, dynamic> data) {
  for (final key in _keys) {
    final raw = data[key]?.toString().trim();
    if (raw == null || raw.isEmpty) continue;

    // A bare path ("/orders/123") is not something the deep-link path can
    // read, so it is given the app's own scheme. `stylemint://orders/123`
    // rather than `stylemint:///orders/123`: the first segment lands in the
    // URI's host, which _navigate rebuilds back into the path.
    final candidate = raw.startsWith('/')
        ? 'stylemint://${raw.substring(1)}'
        : raw;
    final uri = Uri.tryParse(candidate);
    if (uri == null || uri.scheme.isEmpty) continue;
    return uri;
  }
  return null;
}

/// The go_router location for a deep link — the conversion `_navigate` in
/// main.dart applies to every link, kept here so a notification resolved
/// in-app (the inbox) lands where the same link would from outside.
///
///  * StyleMint codes (`stylemint://c/{code}`, `https://<host>/c/{code}`)
///    open the resolve screen; a tag's `via=nfc` is kept.
///  * Brand and creator storefront links open the storefront in-app.
///  * Anything else becomes its path: an https link's path as-is, a
///    custom-scheme link's host rebuilt in front of it
///    (`stylemint://auth/magic` -> `/auth/magic`). The query is kept.
String deepLinkLocation(Uri uri) {
  final styleMintCode = StyleMintCode.parse(uri.toString());
  if (styleMintCode is StyleMintShortCode) return styleMintCode.route;
  final storefront = styleMintStorefrontRoute(uri.toString());
  if (storefront != null) return storefront;
  final rawPath = uri.scheme == 'stylemint' && uri.host.isNotEmpty
      ? '/${uri.host}${uri.path}'
      : uri.path;
  final path = rawPath.startsWith('/') ? rawPath : '/$rawPath';
  final query = uri.queryParameters.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');
  return query.isEmpty ? path : '$path?$query';
}
