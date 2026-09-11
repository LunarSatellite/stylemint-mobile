import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/domain/entities/group.dart';

part 'group_dto.freezed.dart';
part 'group_dto.g.dart';

@freezed
abstract class StyleGroupDto with _$StyleGroupDto {
  const factory StyleGroupDto({
    required String id,
    required String name,
    @Default('') String description,
    String? coverImageUrl,
    required String categoryId,
    @JsonKey(fromJson: _enumName) required String privacy,
    @Default(0) int memberCount,
    bool? isMember,
    bool? isOwner,
    @JsonKey(fromJson: _nullableEnumName) String? myJoinRequestStatus,
    required DateTime createdUtc,
  }) = _StyleGroupDto;

  const StyleGroupDto._();

  factory StyleGroupDto.fromJson(Map<String, dynamic> json) =>
      _$StyleGroupDtoFromJson(json);

  StyleGroup toDomain() => StyleGroup(
    id: id,
    name: name,
    description: description,
    coverImageUrl: coverImageUrl ?? '',
    category: privacy,
    memberCount: memberCount,
    isJoined: isMember ?? isOwner ?? false,
    isPrivate: privacy.toLowerCase() != 'public',
    isProfessional: privacy.toLowerCase() == 'professional',
    isOwner: isOwner ?? false,
    hasPendingJoinRequest: myJoinRequestStatus?.toLowerCase() == 'pending',
    createdAt: createdUtc,
    topProducts: const [],
  );
}

@freezed
abstract class ProfessionalCircleDto with _$ProfessionalCircleDto {
  const factory ProfessionalCircleDto({
    required String id,
    required String groupId,
    required String professionCode,
    required String verifyingAuthority,
    @Default('') String description,
    @Default(false) bool requiresLicenseNumber,
    required DateTime createdUtc,
    required String groupName,
    @Default(0) int groupMemberCount,
    @JsonKey(fromJson: _enumName) required String groupPrivacy,
    required String groupCategoryId,
    String? groupCoverImageUrl,
  }) = _ProfessionalCircleDto;

  const ProfessionalCircleDto._();

  factory ProfessionalCircleDto.fromJson(Map<String, dynamic> json) =>
      _$ProfessionalCircleDtoFromJson(json);

  StyleGroup toDomain() => StyleGroup(
    id: groupId,
    name: groupName,
    description: description,
    coverImageUrl: groupCoverImageUrl ?? '',
    category: professionCode.isEmpty ? 'Professional' : professionCode,
    memberCount: groupMemberCount,
    isJoined: false,
    isPrivate: true,
    isProfessional: true,
    isOwner: false,
    hasPendingJoinRequest: false,
    createdAt: createdUtc,
    topProducts: const [],
  );
}

@freezed
abstract class GroupPostDto with _$GroupPostDto {
  const factory GroupPostDto({
    required String id,
    required String groupId,
    required String authorAccountId,
    String? authorDisplayName,
    String? authorAvatarUrl,
    required String body,
    @Default(0) int reactionCount,
    required DateTime createdUtc,
  }) = _GroupPostDto;

  const GroupPostDto._();

  factory GroupPostDto.fromJson(Map<String, dynamic> json) =>
      _$GroupPostDtoFromJson(json);

  GroupPost toDomain() => GroupPost(
    id: id,
    groupId: groupId,
    userId: authorAccountId,
    userName: authorDisplayName ?? 'Community member',
    userAvatarUrl: authorAvatarUrl ?? '',
    content: body,
    images: const [],
    likeCount: reactionCount,
    commentCount: 0,
    createdAt: createdUtc,
  );
}

String _enumName(Object? value) {
  if (value is String) return value;
  if (value is int) {
    return switch (value) {
      1 => 'Public',
      2 => 'Closed',
      3 => 'Secret',
      4 => 'Professional',
      _ => value.toString(),
    };
  }
  return value?.toString() ?? '';
}

String? _nullableEnumName(Object? value) =>
    value == null ? null : _enumName(value);
