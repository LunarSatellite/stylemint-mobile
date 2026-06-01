import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

part 'reel_studio_dto.freezed.dart';
part 'reel_studio_dto.g.dart';

@freezed
abstract class FeedbackAreaDto with _$FeedbackAreaDto {
  const factory FeedbackAreaDto({
    required String label,
    required double score,
  }) = _FeedbackAreaDto;

  const FeedbackAreaDto._();

  factory FeedbackAreaDto.fromJson(Map<String, dynamic> json) =>
      _$FeedbackAreaDtoFromJson(json);

  FeedbackArea toDomain() => FeedbackArea(label: label, score: score);
}

@freezed
abstract class CoachingFeedbackDto with _$CoachingFeedbackDto {
  const factory CoachingFeedbackDto({
    required double overallScore,
    @Default(<FeedbackAreaDto>[]) List<FeedbackAreaDto> areas,
    @Default(<String>[]) List<String> suggestions,
    required DateTime generatedAt,
  }) = _CoachingFeedbackDto;

  const CoachingFeedbackDto._();

  factory CoachingFeedbackDto.fromJson(Map<String, dynamic> json) =>
      _$CoachingFeedbackDtoFromJson(json);

  CoachingFeedback toDomain() => CoachingFeedback(
    overallScore: overallScore,
    areas: areas.map((a) => a.toDomain()).toList(growable: false),
    suggestions: suggestions,
    generatedAt: generatedAt,
  );
}

@freezed
abstract class ReelRecipeDto with _$ReelRecipeDto {
  const factory ReelRecipeDto({
    required String id,
    required String title,
    required String description,
    @Default(<String>[]) List<String> hashtags,
    @Default('') String suggestedMusic,
    required String platform,
  }) = _ReelRecipeDto;

  const ReelRecipeDto._();

  factory ReelRecipeDto.fromJson(Map<String, dynamic> json) =>
      _$ReelRecipeDtoFromJson(json);

  ReelRecipe toDomain() {
    final platformEnum = SocialPlatform.values.firstWhere(
      (p) => p.name == platform,
      orElse: () => SocialPlatform.instagram,
    );
    return ReelRecipe(
      id: id,
      title: title,
      description: description,
      hashtags: hashtags,
      suggestedMusic: suggestedMusic,
      platform: platformEnum,
    );
  }
}

@freezed
abstract class ReelDraftDto with _$ReelDraftDto {
  const factory ReelDraftDto({
    required String id,
    required String caption,
    @Default(<String>[]) List<String> hashtags,
    @Default(<String>[]) List<String> taggedProductIds,
    required String platform,
    required String status,
    CoachingFeedbackDto? coaching,
    required DateTime createdAt,
  }) = _ReelDraftDto;

  const ReelDraftDto._();

  factory ReelDraftDto.fromJson(Map<String, dynamic> json) =>
      _$ReelDraftDtoFromJson(json);

  ReelDraft toDomain() {
    final platformEnum = SocialPlatform.values.firstWhere(
      (p) => p.name == platform,
      orElse: () => SocialPlatform.instagram,
    );
    final statusEnum = ReelDraftStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => ReelDraftStatus.draft,
    );
    return ReelDraft(
      id: id,
      caption: caption,
      hashtags: hashtags,
      taggedProductIds: taggedProductIds,
      platform: platformEnum,
      status: statusEnum,
      coaching: coaching?.toDomain(),
      createdAt: createdAt,
    );
  }
}
