import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/creator_profile.dart';

part 'creator_profile_dto.freezed.dart';
part 'creator_profile_dto.g.dart';

@freezed
abstract class CreatorProfileDto with _$CreatorProfileDto {
  const factory CreatorProfileDto({
    required String id,
    @Default('') String displayName,
    @Default('') String handle,
    String? avatarUrl,
    @Default('') String bio,
    @Default([]) List<String> tags,
    @Default([]) List<String> niches,
    @Default(0) int followersCount,
    @Default(0) int partnershipsCount,
    @Default(0) int reelsCount,
    @Default(0) int likesCount,
    @Default('') String rowVersion,
  }) = _CreatorProfileDto;

  const CreatorProfileDto._();

  factory CreatorProfileDto.fromJson(Map<String, dynamic> json) =>
      _$CreatorProfileDtoFromJson(json);

  CreatorProfile toDomain() => CreatorProfile(
        id: id,
        displayName: displayName,
        handle: handle,
        bio: bio,
        tags: List<String>.unmodifiable(tags),
        niches: List<String>.unmodifiable(niches),
        followersCount: followersCount,
        partnershipsCount: partnershipsCount,
        reelsCount: reelsCount,
        likesCount: likesCount,
        rowVersion: rowVersion,
        avatarUrl: avatarUrl,
      );
}
