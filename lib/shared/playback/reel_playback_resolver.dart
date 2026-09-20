import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_source.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_media.dart';

/// Picks the terms-compliant way to play [reel].
///
/// YouTube and TikTok always go through their official embedded players, even
/// when a stray [ReelMedia.videoUrl] is present: their terms forbid playing
/// extracted streams. Instagram plays natively only when the official API gave
/// a media URL (it omits one for reels with copyrighted audio).
ReelPlaybackSource resolveReelPlayback(ReelMedia reel) {
  final platform = reel.platform ?? SocialPlatform.instagram;
  final permalink = reel.permalink;

  switch (platform) {
    case SocialPlatform.instagram:
      final url = reel.videoUrl;
      if (url == null || url.isEmpty) {
        return ExternalOnlySource(permalink: permalink);
      }
      return NativeVideoSource(
        url: url,
        cacheKey: permalink.isNotEmpty ? permalink : url,
      );
    case SocialPlatform.youtube:
    case SocialPlatform.tiktok:
    case SocialPlatform.facebook:
      final id = reel.platformVideoId;
      if (id == null || id.isEmpty) {
        return ExternalOnlySource(permalink: permalink);
      }
      return EmbedSource(
        platform: platform,
        externalId: id,
        permalink: permalink,
      );
  }
}
