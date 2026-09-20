import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_navigation_policy.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_slot_view.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_warmup.dart';

const _appOrigin = 'https://app.stylemint.stylemint_mobile_frontend';

bool _topLevel(String url, {String? hostOrigin = _appOrigin}) =>
    EmbedNavigationPolicy.allows(
      Uri.parse(url),
      isTopLevel: true,
      hostOrigin: hostOrigin,
    );

bool _inFrame(String url) => EmbedNavigationPolicy.allows(
  Uri.parse(url),
  isTopLevel: false,
  hostOrigin: _appOrigin,
);

void main() {
  test('loads the host document and the official player resources', () {
    const allowed = [
      '$_appOrigin/',
      'https://www.youtube.com/iframe_api',
      'https://www.youtube.com/embed/39bix0Z0NOQ?enablejsapi=1',
      'https://www.youtube.com/s/player/abc/www-widgetapi.vflset/www-widgetapi.js',
      'https://www.tiktok.com/player/v1/6718335390845095173?controls=0',
      'https://connect.facebook.net/en_US/sdk.js',
      'https://www.facebook.com/v21.0/plugins/video.php?href=x',
      'https://www.facebook.com/plugins/video.php?href=x',
      'about:blank',
    ];
    for (final url in allowed) {
      expect(_topLevel(url), isTrue, reason: url);
    }
    expect(
      _topLevel(
        'https://stylemint.voyageritnepal.com/',
        hostOrigin: 'https://stylemint.voyageritnepal.com',
      ),
      isTrue,
    );
  });

  test('cancels top-level navigations to platform pages and other sites', () {
    const cancelled = [
      'https://www.youtube.com/watch?v=39bix0Z0NOQ',
      'https://www.youtube.com/shorts/39bix0Z0NOQ',
      'https://m.youtube.com/watch?v=39bix0Z0NOQ',
      'https://youtu.be/39bix0Z0NOQ',
      'https://www.tiktok.com/@scout2015/video/6718335390845095173',
      'https://www.tiktok.com/login',
      'https://www.facebook.com/watch/?v=10153231379946729',
      'https://www.facebook.com/login.php',
      'https://stylemint.voyageritnepal.com/',
      'http://www.youtube.com/embed/39bix0Z0NOQ',
      'https://example.com/',
      'data:text/html,hello',
    ];
    for (final url in cancelled) {
      expect(_topLevel(url), isFalse, reason: url);
    }
  });

  test('cancels app hand-off schemes in every frame', () {
    const handOffs = [
      'intent://www.youtube.com/watch?v=x#Intent;package=com.google.android.youtube;scheme=https;end',
      'snssdk1233://aweme/detail/6718335390845095173',
      'snssdk1128://aweme/detail/6718335390845095173',
      'fb://video/10153231379946729',
      'youtube://watch?v=39bix0Z0NOQ',
      'vnd.youtube:39bix0Z0NOQ',
      'tiktok://video/1',
      'market://details?id=com.zhiliaoapp.musically',
      'itms-apps://apps.apple.com/app/id835599320',
      'mailto:someone@example.com',
      'javascript:alert(1)',
      'file:///data/local/tmp/x.html',
    ];
    for (final url in handOffs) {
      expect(_topLevel(url), isFalse, reason: 'top level: $url');
      expect(_inFrame(url), isFalse, reason: 'frame: $url');
    }
  });

  test('lets frames load their own content', () {
    const allowed = [
      'https://www.youtube.com/embed/39bix0Z0NOQ',
      'https://googleads.g.doubleclick.net/pagead/ads?x=1',
      'https://staticxx.facebook.com/x/connect/xd_arbiter/?version=46',
      'about:srcdoc',
      'data:text/html,hello',
      'blob:https://www.youtube.com/0f1e2d3c',
    ];
    for (final url in allowed) {
      expect(_inFrame(url), isTrue, reason: url);
    }
  });

  test('without a host origin only the player resources load at top level', () {
    expect(_topLevel('$_appOrigin/', hostOrigin: null), isFalse);
    expect(
      _topLevel('https://www.youtube.com/iframe_api', hostOrigin: null),
      isTrue,
    );
  });

  test('the WebView vets every navigation and never opens windows', () {
    final settings = EmbedSlotView.buildSettings();

    expect(settings.useShouldOverrideUrlLoading, isTrue);
    expect(settings.supportMultipleWindows, isFalse);
    expect(settings.javaScriptCanOpenWindowsAutomatically, isFalse);
  });

  test('a pre-loaded TikTok player loads in its frame with its assets', () {
    const player =
        'https://www.tiktok.com/player/v1/7685232277147618581?controls=0'
        '&loop=1&autoplay=0';
    const inFrame = [
      player,
      'https://sf16-website-login.neutral.ttwstatic.com/obj/tiktok_web_login_static/tiktok_4d_playback/static/js/main.285a45177d.js',
      'https://sf-i18n-resources.tiktokcdn.com/obj/i18n/strings.json',
      'https://v16-webapp-prime.tiktok.com/video/tos/alisg/abc/',
    ];
    for (final url in inFrame) {
      expect(_inFrame(url), isTrue, reason: url);
    }
    expect(_topLevel(player), isTrue);
  });

  test('TikTok asset, media and site pages are never top-level destinations', () {
    const cancelled = [
      'https://sf16-website-login.neutral.ttwstatic.com/obj/tiktok_web_login_static/x.js',
      'https://v16-webapp-prime.tiktok.com/video/tos/alisg/abc/',
      'https://www.tiktok.com/',
      'https://www.tiktok.com/@stylemint25/video/7685232277147618581',
      'https://vm.tiktok.com/ZSabc123/',
      'https://m.tiktok.com/v/7685232277147618581.html',
      'http://www.tiktok.com/player/v1/7685232277147618581',
    ];
    for (final url in cancelled) {
      expect(_topLevel(url), isFalse, reason: url);
    }
  });

  test('connection warm-up only names official TikTok origins', () {
    expect(EmbedWarmup.tikTokOrigins, contains('https://www.tiktok.com'));
    for (final origin in EmbedWarmup.tikTokOrigins) {
      expect(
        EmbedWarmup.isOfficialTikTokOrigin(origin),
        isTrue,
        reason: origin,
      );
    }
    const notOfficial = [
      'http://www.tiktok.com',
      'https://tiktok.com.example.net',
      'https://eviltiktok.com',
      'https://www.tiktok.com/player/v1/1',
      'https://www.tiktok.com:8443',
      'https://example.com',
      'javascript:alert(1)',
    ];
    for (final origin in notOfficial) {
      expect(
        EmbedWarmup.isOfficialTikTokOrigin(origin),
        isFalse,
        reason: origin,
      );
    }
  });
}
