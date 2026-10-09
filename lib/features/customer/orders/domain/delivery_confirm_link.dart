import 'package:stylemint_mobile_frontend/core/navigation/in_app_link.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/code_links.dart';

/// The rider's proof-of-delivery QR: `https://<StyleMint host>/dc/<token>`
/// (also `stylemint://dc/<token>`).
///
/// The token is opaque — signed, single-use, bound to the hop — so it is
/// only checked for shape here; the server decides whether it is good.
abstract final class DeliveryConfirmLink {
  /// Long enough to rule out a stray path, short enough to rule out junk.
  static final RegExp _token = RegExp(r'^[A-Za-z0-9._~-]{8,512}$');

  /// The token in [raw], or null when [raw] is not a delivery QR.
  static String? token(String? raw) {
    final uri = Uri.tryParse(raw?.trim() ?? '');
    if (uri == null) return null;
    final scheme = uri.scheme.toLowerCase();
    final List<String> segments;
    if (scheme == 'stylemint') {
      segments = [uri.host, ...uri.pathSegments];
    } else if ((scheme == 'https' || scheme == 'http') &&
        isStyleMintWebHost(uri.host)) {
      segments = uri.pathSegments;
    } else {
      return null;
    }
    final parts = segments.where((s) => s.isNotEmpty).toList(growable: false);
    if (parts.length != 2 || parts.first.toLowerCase() != 'dc') return null;
    final token = parts.last;
    return _token.hasMatch(token) ? token : null;
  }

  /// The payload to send for [token] when only the token survived — an app
  /// link routed by path, say. The canonical public origin, as the rider's
  /// QR carries.
  static String payloadFor(String token) =>
      '${StyleMintCodeLinks.publicOrigin}/dc/$token';
}
