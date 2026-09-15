/// Connections an embed slot's host page opens ahead of TikTok's Embed Player.
///
/// Only resource hints (`dns-prefetch`, `preconnect`) to TikTok's own player
/// hosts: nothing is fetched or scraped, and no navigation happens, so
/// `EmbedNavigationPolicy` is not involved. The hosts are the ones the
/// official player page (`https://www.tiktok.com/player/v1/{id}`) loads from;
/// the video CDN is chosen per viewer at play time and is not listed.
abstract final class EmbedWarmup {
  /// Origins the TikTok player page needs before it can play.
  static const tikTokOrigins = <String>[
    // The player page itself.
    'https://www.tiktok.com',
    // Its scripts and styles.
    'https://sf16-website-login.neutral.ttwstatic.com',
    // Its interface strings.
    'https://sf-i18n-resources.tiktokcdn.com',
  ];

  /// How long a warm-up is worth before it is repeated. Browsers close
  /// pre-opened connections that go unused for about ten seconds.
  static const interval = Duration(seconds: 10);

  static const _tikTokDomains = [
    'tiktok.com',
    'tiktokcdn.com',
    'tiktokcdn-us.com',
    'tiktokv.com',
    'ttwstatic.com',
  ];

  /// Whether [origin] is a bare `https://` origin on a TikTok-owned domain.
  static bool isOfficialTikTokOrigin(String origin) {
    final uri = Uri.tryParse(origin);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty ||
        uri.path.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return false;
    }
    final host = uri.host.toLowerCase();
    return _tikTokDomains.any((d) => host == d || host.endsWith('.$d'));
  }
}
