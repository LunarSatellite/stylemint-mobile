import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/entities/story.dart';

part 'story_dto.freezed.dart';
part 'story_dto.g.dart';

@freezed
abstract class StoryDto with _$StoryDto {
  const factory StoryDto({
    required String id,
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required String mediaUrl,
    required String mediaType,
    required DateTime expiresAt,
    @Default(<String>[]) List<String> taggedProductIds,
    String? caption,
    @Default(0) int viewCount,
    @Default(false) bool hasWatched,
  }) = _StoryDto;

  const StoryDto._();

  factory StoryDto.fromJson(Map<String, dynamic> json) =>
      _$StoryDtoFromJson(json);

  Story toDomain() => Story(
    id: id,
    userId: userId,
    userName: userName,
    userAvatarUrl: userAvatarUrl,
    mediaUrl: mediaUrl,
    mediaType: mediaType,
    caption: caption,
    taggedProductIds: taggedProductIds,
    expiresAt: expiresAt,
    viewCount: viewCount,
    hasWatched: hasWatched,
  );
}

@freezed
abstract class StoryGroupDto with _$StoryGroupDto {
  const factory StoryGroupDto({
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required List<StoryDto> stories,
    @Default(false) bool hasUnwatched,
  }) = _StoryGroupDto;

  const StoryGroupDto._();

  factory StoryGroupDto.fromJson(Map<String, dynamic> json) =>
      _$StoryGroupDtoFromJson(json);

  StoryGroup toDomain() => StoryGroup(
    userId: userId,
    userName: userName,
    userAvatarUrl: userAvatarUrl,
    stories: stories.map((dto) => dto.toDomain()).toList(growable: false),
    hasUnwatched: hasUnwatched,
  );
}
