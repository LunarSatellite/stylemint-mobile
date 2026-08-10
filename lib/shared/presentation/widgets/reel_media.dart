import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

/// Common media view for the various reel types in the app (customer feed
/// reel, creator importable reel). The [ReelPlayer] only cares about these
/// five fields; everything else (creator info, tagged products, etc.) lives
/// on the source entity. Implement this on any reel-shaped entity you want
/// to play through [ReelPlayer].
///
/// Why a contract, not a value class:
/// - the customer `Reel` and the creator `ImportableReel` are different
///   domain types with different surrounding data; the player only needs the
///   playback-relevant fields, so we extract them behind a shared interface
///   instead of forcing both sides through a single normalised model.
/// - one place to add a new platform (e.g. when Meta ships a usable embed,
///   only the player and the importable reel need a new branch).
abstract class ReelMedia {
  /// Source platform (Instagram / YouTube / TikTok / Facebook).
  SocialPlatform? get platform;

  /// Platform-specific video ID (e.g. YouTube `videoId`, Instagram shortcode).
  /// Null when the platform is unknown or the ID cannot be parsed.
  String? get platformVideoId;

  /// Direct playable URL (mp4 / m3u8). Null when the platform does not expose
  /// one (e.g. YouTube). Used when there is a native player for the platform.
  String? get videoUrl;

  /// Preview image to show before/while the video loads. Nullable
  /// because some backend responses (notably the creator's published
  /// reel detail) don't carry a thumbnail until the platform sync ran.
  String? get thumbnailUrl;

  /// Full URL to open in the native app when the platform does not have an
  /// in-app player (e.g. TikTok / Facebook).
  String get permalink;
}
