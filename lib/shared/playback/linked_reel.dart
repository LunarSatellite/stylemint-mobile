import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/playback/platform_video_id.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_resolver.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_source.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_media.dart';

/// A reel known only by its platform link, such as a product's reel review.
class LinkedReel implements ReelMedia {
  const LinkedReel({required this.platform, required this.permalink});

  @override
  final SocialPlatform platform;

  @override
  final String permalink;

  @override
  String? get platformVideoId => parsePlatformVideoId(platform, permalink);

  @override
  String? get videoUrl => null;

  @override
  String? get thumbnailUrl => null;

  /// The reel at [url] when StyleMint can play it in the platform's official
  /// embedded player; null otherwise.
  ///
  /// [platform] is the backend's platform value in any wire shape
  /// ([SocialPlatform.tryParseWire]); when it is missing or unrecognised the
  /// platform is read from the link's host.
  static LinkedReel? playable({required String? url, Object? platform}) {
    final link = url?.trim() ?? '';
    if (link.isEmpty) return null;
    final resolved =
        SocialPlatform.tryParseWire(platform) ?? platformOfLink(link);
    if (resolved == null) return null;
    final reel = LinkedReel(platform: resolved, permalink: link);
    return resolveReelPlayback(reel) is EmbedSource ? reel : null;
  }

  /// The platform a post link belongs to, by its host.
  static SocialPlatform? platformOfLink(String link) {
    final host = Uri.tryParse(link.trim())?.host.toLowerCase() ?? '';
    bool on(String domain) => host == domain || host.endsWith('.$domain');
    if (on('youtube.com') || host == 'youtu.be') return SocialPlatform.youtube;
    if (on('tiktok.com')) return SocialPlatform.tiktok;
    if (on('facebook.com') || host == 'fb.watch') {
      return SocialPlatform.facebook;
    }
    if (on('instagram.com')) return SocialPlatform.instagram;
    return null;
  }
}
