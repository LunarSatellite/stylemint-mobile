import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class ImportableReel {
  const ImportableReel({
    required this.id,
    required this.platform,
    required this.platformPostId,
    required this.sourceUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.createdAt,
    required this.videoDuration,
    this.isSelected = false,
  });

  final String id;
  final SocialPlatform platform;
  final String platformPostId;
  final String sourceUrl;
  final String thumbnailUrl;
  final String caption;
  final DateTime createdAt;
  final int videoDuration;
  final bool isSelected;

  ImportableReel copyWith({
    String? id,
    SocialPlatform? platform,
    String? platformPostId,
    String? sourceUrl,
    String? thumbnailUrl,
    String? caption,
    DateTime? createdAt,
    int? videoDuration,
    bool? isSelected,
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
      isSelected: isSelected ?? this.isSelected,
    );
  }
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
      platform: platform ?? this.platform,
      platformPostId: platformPostId ?? this.platformPostId,
    );
  }
}
