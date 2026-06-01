import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'reel_dto.freezed.dart';
part 'reel_dto.g.dart';

/// DTO for a reel returned by `/v1/reels/feed`.
/// JSON (de)serialization lives here; [toDomain] maps to the pure-Dart entity.
@freezed
abstract class ReelDto with _$ReelDto {
  const factory ReelDto({
    required String id,
    required String sourceUrl,
    required String thumbnailUrl,
    required String creatorId,
    required String creatorName,
    required String creatorAvatarUrl,
    required String caption,
    required DateTime createdAt,
    @Default('') String musicTitle,
    @Default('') String musicArtist,
    @Default(<TaggedProductDto>[]) List<TaggedProductDto> taggedProducts,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @Default(0) int shareCount,
    bool? isLikedByUser,
    bool? isWishlistedByUser,
    bool? isCreatorFollowed,
  }) = _ReelDto;

  const ReelDto._();

  factory ReelDto.fromJson(Map<String, dynamic> json) =>
      _$ReelDtoFromJson(json);

  Reel toDomain() => Reel(
    id: id,
    sourceUrl: sourceUrl,
    thumbnailUrl: thumbnailUrl,
    creatorId: creatorId,
    creatorName: creatorName,
    creatorAvatarUrl: creatorAvatarUrl,
    caption: caption,
    musicTitle: musicTitle,
    musicArtist: musicArtist,
    taggedProducts: taggedProducts
        .map((dto) => dto.toDomain())
        .toList(growable: false),
    likeCount: likeCount,
    commentCount: commentCount,
    shareCount: shareCount,
    isLikedByUser: isLikedByUser,
    isWishlistedByUser: isWishlistedByUser,
    isCreatorFollowed: isCreatorFollowed,
    createdAt: createdAt,
  );
}

/// DTO for a product tagged on a reel.
@freezed
abstract class TaggedProductDto with _$TaggedProductDto {
  const factory TaggedProductDto({
    required String id,
    required String name,
    required String imageUrl,
    required double amount,
    @Default('NPR') String currency,
    @Default(1) int quantity,
  }) = _TaggedProductDto;

  const TaggedProductDto._();

  factory TaggedProductDto.fromJson(Map<String, dynamic> json) =>
      _$TaggedProductDtoFromJson(json);

  TaggedProductEntity toDomain() => TaggedProductEntity(
    id: id,
    name: name,
    imageUrl: imageUrl,
    price: Money(amount: amount, currency: currency),
    quantity: quantity,
  );
}
