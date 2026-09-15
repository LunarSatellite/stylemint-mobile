import 'package:stylemint_mobile_frontend/core/config/api_config.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

const _styleMintWebHosts = {
  'stylemint.voyageritnepal.com',
  'stylemint.app',
  'www.stylemint.app',
};

final _productId = RegExp(r'^[A-Za-z0-9_-]+$');

/// The in-app product route for a StyleMint product link, or null for any
/// other link.
///
/// Accepts an app path (`/product/{id}`), a `stylemint://product/{id}` deep
/// link, or a StyleMint web URL (`https://<StyleMint host>/product/{id}`;
/// `/products/{id}` too). Callers navigate in-app with the result and do
/// nothing with a link that gives null — it is never launched.
String? styleMintProductRoute(String? link) {
  final raw = link?.trim() ?? '';
  if (raw.isEmpty) return null;
  final uri = Uri.tryParse(raw);
  if (uri == null) return null;

  final List<String> segments;
  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'stylemint') {
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
  if (parts.first != 'product' && parts.first != 'products') return null;
  final id = parts.last;
  if (!_productId.hasMatch(id)) return null;
  return RouteNames.productDetail.replaceFirst(':productId', id);
}

/// Whether [host] is one of StyleMint's own web hosts (or the API host).
bool isStyleMintWebHost(String host) {
  final value = host.toLowerCase();
  if (value.isEmpty) return false;
  if (_styleMintWebHosts.contains(value)) return true;
  return value == Uri.tryParse(ApiConfig.baseUrl)?.host.toLowerCase();
}
