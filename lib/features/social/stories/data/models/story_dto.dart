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

  factory StoryDto.fromStoryJson(Map<String, dynamic> json) {
    final rawMediaType = json['mediaType'];
    final mediaTypeText = rawMediaType.toString().toLowerCase();
    final isVideo =
        rawMediaType == 2 ||
        mediaTypeText == 'video' ||
        mediaTypeText == 'boomerang';
    final rawProductIds = json['taggedProductIds'];
    final productIds = rawProductIds is List
        ? rawProductIds.map((id) => id.toString()).toList(growable: false)
        : const <String>[];

    return StoryDto(
      id: json['id'].toString(),
      userId: (json['userId'] ?? json['authorAccountId']).toString(),
      userName:
          (json['userName'] ?? json['authorDisplayName'] ?? 'StyleMint user')
              .toString(),
      userAvatarUrl: (json['userAvatarUrl'] ?? json['authorAvatarUrl'] ?? '')
          .toString(),
      mediaUrl: json['mediaUrl'].toString(),
      mediaType: isVideo ? 'video' : 'image',
      expiresAt: DateTime.parse(
        (json['expiresAt'] ?? json['expiresUtc']).toString(),
      ),
      taggedProductIds: productIds,
      caption: json['caption'] as String?,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      hasWatched: json['hasWatched'] as bool? ?? false,
    );
  }

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
