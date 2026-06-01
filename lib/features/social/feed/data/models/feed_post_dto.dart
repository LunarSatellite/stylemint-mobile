import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/feed_post.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'feed_post_dto.freezed.dart';
part 'feed_post_dto.g.dart';

@freezed
abstract class FeedPostDto with _$FeedPostDto {
  const factory FeedPostDto({
    required String id,
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required String content,
    required DateTime createdAt,
    @Default(<String>[]) List<String> images,
    @Default(<FeedTaggedProductDto>[]) List<FeedTaggedProductDto> taggedProducts,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @Default(0) int shareCount,
    @Default(false) bool isLiked,
  }) = _FeedPostDto;

  const FeedPostDto._();

  factory FeedPostDto.fromJson(Map<String, dynamic> json) =>
      _$FeedPostDtoFromJson(json);

  FeedPost toDomain() => FeedPost(
    id: id,
    userId: userId,
    userName: userName,
    userAvatarUrl: userAvatarUrl,
    content: content,
    images: images,
    taggedProducts:
        taggedProducts.map((dto) => dto.toDomain()).toList(growable: false),
    likeCount: likeCount,
    commentCount: commentCount,
    shareCount: shareCount,
    isLiked: isLiked,
    createdAt: createdAt,
  );
}

@freezed
abstract class FeedTaggedProductDto with _$FeedTaggedProductDto {
  const factory FeedTaggedProductDto({
    required String productId,
    required String productName,
    required String imageUrl,
    required double amount,
    @Default('NPR') String currency,
  }) = _FeedTaggedProductDto;

  const FeedTaggedProductDto._();

  factory FeedTaggedProductDto.fromJson(Map<String, dynamic> json) =>
      _$FeedTaggedProductDtoFromJson(json);

  FeedTaggedProduct toDomain() => FeedTaggedProduct(
    productId: productId,
    productName: productName,
    imageUrl: imageUrl,
    price: Money(amount: amount, currency: currency),
  );
}

@freezed
abstract class FeedCommentDto with _$FeedCommentDto {
  const factory FeedCommentDto({
    required String id,
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required String content,
    required DateTime createdAt,
  }) = _FeedCommentDto;

  const FeedCommentDto._();

  factory FeedCommentDto.fromJson(Map<String, dynamic> json) =>
      _$FeedCommentDtoFromJson(json);

  FeedComment toDomain() => FeedComment(
    id: id,
    userId: userId,
    userName: userName,
    userAvatarUrl: userAvatarUrl,
    content: content,
    createdAt: createdAt,
  );
}
