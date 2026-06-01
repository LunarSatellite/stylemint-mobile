import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/domain/entities/matchmaking.dart';

part 'matchmaking_dto.freezed.dart';
part 'matchmaking_dto.g.dart';

@freezed
abstract class MatchRecommendationDto with _$MatchRecommendationDto {
  const factory MatchRecommendationDto({
    required String creatorId,
    required String creatorName,
    required String avatarUrl,
    required String handle,
    required String category,
    @Default(0) int followersCount,
    @Default(0) int compatibilityScore,
    @Default([]) List<String> reasons,
    String? sampleReelThumbnail,
  }) = _MatchRecommendationDto;

  const MatchRecommendationDto._();

  factory MatchRecommendationDto.fromJson(Map<String, dynamic> json) =>
      _$MatchRecommendationDtoFromJson(json);

  MatchRecommendation toDomain() => MatchRecommendation(
    creatorId: creatorId,
    creatorName: creatorName,
    avatarUrl: avatarUrl,
    handle: handle,
    category: category,
    followersCount: followersCount,
    compatibilityScore: compatibilityScore,
    reasons: reasons,
    sampleReelThumbnail: sampleReelThumbnail,
  );
}

@freezed
abstract class MatchmakingFilterDto with _$MatchmakingFilterDto {
  const factory MatchmakingFilterDto({
    List<String>? categories,
    int? minFollowers,
    int? maxFollowers,
    double? minEngagementRate,
    double? budgetRange,
  }) = _MatchmakingFilterDto;

  const MatchmakingFilterDto._();

  factory MatchmakingFilterDto.fromJson(Map<String, dynamic> json) =>
      _$MatchmakingFilterDtoFromJson(json);

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (categories != null && categories!.isNotEmpty) {
      params['categories'] = categories!.join(',');
    }
    if (minFollowers != null) params['minFollowers'] = minFollowers;
    if (maxFollowers != null) params['maxFollowers'] = maxFollowers;
    if (minEngagementRate != null) params['minEngagementRate'] = minEngagementRate;
    if (budgetRange != null) params['budgetRange'] = budgetRange;
    return params;
  }
}
