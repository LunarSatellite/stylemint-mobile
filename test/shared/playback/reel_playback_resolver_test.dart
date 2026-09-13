import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_resolver.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_source.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_media.dart';

class _Reel implements ReelMedia {
  const _Reel({
    this.platform,
    this.platformVideoId,
    this.videoUrl,
    this.permalink = 'https://example.com/p/1',
  });

  @override
  final SocialPlatform? platform;
  @override
  final String? platformVideoId;
  @override
  final String? videoUrl;
  @override
  final String permalink;
  @override
  String? get thumbnailUrl => null;
}

void main() {
  test('Instagram with a media URL plays natively, cached by permalink', () {
    final source = resolveReelPlayback(const _Reel(
      platform: SocialPlatform.instagram,
      videoUrl: 'https://scontent.cdninstagram.com/v/reel.mp4',
      permalink: 'https://www.instagram.com/reel/abc/',
    ));

    expect(source, isA<NativeVideoSource>());
    source as NativeVideoSource;
    expect(source.url, 'https://scontent.cdninstagram.com/v/reel.mp4');
    expect(source.cacheKey, 'https://www.instagram.com/reel/abc/');
  });

  test('Instagram without a media URL falls back to external hand-off', () {
    final source = resolveReelPlayback(const _Reel(
      platform: SocialPlatform.instagram,
      platformVideoId: '1789',
    ));

    expect(source, isA<ExternalOnlySource>());
  });

  test('YouTube uses the official embed even when a video URL is present', () {
    final source = resolveReelPlayback(const _Reel(
      platform: SocialPlatform.youtube,
      platformVideoId: '39bix0Z0NOQ',
      videoUrl: 'https://rr1---sn.googlevideo.com/videoplayback?x=1',
    ));

    expect(source, isA<EmbedSource>());
    source as EmbedSource;
    expect(source.platform, SocialPlatform.youtube);
    expect(source.externalId, '39bix0Z0NOQ');
  });

  test('TikTok and Facebook use their official embeds', () {
    for (final platform in [SocialPlatform.tiktok, SocialPlatform.facebook]) {
      final source = resolveReelPlayback(_Reel(
        platform: platform,
        platformVideoId: '6718335390845095173',
        permalink: 'https://www.facebook.com/reel/1/',
      ));

      expect(source, isA<EmbedSource>(), reason: platform.name);
      source as EmbedSource;
      expect(source.permalink, 'https://www.facebook.com/reel/1/');
    }
  });

  test('an embed platform without an id falls back to external hand-off', () {
    final source = resolveReelPlayback(const _Reel(
      platform: SocialPlatform.youtube,
      permalink: 'https://youtube.com/shorts/',
    ));

    expect(source, isA<ExternalOnlySource>());
    expect((source as ExternalOnlySource).permalink, 'https://youtube.com/shorts/');
  });

  test('an unknown platform is treated as Instagram', () {
    final source = resolveReelPlayback(const _Reel(
      videoUrl: 'https://scontent.cdninstagram.com/v/reel.mp4',
    ));

    expect(source, isA<NativeVideoSource>());
  });
}
