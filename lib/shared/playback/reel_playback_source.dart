import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

/// How a reel is played. Decided once per reel by `resolveReelPlayback`.
sealed class ReelPlaybackSource {
  const ReelPlaybackSource();
}

/// A directly playable media URL returned by an official platform API
/// (e.g. Instagram `media_url`). Played with the native video engine.
final class NativeVideoSource extends ReelPlaybackSource {
  const NativeVideoSource({required this.url, required this.cacheKey});

  final String url;

  /// Stable disk-cache key. The permalink, not [url]: CDN URLs rotate.
  final String cacheKey;
}

/// The platform's official embedded player (YouTube IFrame API, TikTok Embed
/// Player, Facebook Embedded Video Player).
final class EmbedSource extends ReelPlaybackSource {
  const EmbedSource({
    required this.platform,
    required this.externalId,
    required this.permalink,
  });

  final SocialPlatform platform;

  /// The platform's own video id (YouTube videoId, TikTok item id, ...).
  final String externalId;

  /// Canonical post URL. The Facebook player embeds by URL.
  final String permalink;
}

/// No inline playback is possible: show the poster with a "can't play here"
/// note. The platform's app or site is never opened.
final class ExternalOnlySource extends ReelPlaybackSource {
  const ExternalOnlySource({required this.permalink});

  final String permalink;
}
