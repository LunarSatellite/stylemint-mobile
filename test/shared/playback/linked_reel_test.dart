import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/playback/linked_reel.dart';

void main() {
  test('a YouTube review link plays in the embedded player', () {
    final reel = LinkedReel.playable(
      url: 'https://youtube.com/shorts/39bix0Z0NOQ?feature=shared',
      platform: '3',
    );

    expect(reel?.platform, SocialPlatform.youtube);
    expect(reel?.platformVideoId, '39bix0Z0NOQ');
  });

  test('reads the backend platform in any wire shape', () {
    const tiktok =
        'https://www.tiktok.com/@scout2015/video/6718335390845095173';

    expect(
      LinkedReel.playable(url: tiktok, platform: 2)?.platform,
      SocialPlatform.tiktok,
    );
    expect(
      LinkedReel.playable(url: tiktok, platform: 'TikTok')?.platform,
      SocialPlatform.tiktok,
    );
    expect(
      LinkedReel.playable(
        url: 'https://www.youtube.com/watch?v=I1bYtU4F2AQ',
        platform: 'YouTubeShorts',
      )?.platformVideoId,
      'I1bYtU4F2AQ',
    );
  });

  test('falls back to the link host when the platform is missing', () {
    final reel = LinkedReel.playable(
      url: 'https://www.facebook.com/watch/?v=10153231379946729',
    );

    expect(reel?.platform, SocialPlatform.facebook);
  });

  test('is null when the reel cannot play in StyleMint', () {
    expect(
      LinkedReel.playable(
        url: 'https://www.instagram.com/reel/C8abc/',
        platform: '1',
      ),
      isNull,
    );
    expect(
      LinkedReel.playable(url: 'https://vm.tiktok.com/ZMabc/', platform: '2'),
      isNull,
    );
    expect(
      LinkedReel.playable(
        url: 'https://www.youtube.com/@stylemint',
        platform: '3',
      ),
      isNull,
    );
    // The platform and the link disagree.
    expect(
      LinkedReel.playable(
        url: 'https://youtube.com/shorts/39bix0Z0NOQ',
        platform: 'TikTok',
      ),
      isNull,
    );
    expect(LinkedReel.playable(url: null, platform: '3'), isNull);
    expect(LinkedReel.playable(url: '   '), isNull);
    expect(LinkedReel.playable(url: 'https://example.com/v/1'), isNull);
  });
}
