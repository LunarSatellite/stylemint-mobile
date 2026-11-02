/// Seller-app routes for multi-shop bundles. The detail path is exactly the
/// seller deep link the backend puts in bundle notifications (shop bundles
/// contract §B4: `stylemint://vendor/bundles/{id}`).
abstract final class VendorBundleRoutes {
  static const list = '/vendor/bundles';
  static const detail = '/vendor/bundles/:bundleId';

  static String detailPath(String bundleId) =>
      '/vendor/bundles/${Uri.encodeComponent(bundleId)}';
}

final _guid = RegExp(
  r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// Where a bundle notice opens in the seller app, or null when it is not
/// one for the seller (a creator owner's notice links to Creator Studio on
/// the web, so it falls through).
///
/// Bundle notices carry a `type` naming the bundle event
/// (`bundle.*` / `catalog.bundle.*`), `data.bundleId` and `data.deepLink`.
/// The seller link wins; else the bundle by id when the viewer is acting as
/// a seller.
String? bundleNotificationLocation(
  String? type,
  Map<String, dynamic> data, {
  String? link,
  bool actsAsVendor = false,
}) {
  if (type == null) return null;
  final t = type.toLowerCase();
  if (t != 'bundle' &&
      !t.startsWith('bundle.') &&
      !t.startsWith('catalog.bundle')) {
    return null;
  }
  if (link != null && link.startsWith(VendorBundleRoutes.list)) return link;
  if (!actsAsVendor) return null;
  final bundleId = data['bundleId']?.toString().trim();
  if (bundleId != null && _guid.hasMatch(bundleId)) {
    return VendorBundleRoutes.detailPath(bundleId);
  }
  return VendorBundleRoutes.list;
}
