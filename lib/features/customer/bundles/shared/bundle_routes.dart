/// Buyer routes for bundles (shop bundles contract §B10).
///
/// `stylemint://bundles/{id}` and an `/app/bundles/{id}` link both land on
/// [detail] (the `/app` prefix is stripped by `deepLinkLocation`). The web
/// share link `/shop/b/{id}` is not claimed by the app.
abstract final class BundleRoutes {
  static const detail = '/bundles/:bundleId';

  /// The reel tag the bundle was opened from (`taggedBundleId`), so the add
  /// credits that reel's creator.
  static const tagParam = 't';

  /// An affiliate code carried in from a link.
  static const refParam = 'ref';

  static String detailPath(
    String bundleId, {
    String? taggedBundleId,
    String? affiliateCode,
  }) {
    final query = <String, String>{
      if (taggedBundleId != null && taggedBundleId.isNotEmpty)
        tagParam: taggedBundleId,
      if (affiliateCode != null && affiliateCode.isNotEmpty)
        refParam: affiliateCode,
    };
    final path = '/bundles/${Uri.encodeComponent(bundleId)}';
    return query.isEmpty
        ? path
        : Uri(path: path, queryParameters: query).toString();
  }
}
