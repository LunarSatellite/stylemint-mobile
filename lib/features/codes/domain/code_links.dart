import 'package:stylemint_mobile_frontend/core/navigation/in_app_link.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/style_mint_code_format.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// Links for StyleMint codes. A QR on screen, a printed shelf card and an
/// NFC tag only ever carry one of these — a StyleMint https link — never a
/// link to another site or app.
abstract final class StyleMintCodeLinks {
  /// Where `/c/{code}` links live (backend `Codes:PublicBaseUrl`).
  static const String publicOrigin = 'https://stylemint.voyageritnepal.com';

  /// The public link for [code]. The backend's [serverUrl] is kept when it
  /// is an https StyleMint link to that same code; anything else falls back
  /// to the canonical link.
  static String publicUrl(String code, {String? serverUrl}) {
    final uri = Uri.tryParse(serverUrl?.trim() ?? '');
    if (uri != null &&
        uri.scheme == 'https' &&
        isStyleMintWebHost(uri.host) &&
        !uri.hasPort &&
        uri.pathSegments.length == 2 &&
        uri.pathSegments.first == 'c' &&
        StyleMintCodeFormat.normalize(uri.pathSegments.last) == code) {
      return 'https://${uri.host.toLowerCase()}/c/$code';
    }
    return '$publicOrigin/c/$code';
  }

  /// The link written to NFC tags: [link] with `via=nfc`, so a tap is
  /// counted as a tap rather than an ordinary link.
  static String nfcUrl(String link) => Uri.parse(
    link,
  ).replace(queryParameters: const {'via': 'nfc'}).toString();

  /// The in-app route that resolves [code] as opened [via].
  static String route(String code, CodeScanVia via) =>
      '${RouteNames.styleMintCodeRoot}$code?via=${via.wireName}';
}
