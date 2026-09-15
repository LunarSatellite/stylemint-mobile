import 'package:stylemint_mobile_frontend/core/navigation/in_app_link.dart';

/// What a scanned StyleMint QR code asks the app to do.
///
/// Only three kinds are recognised: a web-login code, a drop party join code
/// and a StyleMint link to something to browse. Anything else — including
/// StyleMint links that would sign in, sign out or change settings — is not
/// a StyleMint code, and the scanner opens nothing for it.
sealed class StyleMintCode {
  const StyleMintCode();

  static final _joinCode = RegExp(r'^[A-Za-z0-9]{6}$');
  static final _id = RegExp(r'^[A-Za-z0-9_-]+$');

  /// First link segment → in-app route prefix: the places a scan may open.
  static const _linkRoots = {
    'product': '/product',
    'products': '/product',
    'reels': '/reels',
    'creator-profile': '/creator-profile',
    'drop': '/drop',
    'group-cart': '/group-cart',
  };

  /// Reads a scanned QR payload; null when it isn't a StyleMint code.
  static StyleMintCode? parse(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    if (_joinCode.hasMatch(value)) return DropPartyInviteCode(value);

    final uri = Uri.tryParse(value);
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
    if (parts.length == 1 && parts.first == 'qr-login') {
      final token = uri.queryParameters['token']?.trim() ?? '';
      return token.isEmpty ? null : QrLoginCode(token);
    }
    if (parts.length != 2) return null;
    final root = _linkRoots[parts.first];
    final id = parts.last;
    if (root == null || !_id.hasMatch(id)) return null;
    // The drop party scanner's own path, not a party.
    if (root == '/drop' && id == 'scan') return null;
    return StyleMintLinkCode('$root/$id');
  }
}

/// Cross-device login to Brand Studio or Creator Studio on the web:
/// `stylemint://qr-login?token=…&app=…`.
final class QrLoginCode extends StyleMintCode {
  const QrLoginCode(this.token);

  final String token;
}

/// A drop party's 6-character join code.
final class DropPartyInviteCode extends StyleMintCode {
  const DropPartyInviteCode(this.joinCode);

  final String joinCode;
}

/// A StyleMint link to a product, reel, creator, drop party or group cart.
final class StyleMintLinkCode extends StyleMintCode {
  const StyleMintLinkCode(this.route);

  /// The in-app route, e.g. `/product/{id}`.
  final String route;
}
