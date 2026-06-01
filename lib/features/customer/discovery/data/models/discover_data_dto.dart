import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'discover_data_dto.freezed.dart';
part 'discover_data_dto.g.dart';

/// DTO for the Discover landing payload from `/v1/discover`.
@freezed
abstract class DiscoverDataDto with _$DiscoverDataDto {
  const factory DiscoverDataDto({
    @Default(<String>[]) List<String> popularSearches,
    @Default(<DiscoverCategoryDto>[]) List<DiscoverCategoryDto> categories,
    @Default(<TrendingProductDto>[]) List<TrendingProductDto> trending,
    @Default(<DiscoverCreatorDto>[]) List<DiscoverCreatorDto> topCreators,
  }) = _DiscoverDataDto;

  const DiscoverDataDto._();

  factory DiscoverDataDto.fromJson(Map<String, dynamic> json) =>
      _$DiscoverDataDtoFromJson(json);

  DiscoverData toDomain() => DiscoverData(
    popularSearches: popularSearches,
    categories: categories.map((e) => e.toDomain()).toList(growable: false),
    trending: trending.map((e) => e.toDomain()).toList(growable: false),
    topCreators: topCreators.map((e) => e.toDomain()).toList(growable: false),
  );
}

@freezed
abstract class DiscoverCategoryDto with _$DiscoverCategoryDto {
  const factory DiscoverCategoryDto({
    required String id,
    required String label,
    @Default('') String emoji,
  }) = _DiscoverCategoryDto;

  const DiscoverCategoryDto._();

  factory DiscoverCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$DiscoverCategoryDtoFromJson(json);

  DiscoverCategory toDomain() =>
      DiscoverCategory(id: id, label: label, emoji: emoji);
}

@freezed
abstract class TrendingProductDto with _$TrendingProductDto {
  const factory TrendingProductDto({
    required String id,
    required String name,
    required double amount,
    @Default('NPR') String currency,
    @Default('') String imageUrl,
    @Default(0) double rating,
    @Default(0) int soldToday,
  }) = _TrendingProductDto;

  const TrendingProductDto._();

  factory TrendingProductDto.fromJson(Map<String, dynamic> json) =>
      _$TrendingProductDtoFromJson(json);

  TrendingProduct toDomain() => TrendingProduct(
    id: id,
    name: name,
    imageUrl: imageUrl,
    price: Money(amount: amount, currency: currency),
    rating: rating,
    soldToday: soldToday,
  );
}

@freezed
abstract class DiscoverCreatorDto with _$DiscoverCreatorDto {
  const factory DiscoverCreatorDto({
    required String id,
    required String name,
    required String handle,
    @Default('') String avatarUrl,
    @Default('') String category,
    @Default('') String description,
    @Default(0) double rating,
    @Default(0) int followers,
    @Default(false) bool isFollowing,
  }) = _DiscoverCreatorDto;

  const DiscoverCreatorDto._();

  factory DiscoverCreatorDto.fromJson(Map<String, dynamic> json) =>
      _$DiscoverCreatorDtoFromJson(json);

  DiscoverCreator toDomain() => DiscoverCreator(
    id: id,
    name: name,
    handle: handle,
    avatarUrl: avatarUrl,
    category: category,
    description: description,
    rating: rating,
    followers: followers,
    isFollowing: isFollowing,
  );
}
