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
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

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
///  * The site itself (`https://<host>/`) opens home: the router has no page
///    at `/`.
///  * An email's button, `https://<host>/app/<app route>`, opens that route:
///    the `/app` prefix is dropped (`/app/orders/NK2026-00041` ->
///    `/orders/NK2026-00041`), and `/app` alone opens home. The web page
///    behind the same link hands phones without App Links to
///    `stylemint://<app route>`, which needs no unwrapping.
String deepLinkLocation(Uri uri) {
  final appLinkTarget = _appLinkTarget(uri);
  if (appLinkTarget != null) return deepLinkLocation(appLinkTarget);

  final styleMintCode = StyleMintCode.parse(uri.toString());
  if (styleMintCode is StyleMintShortCode) return styleMintCode.route;
  final storefront = styleMintStorefrontRoute(uri.toString());
  if (storefront != null) return storefront;
  final rawPath = uri.scheme == 'stylemint' && uri.host.isNotEmpty
      ? '/${uri.host}${uri.path}'
      : uri.path;
  final path = rawPath.startsWith('/') ? rawPath : '/$rawPath';
  if (path == '/') return RouteNames.home;
  final query = uri.queryParameters.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');
  return query.isEmpty ? path : '$path?$query';
}

/// The first path segment of an email link (`https://<host>/app/...`).
const _appLinkSegment = 'app';

/// [uri] without its leading `/app` — the same link as the app route it
/// names — or null when [uri] is not an `/app` link.
///
/// `stylemint://app/orders/X` counts too: there the segment lands in the
/// host. The result keeps the scheme, so a custom-scheme link stays one
/// (its next segment becomes the host) and an https link keeps its host.
Uri? _appLinkTarget(Uri uri) {
  final List<String> rest;
  if (uri.scheme == 'stylemint') {
    if (uri.host != _appLinkSegment) return null;
    rest = uri.pathSegments;
  } else {
    final segments = uri.pathSegments;
    if (segments.isEmpty || segments.first != _appLinkSegment) return null;
    rest = segments.sublist(1);
  }
  final inner = rest.where((s) => s.isNotEmpty).toList();
  final query = uri.hasQuery ? uri.query : null;
  if (uri.scheme == 'stylemint') {
    return Uri(
      scheme: 'stylemint',
      host: inner.isEmpty ? '' : inner.first,
      pathSegments: inner.length > 1 ? inner.sublist(1) : null,
      query: query,
    );
  }
  return uri.replace(pathSegments: inner, query: query);
}
