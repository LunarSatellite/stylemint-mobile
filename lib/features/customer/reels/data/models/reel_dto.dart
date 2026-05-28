import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import '../../domain/entities/reel.dart';

part 'reel_dto.freezed.dart';
part 'reel_dto.g.dart';

/// DTO for Reel - handles JSON serialization/deserialization
/// Converts between API responses and domain entities
@freezed
class ReelDTO with _$ReelDTO {
  const factory ReelDTO({
    required String id,
    required String sourceUrl,
    required String thumbnailUrl,
    required String creatorId,
    required String creatorName,
    required String creatorAvatarUrl,
    required String caption,
    required String musicTitle,
    required String musicArtist,
    @Default([]) List<TaggedProductDTO> taggedProducts,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @Default(0) int shareCount,
    @JsonKey(name: 'isLikedByUser') bool? isLikedByUser,
    @JsonKey(name: 'isWishlistedByUser') bool? isWishlistedByUser,
    @JsonKey(name: 'isCreatorFollowed') bool? isCreatorFollowed,
    required DateTime createdAt,
  }) = _ReelDTO;

  factory ReelDTO.fromJson(Map<String, dynamic> json) =>
      _$ReelDTOFromJson(json);

  const ReelDTO._();

  /// Converts DTO to domain entity
  Reel toDomain() {
    return Reel(
      id: id,
      sourceUrl: sourceUrl,
      thumbnailUrl: thumbnailUrl,
      creatorId: creatorId,
      creatorName: creatorName,
      creatorAvatarUrl: creatorAvatarUrl,
      caption: caption,
      musicTitle: musicTitle,
      musicArtist: musicArtist,
      taggedProducts: taggedProducts.map((dto) => dto.toDomain()).toList(),
      likeCount: likeCount,
      commentCount: commentCount,
      shareCount: shareCount,
      isLikedByUser: isLikedByUser,
      isWishlistedByUser: isWishlistedByUser,
      isCreatorFollowed: isCreatorFollowed,
      createdAt: createdAt,
    );
  }
}

/// DTO for tagged product
@freezed
class TaggedProductDTO with _$TaggedProductDTO {
  const factory TaggedProductDTO({
    required String id,
    required String name,
    required String imageUrl,
    required double amount,
    @Default('NPR') String currency,
    @Default(1) int quantity,
  }) = _TaggedProductDTO;

  factory TaggedProductDTO.fromJson(Map<String, dynamic> json) =>
      _$TaggedProductDTOFromJson(json);

  const TaggedProductDTO._();

  /// Converts DTO to domain entity
  TaggedProductEntity toDomain() {
    return TaggedProductEntity(
      id: id,
      name: name,
      imageUrl: imageUrl,
      price: Money(amount: amount, currency: currency),
      quantity: quantity,
    );
  }
}
