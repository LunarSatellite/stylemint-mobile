import 'package:package_info_plus/package_info_plus.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

/// The origins an embed slot's host page is loaded under.
///
/// Two are needed because the platforms disagree:
/// - YouTube requires API clients to identify themselves in the HTTP Referer
///   with their store app ID, so a YouTube reel's page loads as
///   `https://<app id>`.
/// - TikTok's Embed Player sends no events to a page on that kind of origin
///   (checked on device), so TikTok and Facebook reels load under a normal
///   site origin.
class EmbedOrigins {
  const EmbedOrigins({required this.appOrigin, required this.webOrigin});

  /// Used only if the app's package name cannot be read.
  static const fallbackAppId = 'app.stylemint.stylemint_mobile_frontend';

  static const _webOrigin = String.fromEnvironment(
    'EMBED_WEB_ORIGIN',
    defaultValue: 'https://stylemint.voyageritnepal.com',
  );

  final String appOrigin;
  final String webOrigin;

  String forPlatform(SocialPlatform platform) =>
      platform == SocialPlatform.youtube ? appOrigin : webOrigin;

  static Future<EmbedOrigins> resolve() async {
    var appId = fallbackAppId;
    try {
      final name = (await PackageInfo.fromPlatform()).packageName;
      if (name.isNotEmpty) appId = name;
    } on Exception {
      // Keep the fallback: it is this app's Android package name.
    }
    return EmbedOrigins(
      appOrigin: 'https://${appId.toLowerCase()}',
      webOrigin: _webOrigin,
    );
  }
}
