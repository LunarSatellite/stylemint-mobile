import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/domain/entities/creator_search_result.dart';

part 'creator_search_dto.freezed.dart';
part 'creator_search_dto.g.dart';

/// Wire models for `GET /api/v1/customer/search?type=brands|products|creators`.
///
/// The Discovery search endpoint returns one keyed list per `type` — `brands`,
/// `products` or `creators` — so each result kind gets its own DTO rather than
/// a single polymorphic envelope. Every field is defaulted because the search
/// projection omits keys it has no value for.
@freezed
abstract class SearchBrandResultDto with _$SearchBrandResultDto {
  const factory SearchBrandResultDto({
    @Default('') String brandId,
    @Default('') String name,
    String? logoUrl,
    @Default(0.0) double averageRating,
    @Default(0) int productCount,
    @Default('') String commissionRange,
  }) = _SearchBrandResultDto;

  const SearchBrandResultDto._();

  factory SearchBrandResultDto.fromJson(Map<String, dynamic> json) =>
      _$SearchBrandResultDtoFromJson(json);

  SearchBrandResult toDomain() => SearchBrandResult(
        brandId: brandId,
        name: name,
        logoUrl: logoUrl,
        averageRating: averageRating,
        productCount: productCount,
        commissionRange: commissionRange,
      );
}

@freezed
abstract class SearchProductResultDto with _$SearchProductResultDto {
  const factory SearchProductResultDto({
    @Default('') String productId,
    @Default('') String name,
    @Default('') String heroImageUrl,
    @Default(0.0) double price,
    @Default('NPR') String currency,
    @Default('') String brandId,
    @Default('') String brandName,
  }) = _SearchProductResultDto;

  const SearchProductResultDto._();

  factory SearchProductResultDto.fromJson(Map<String, dynamic> json) =>
      _$SearchProductResultDtoFromJson(json);

  SearchProductResult toDomain() => SearchProductResult(
        productId: productId,
        name: name,
        heroImageUrl: heroImageUrl,
        price: price,
        currency: currency,
        brandId: brandId,
        brandName: brandName,
      );
}

@freezed
abstract class SearchCreatorResultDto with _$SearchCreatorResultDto {
  const factory SearchCreatorResultDto({
    @Default('') String creatorProfileId,
    @Default('') String handle,
    @Default('') String displayName,
    String? avatarUrl,
    @Default(0) int followerCount,
    @Default(0) int reelCount,
  }) = _SearchCreatorResultDto;

  const SearchCreatorResultDto._();

  factory SearchCreatorResultDto.fromJson(Map<String, dynamic> json) =>
      _$SearchCreatorResultDtoFromJson(json);

  SearchCreatorResult toDomain() => SearchCreatorResult(
        creatorProfileId: creatorProfileId,
        handle: handle,
        displayName: displayName,
        avatarUrl: avatarUrl,
        followerCount: followerCount,
        reelCount: reelCount,
      );
}
