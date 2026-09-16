import 'package:stylemint_mobile_frontend/core/navigation/in_app_link.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// A backend account id — every brand and creator link carries a GUID.
final _accountId = RegExp(
  r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// The in-app route for a shared brand or creator storefront link, or null for
/// any other link.
///
/// Accepts the web pages the backend serves
/// (`https://<StyleMint host>/brands/{vendorAccountId}` and
/// `https://<StyleMint host>/creator-profile/{accountId}`), the custom-scheme
/// forms those pages' app-dock buttons use (`stylemint://brands/{id}`,
/// `stylemint://creator-profile/{id}`), and the bare app paths.
///
/// A link of the right shape whose id is not a GUID resolves to
/// [RouteNames.home]: the storefront screens fetch by id, so a junk id would
/// otherwise open a permanently empty page. Anything that is not a storefront
/// link at all gives null, and the caller falls back to its own handling.
String? styleMintStorefrontRoute(String? link) {
  final raw = link?.trim() ?? '';
  if (raw.isEmpty) return null;
  final uri = Uri.tryParse(raw);
  if (uri == null) return null;

  final List<String> segments;
  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'stylemint') {
    // The first path segment of a custom-scheme link lands in `host`
    // (stylemint://brands/{id} -> host 'brands', path '/{id}').
    segments = [uri.host, ...uri.pathSegments];
  } else if (scheme.isEmpty) {
    if (!raw.startsWith('/') || raw.startsWith('//')) return null;
    segments = uri.pathSegments;
  } else if ((scheme == 'https' || scheme == 'http') &&
      isStyleMintWebHost(uri.host)) {
    segments = uri.pathSegments;
  } else {
    return null;
  }

  final parts = segments.where((s) => s.isNotEmpty).toList(growable: false);
  if (parts.length != 2) return null;

  final String pattern;
  final String parameter;
  switch (parts.first) {
    case 'brands':
      pattern = RouteNames.brandStorefront;
      parameter = ':vendorAccountId';
    case 'creator-profile':
      pattern = RouteNames.creatorProfile;
      parameter = ':accountId';
    default:
      return null;
  }

  final id = parts.last;
  if (!_accountId.hasMatch(id)) return RouteNames.home;
  return pattern.replaceFirst(parameter, id);
}
