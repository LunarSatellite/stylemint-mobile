import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/domain/entities/recommendation.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'recommendation_dto.freezed.dart';
part 'recommendation_dto.g.dart';

@freezed
abstract class RecommendationTaggedProductDto
    with _$RecommendationTaggedProductDto {
  const factory RecommendationTaggedProductDto({
    required String productId,
    required String productName,
    required String imageUrl,
    required double amount,
    @Default('NPR') String currency,
  }) = _RecommendationTaggedProductDto;

  const RecommendationTaggedProductDto._();

  factory RecommendationTaggedProductDto.fromJson(Map<String, dynamic> json) =>
      _$RecommendationTaggedProductDtoFromJson(json);

  RecommendationTaggedProduct toDomain() => RecommendationTaggedProduct(
    productId: productId,
    productName: productName,
    imageUrl: imageUrl,
    price: Money(amount: amount, currency: currency),
  );
}

@freezed
abstract class RecommendationRequestDto with _$RecommendationRequestDto {
  const factory RecommendationRequestDto({
    required String id,
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required String question,
    String? context,
    @Default(<String>[]) List<String> taggedCategories,
    @Default(<RecommendationTaggedProductDto>[])
    List<RecommendationTaggedProductDto> taggedProducts,
    @Default(0) int replyCount,
    required DateTime createdAt,
    DateTime? expiresAt,
  }) = _RecommendationRequestDto;

  const RecommendationRequestDto._();

  factory RecommendationRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RecommendationRequestDtoFromJson(json);

  factory RecommendationRequestDto.fromBackendJson(
    Map<String, dynamic> json,
  ) => RecommendationRequestDto(
    id: json['id'] as String,
    userId: json['askerAccountId'] as String,
    userName: (json['askerName'] as String?)?.trim().isNotEmpty == true
        ? json['askerName'] as String
        : 'StyleMint user',
    userAvatarUrl: json['askerAvatarUrl'] as String? ?? '',
    question: json['title'] as String,
    context: json['body'] as String?,
    replyCount: json['replyCount'] as int? ?? 0,
    createdAt: DateTime.parse(
      (json['openedUtc'] ?? json['createdUtc']) as String,
    ),
    expiresAt: json['expiresUtc'] == null
        ? null
        : DateTime.parse(json['expiresUtc'] as String),
  );

  RecommendationRequest toDomain() => RecommendationRequest(
    id: id,
    userId: userId,
    userName: userName,
    userAvatarUrl: userAvatarUrl,
    question: question,
    context: context,
    taggedCategories: taggedCategories,
    taggedProducts: taggedProducts
        .map((dto) => dto.toDomain())
        .toList(growable: false),
    replyCount: replyCount,
    createdAt: createdAt,
    expiresAt: expiresAt,
  );
}

@freezed
abstract class RecommendationReplyDto with _$RecommendationReplyDto {
  const factory RecommendationReplyDto({
    required String id,
    required String requestId,
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required String content,
    String? suggestedProduct,
    String? suggestedProductUrl,
    @Default(0) int likeCount,
    required DateTime createdAt,
  }) = _RecommendationReplyDto;

  const RecommendationReplyDto._();

  factory RecommendationReplyDto.fromJson(Map<String, dynamic> json) =>
      _$RecommendationReplyDtoFromJson(json);

  factory RecommendationReplyDto.fromBackendJson(Map<String, dynamic> json) =>
      RecommendationReplyDto(
        id: json['id'] as String,
        requestId: json['requestId'] as String,
        userId: json['replierAccountId'] as String,
        userName: (json['replierName'] as String?)?.trim().isNotEmpty == true
            ? json['replierName'] as String
            : 'StyleMint user',
        userAvatarUrl: json['replierAvatarUrl'] as String? ?? '',
        content: json['body'] as String,
        likeCount: json['upvoteCount'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdUtc'] as String),
      );

  RecommendationReply toDomain() => RecommendationReply(
    id: id,
    requestId: requestId,
    userId: userId,
    userName: userName,
    userAvatarUrl: userAvatarUrl,
    content: content,
    suggestedProduct: suggestedProduct,
    suggestedProductUrl: suggestedProductUrl,
    likeCount: likeCount,
    createdAt: createdAt,
  );
}
