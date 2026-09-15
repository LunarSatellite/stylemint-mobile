/// Where an embed slot's WebView may navigate.
///
/// Reels play in the platforms' official embedded players, and the WebView
/// never takes a touch (it sits under an `IgnorePointer`). This policy is the
/// second line of defence for the rule that nothing on a reel surface sends
/// the viewer out of StyleMint (owner decision, 2026-09-14): a player or SDK
/// script that tries to take the page to the platform's site or app is
/// stopped. It never touches, hides or restyles the players themselves.
///
/// - Every scheme but http(s) is cancelled: `intent://`, `snssdk…://`,
///   `fb://`, `youtube://`, `market://` and the like are how a page hands off
///   to another app. Only the document-internal `about:blank` /
///   `about:srcdoc`, and `data:` / `blob:` inside a frame, are let through;
///   they cannot leave the WebView.
/// - A top-level navigation (the page itself, or a request for a new window)
///   may only load the slot's host document or an official player / SDK
///   resource.
/// - An http(s) navigation inside a frame is allowed: it stays inside its
///   iframe, and the players load their own frames that way. On Android the
///   plugin cannot cancel frame navigations at all (`shouldOverrideUrlLoading`
///   only governs the main frame there); iOS reports every one.
/// - Pre-loading and warm-up add no navigations: a pre-loaded TikTok player
///   is an ordinary frame on `www.tiktok.com/player/`, and its scripts,
///   styles and video, like the host page's `preconnect` hints, are
///   subresource loads that never reach this policy. Their static and CDN
///   hosts are deliberately not top-level destinations.
abstract final class EmbedNavigationPolicy {
  static final RegExp _facebookPluginPath = RegExp(
    r'^/(v\d+(\.\d+)?/)?plugins/',
  );

  /// Whether the WebView may load [url].
  ///
  /// [isTopLevel] is true for the main frame and for new-window requests.
  /// [hostOrigin] is the origin the slot's host page is loaded under.
  static bool allows(
    Uri url, {
    required bool isTopLevel,
    String? hostOrigin,
  }) {
    switch (url.scheme.toLowerCase()) {
      case 'about':
        final page = url.path.toLowerCase();
        return page == 'blank' || page == 'srcdoc';
      case 'data':
      case 'blob':
        return !isTopLevel;
      case 'http':
      case 'https':
        break;
      default:
        return false;
    }
    if (url.host.isEmpty) return false;
    if (!isTopLevel) return true;
    return isHostDocument(url, hostOrigin) || isOfficialPlayerUrl(url);
  }

  /// Whether [url] is on [hostOrigin], the slot's host page.
  static bool isHostDocument(Uri url, String? hostOrigin) {
    final host = hostOrigin == null ? null : Uri.tryParse(hostOrigin.trim());
    if (host == null || host.host.isEmpty) return false;
    return url.scheme.toLowerCase() == host.scheme.toLowerCase() &&
        url.host.toLowerCase() == host.host.toLowerCase() &&
        url.port == host.port;
  }

  /// The official player and SDK resources a reel needs to play: the YouTube
  /// IFrame Player API and embed player, TikTok's Embed Player, and the
  /// Facebook JS SDK with its video plugin.
  static bool isOfficialPlayerUrl(Uri url) {
    if (url.scheme.toLowerCase() != 'https') return false;
    final path = url.path;
    return switch (url.host.toLowerCase()) {
      'www.youtube.com' || 'youtube.com' =>
        path == '/iframe_api' ||
            path == '/player_api' ||
            path.startsWith('/embed/') ||
            path.startsWith('/s/player/'),
      'www.tiktok.com' => path.startsWith('/player/'),
      'connect.facebook.net' => true,
      'www.facebook.com' => _facebookPluginPath.hasMatch(path),
      _ => false,
    };
  }
}
