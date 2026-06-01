import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'imported_reel_dto.freezed.dart';
part 'imported_reel_dto.g.dart';

@freezed
abstract class ImportableReelDto with _$ImportableReelDto {
  const factory ImportableReelDto({
    required String id,
    required String platform,
    required String platformPostId,
    required String sourceUrl,
    required String thumbnailUrl,
    required String caption,
    required DateTime createdAt,
    @Default(0) int videoDuration,
    @Default(false) bool isSelected,
  }) = _ImportableReelDto;

  const ImportableReelDto._();

  factory ImportableReelDto.fromJson(Map<String, dynamic> json) =>
      _$ImportableReelDtoFromJson(json);

  ImportableReel toDomain() {
    final platformEnum = SocialPlatform.values.firstWhere(
      (p) => p.name == platform,
      orElse: () => SocialPlatform.instagram,
    );

    return ImportableReel(
      id: id,
      platform: platformEnum,
      platformPostId: platformPostId,
      sourceUrl: sourceUrl,
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      createdAt: createdAt,
      videoDuration: videoDuration,
      isSelected: isSelected,
    );
  }
}

@freezed
abstract class TaggedProductForImportDto with _$TaggedProductForImportDto {
  const factory TaggedProductForImportDto({
    required String productId,
    required String productName,
    required String imageUrl,
    required double amount,
    @Default('NPR') String currency,
    required String vendorName,
  }) = _TaggedProductForImportDto;

  const TaggedProductForImportDto._();

  factory TaggedProductForImportDto.fromJson(Map<String, dynamic> json) =>
      _$TaggedProductForImportDtoFromJson(json);

  TaggedProductForImport toDomain() => TaggedProductForImport(
        productId: productId,
        productName: productName,
        imageUrl: imageUrl,
        price: Money(amount: amount, currency: currency),
        vendorName: vendorName,
      );
}

@freezed
abstract class ImportedReelDto with _$ImportedReelDto {
  const factory ImportedReelDto({
    required String id,
    required String status,
    required String reelReelId,
    @Default(<TaggedProductForImportDto>[]) List<TaggedProductForImportDto> tags,
    required DateTime importedAt,
    required String caption,
    required String thumbnailUrl,
    required String platform,
    required String platformPostId,
  }) = _ImportedReelDto;

  const ImportedReelDto._();

  factory ImportedReelDto.fromJson(Map<String, dynamic> json) =>
      _$ImportedReelDtoFromJson(json);

  ImportedReel toDomain() {
    final platformEnum = SocialPlatform.values.firstWhere(
      (p) => p.name == platform,
      orElse: () => SocialPlatform.instagram,
    );

    final statusEnum = ImportStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => ImportStatus.pending,
    );

    return ImportedReel(
      id: id,
      status: statusEnum,
      reelReelId: reelReelId,
      tags: tags.map((dto) => dto.toDomain()).toList(growable: false),
      importedAt: importedAt,
      caption: caption,
      thumbnailUrl: thumbnailUrl,
      platform: platformEnum,
      platformPostId: platformPostId,
    );
  }
}
