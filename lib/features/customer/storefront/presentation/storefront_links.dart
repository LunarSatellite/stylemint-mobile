import 'package:stylemint_mobile_frontend/features/codes/domain/code_links.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// App routes and public links of storefronts.
abstract final class StorefrontLinks {
  /// `/creator-profile/{accountId}`.
  static String creator(String accountId) => RouteNames.creatorProfile
      .replaceFirst(':accountId', Uri.encodeComponent(accountId));

  /// `/brands/{vendorAccountId}`.
  static String brand(String vendorAccountId) => RouteNames.brandStorefront
      .replaceFirst(':vendorAccountId', Uri.encodeComponent(vendorAccountId));

  /// Shareable StyleMint link to a creator. There is no public lookup of
  /// another person's `/c/` code, so this is the web path the app's link
  /// parser opens on the creator's storefront.
  static String creatorWeb(String accountId) =>
      '${StyleMintCodeLinks.publicOrigin}${creator(accountId)}';

  /// Shareable StyleMint link to a brand storefront.
  static String brandWeb(String vendorAccountId) =>
      '${StyleMintCodeLinks.publicOrigin}${brand(vendorAccountId)}';

  /// [raw] as an absolute https URL with a host, else null. Storefronts only
  /// open https links outside the app.
  static Uri? https(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty) {
      return null;
    }
    return uri;
  }
}
