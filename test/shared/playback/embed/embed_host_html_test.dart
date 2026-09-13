import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_host_html.dart';

void main() {
  final html = embedHostHtml(
    origin: 'https://app.stylemint.stylemint_mobile_frontend',
  );

  test('identifies the app to YouTube and keeps playback inline', () {
    expect(
      html,
      contains('var ORIGIN = "https://app.stylemint.stylemint_mobile_frontend";'),
    );
    expect(html, contains('origin: ORIGIN'));
    expect(html, contains('widget_referrer: ORIGIN'));
    expect(html, contains('playsinline: 1'));
    expect(html, contains('controls: 0'));
    expect(html, contains('https://www.youtube.com/iframe_api'));
  });

  test('never hides, restyles or scripts inside a platform player', () {
    const banned = [
      'youtube-nocookie',
      '.ytp-',
      'contentDocument',
      'MutationObserver',
      'display:none',
      'visibility:hidden',
    ];
    for (final pattern in banned) {
      expect(html, isNot(contains(pattern)), reason: pattern);
    }
  });

  test('uses the official TikTok and Facebook players', () {
    expect(html, contains('https://www.tiktok.com/player/v1/'));
    expect(html, contains("'x-tiktok-player': true"));
    expect(html, contains('https://connect.facebook.net/en_US/sdk.js'));
    expect(html, contains("video.className = 'fb-video'"));
  });

  test('embeds the origin as an escaped JavaScript string', () {
    expect(embedHostHtml(origin: 'https://a"b'), contains(r'"https://a\"b"'));
  });
}
