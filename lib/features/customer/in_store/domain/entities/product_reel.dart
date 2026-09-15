import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/playback/platform_video_id.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_media.dart';

/// A published reel that tags a product. A pointer record: StyleMint never
/// hosts the video, and the reel opens in StyleMint's own reel screen.
class ProductReel implements ReelMedia {
  const ProductReel({
    required this.id,
    required this.permalink,
    this.thumbnailUrl,
    this.videoUrl,
    this.platform,
    this.externalId,
    this.creatorName = '',
    this.caption = '',
    this.likeCount = 0,
  });

  final String id;

  @override
  final String permalink;

  @override
  final String? thumbnailUrl;

  @override
  final String? videoUrl;

  @override
  final SocialPlatform? platform;

  /// The platform's own post id, when the backend stored one.
  final String? externalId;
  final String creatorName;
  final String caption;
  final int likeCount;

  @override
  String? get platformVideoId {
    final stored = externalId;
    if (stored != null && stored.isNotEmpty) return stored;
    return parsePlatformVideoId(platform, permalink);
  }
}
