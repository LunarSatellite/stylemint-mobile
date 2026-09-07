import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_media.dart';

class ImportableReel implements ReelMedia {
  const ImportableReel({
    required this.id,
    required this.platform,
    required this.platformPostId,
    required this.sourceUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.createdAt,
    required this.videoDuration,
    this.videoUrl,
    this.isSelected = false,
    this.likeCount = 0,
    this.viewCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.bookmarkCount = 0,
  });

  final String id;
  final SocialPlatform platform;
  final String platformPostId;
  final String sourceUrl;
  final String thumbnailUrl;
  final String caption;
  final DateTime createdAt;
  final int videoDuration;

  /// Direct playable URL (mp4 / m3u8). Null when the platform does not
  /// expose one (e.g. Instagram). Use [ReelPlayer] which falls back to a
  /// thumbnail + tap-to-open in that case.
  final String? videoUrl;
  final bool isSelected;

  /// Platform-native stats (last sync). Default 0 — backend may populate these
  /// per provider when the reel is fetched.
  final int likeCount;
  final int viewCount;
  final int commentCount;
  final int shareCount;
  final int bookmarkCount;

  ImportableReel copyWith({
    String? id,
    SocialPlatform? platform,
    String? platformPostId,
    String? sourceUrl,
    String? thumbnailUrl,
    String? caption,
    DateTime? createdAt,
    int? videoDuration,
    String? videoUrl,
    bool? isSelected,
    int? likeCount,
    int? viewCount,
    int? commentCount,
    int? shareCount,
    int? bookmarkCount,
  }) {
    return ImportableReel(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      platformPostId: platformPostId ?? this.platformPostId,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      videoDuration: videoDuration ?? this.videoDuration,
      videoUrl: videoUrl ?? this.videoUrl,
      isSelected: isSelected ?? this.isSelected,
      likeCount: likeCount ?? this.likeCount,
      viewCount: viewCount ?? this.viewCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      bookmarkCount: bookmarkCount ?? this.bookmarkCount,
    );
  }

  /// Platform-specific video ID — for YouTube this is the 11-char video ID,
  /// for Instagram the shortcode, for TikTok / Facebook the post/video ID.
  @override
  String? get platformVideoId => platformPostId;

  /// Open URL for the platform's native app / web.
  @override
  String get permalink => sourceUrl;
}

class TaggedProductForImport {
  const TaggedProductForImport({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.vendorName,
  });

  final String productId;
  final String productName;
  final String imageUrl;
  final Money price;
  final String vendorName;
}

enum ImportStatus { pending, processing, live, flagged }

class ImportedReel {
  const ImportedReel({
    required this.id,
    required this.status,
    required this.reelReelId,
    required this.tags,
    required this.importedAt,
    required this.caption,
    required this.thumbnailUrl,
    required this.sourceUrl,
    required this.platform,
    required this.platformPostId,
  });

  final String id;
  final ImportStatus status;
  final String reelReelId;
  final List<TaggedProductForImport> tags;
  final DateTime importedAt;
  final String caption;
  final String thumbnailUrl;
  final String sourceUrl;
  final SocialPlatform platform;
  final String platformPostId;

  ImportedReel copyWith({
    String? id,
    ImportStatus? status,
    String? reelReelId,
    List<TaggedProductForImport>? tags,
    DateTime? importedAt,
    String? caption,
    String? thumbnailUrl,
    String? sourceUrl,
    SocialPlatform? platform,
    String? platformPostId,
  }) {
    return ImportedReel(
      id: id ?? this.id,
      status: status ?? this.status,
      reelReelId: reelReelId ?? this.reelReelId,
      tags: tags ?? this.tags,
      importedAt: importedAt ?? this.importedAt,
      caption: caption ?? this.caption,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      platform: platform ?? this.platform,
      platformPostId: platformPostId ?? this.platformPostId,
    );
  }
}
