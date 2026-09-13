import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/playback/platform_video_id.dart';

void main() {
  group('YouTube', () {
    const p = SocialPlatform.youtube;

    test('reads Shorts, watch, youtu.be and mobile links', () {
      expect(parsePlatformVideoId(p, 'https://www.youtube.com/shorts/39bix0Z0NOQ'), '39bix0Z0NOQ');
      expect(parsePlatformVideoId(p, 'https://www.youtube.com/watch?v=aoP2qlRrsmY&t=3'), 'aoP2qlRrsmY');
      expect(parsePlatformVideoId(p, 'https://youtu.be/jSE44kkEVs8'), 'jSE44kkEVs8');
      expect(parsePlatformVideoId(p, 'https://m.youtube.com/shorts/I1bYtU4F2AQ'), 'I1bYtU4F2AQ');
    });

    test('rejects other hosts and unsafe ids', () {
      expect(parsePlatformVideoId(p, 'https://evil.example/shorts/39bix0Z0NOQ'), isNull);
      expect(parsePlatformVideoId(p, 'https://notyoutube.com/watch?v=abc'), isNull);
      expect(parsePlatformVideoId(p, 'https://www.youtube.com/watch?v=a"b'), isNull);
    });
  });

  test('TikTok reads the numeric video id', () {
    expect(
      parsePlatformVideoId(SocialPlatform.tiktok, 'https://www.tiktok.com/@maker/video/6718335390845095173?lang=en'),
      '6718335390845095173',
    );
    expect(parsePlatformVideoId(SocialPlatform.tiktok, 'https://www.tiktok.com/@maker'), isNull);
  });

  test('Facebook reads reel, watch and page video links', () {
    const p = SocialPlatform.facebook;
    expect(parsePlatformVideoId(p, 'https://www.facebook.com/reel/1234567890'), '1234567890');
    expect(parsePlatformVideoId(p, 'https://www.facebook.com/watch/?v=987654321'), '987654321');
    expect(parsePlatformVideoId(p, 'https://www.facebook.com/facebook/videos/10153231379946729/'), '10153231379946729');
    expect(parsePlatformVideoId(p, 'https://fb.watch/abcDEF123/'), 'abcDEF123');
  });

  test('Instagram and unknown platforms have no embeddable id', () {
    expect(parsePlatformVideoId(SocialPlatform.instagram, 'https://www.instagram.com/reel/Cxyz/'), isNull);
    expect(parsePlatformVideoId(null, 'https://www.youtube.com/shorts/39bix0Z0NOQ'), isNull);
  });
}
