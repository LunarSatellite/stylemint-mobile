import 'package:stylemint_mobile_frontend/core/navigation/in_app_link.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/code_links.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/style_mint_code_format.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/unit_marker_format.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// What a scanned StyleMint QR code asks the app to do.
///
/// Only five kinds are recognised: a web-login code, a drop party join code,
/// a per-unit tag code, a StyleMint code link (`/c/{code}`: a shelf tag,
/// store or person) and a StyleMint link to something to browse. Anything
/// else — including StyleMint links that would sign in, sign out or change
/// settings — is not a StyleMint code, and the scanner opens nothing for it.
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
    'brands': '/brands',
    'drop': '/drop',
    'group-cart': '/group-cart',
  };

  /// Reads a scanned QR payload; null when it isn't a StyleMint code.
  static StyleMintCode? parse(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    if (_joinCode.hasMatch(value)) return DropPartyInviteCode(value);
    // A per-unit tag: 26 Crockford characters and nothing else. Checked
    // before the URL parse because a bare code is not a URI, and kept out of
    // any link form on purpose — a tag code is a credential, so it travels in
    // a request body and never in a link somebody could paste or share.
    final marker = UnitMarkerFormat.normalize(value);
    if (marker != null) return UnitMarkerTagCode(marker);

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
    if (parts.length == 2 && parts.first == 'c') {
      final code = StyleMintCodeFormat.normalize(parts.last);
      if (code == null) return null;
      // NFC tags carry `?via=nfc`; nothing else in a link is trusted.
      final fromTag = uri.queryParameters['via']?.trim().toLowerCase() == 'nfc';
      return StyleMintShortCode(code, via: fromTag ? CodeScanVia.nfc : null);
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

/// A StyleMint code link — `https://<StyleMint host>/c/{code}` or
/// `stylemint://c/{code}` — for a product on a shelf, a store or a person.
final class StyleMintShortCode extends StyleMintCode {
  const StyleMintShortCode(this.code, {this.via});

  /// The 8-character code, upper case.
  final String code;

  /// [CodeScanVia.nfc] when the link came off an NFC tag (`via=nfc`);
  /// null for an ordinary link.
  final CodeScanVia? via;

  /// The in-app route: `/c/{code}`, or `/c/{code}?via=Nfc` for a tag. With
  /// no `via` the code resolves as a link.
  String get route {
    final from = via;
    return from == null
        ? '${RouteNames.styleMintCodeRoot}$code'
        : StyleMintCodeLinks.route(code, from);
  }
}

/// A StyleMint link to a product, reel, creator, drop party or group cart.
final class StyleMintLinkCode extends StyleMintCode {
  const StyleMintLinkCode(this.route);

  /// The in-app route, e.g. `/product/{id}`.
  final String route;
}

/// A per-unit tag's 26-character code, read straight off the item.
///
/// This is a **credential**, not an identifier. It never becomes a route, a
/// query parameter or a deep link: the scanner hands it to
/// `POST v1/public/unit-markers/scan` in the request body, and what comes
/// back — an opaque marker id — is what the app navigates with.
final class UnitMarkerTagCode extends StyleMintCode {
  const UnitMarkerTagCode(this.marker);

  final String marker;

  /// Deliberately does not name the code.
  @override
  String toString() => 'UnitMarkerTagCode(<redacted>)';
}
