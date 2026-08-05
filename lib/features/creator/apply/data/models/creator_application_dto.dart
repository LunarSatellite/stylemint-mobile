import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/creator_application.dart';

part 'creator_application_dto.freezed.dart';
part 'creator_application_dto.g.dart';

@freezed
abstract class PlatformDto with _$PlatformDto {
  const factory PlatformDto({
    required String id,
    required String name,
    required String handle,
    required int followerCount,
    @Default(false) bool connected,
  }) = _PlatformDto;

  const PlatformDto._();

  factory PlatformDto.fromJson(Map<String, dynamic> json) =>
      _$PlatformDtoFromJson(json);

  Platform toDomain() => Platform(
    id: id,
    name: name,
    handle: handle,
    followerCount: followerCount,
    connected: connected,
  );
}

/// A single row from GET /v1/creator/application -> socials[]. Carries
/// only the fields the BE persists for an application social (provider int
/// enum, handle, self-reported follower count). Maps back to a [Platform]
/// domain entity via [toDomain] for reapply pre-fill.
@freezed
abstract class CreatorApplicationSocialDto
    with _$CreatorApplicationSocialDto {
  const factory CreatorApplicationSocialDto({
    required int provider,
    String? handle,
    @JsonKey(name: 'followerCountSelfReported') int? followerCount,
  }) = _CreatorApplicationSocialDto;

  const CreatorApplicationSocialDto._();

  factory CreatorApplicationSocialDto.fromJson(Map<String, dynamic> json) =>
      _$CreatorApplicationSocialDtoFromJson(json);

  /// Reverse of the [SocialIdentityProvider] enum used by the apply endpoint.
  /// Null for providers the wizard doesn't model (e.g. Snapchat, X).
  String? get platformId => switch (provider) {
        1 => 'instagram',
        2 => 'tiktok',
        3 => 'youtube',
        4 => 'facebook',
        _ => null,
      };

  Platform toDomain() {
    final id = platformId ?? 'unknown';
    final pretty = id == 'unknown'
        ? 'Unknown'
        : '${id[0].toUpperCase()}${id.substring(1)}';
    return Platform(
      id: id,
      name: pretty,
      handle: handle ?? '',
      followerCount: followerCount ?? 0,
    );
  }
}

@freezed
abstract class CreatorApplicationDto with _$CreatorApplicationDto {
  const factory CreatorApplicationDto({
    required String id,
    // ApplicationState integer enum: 1 Draft, 2 Submitted, 3 UnderReview,
    // 4 Approved, 5 Rejected.
    required int state,
    String? rejectionReason,
    String? bio,
    int? audienceBand,
    String? otherCategoryDescription,
    @Default(<String>[]) List<String> categoryIds,
    @Default(<CreatorApplicationSocialDto>[])
    List<CreatorApplicationSocialDto> socials,
    DateTime? submittedAtUtc,
    DateTime? createdUtc,
    DateTime? updatedUtc,
  }) = _CreatorApplicationDto;

  const CreatorApplicationDto._();

  factory CreatorApplicationDto.fromJson(Map<String, dynamic> json) {
    // Flatten the BE's nested categories[] and socials[] arrays into the
    // scalar fields the DTO actually carries. The wire shape for
    // categories is { id, creatorApplicationId, creatorContentCategoryId };
    // we only need the last one (the category GUID the apply payload sends).
    final rawCategories = (json['categories'] as List<dynamic>?) ?? const [];
    final categoryIds = rawCategories
        .map(
          (c) =>
              (c as Map<String, dynamic>)['creatorContentCategoryId']
                  as String?,
        )
        .whereType<String>()
        .toList(growable: false);
    final rawSocials = (json['socials'] as List<dynamic>?) ?? const [];
    return _$CreatorApplicationDtoFromJson(<String, dynamic>{
      ...json,
      'categoryIds': categoryIds,
      'socials': rawSocials,
    });
  }

  CreatorApplication toDomain() {
    final created = createdUtc ?? DateTime.fromMillisecondsSinceEpoch(0);
    return CreatorApplication(
      id: id,
      status: _statusFromState(state),
      rejectionReason: rejectionReason,
      bio: bio ?? '',
      audienceBand: audienceBand ?? 1,
      otherCategoryDescription: otherCategoryDescription,
      categoryIds: categoryIds,
      socials: socials.map((s) => s.toDomain()).toList(growable: false),
      submittedAt: submittedAtUtc ?? created,
      updatedAt: updatedUtc ?? created,
    );
  }

  static CreatorApplicationStatus _statusFromState(int state) {
    switch (state) {
      case 1: // Draft
      case 2: // Submitted
        return CreatorApplicationStatus.pending;
      case 3: // UnderReview
        return CreatorApplicationStatus.underReview;
      case 4: // Approved
        return CreatorApplicationStatus.approved;
      case 5: // Rejected
        return CreatorApplicationStatus.rejected;
      default:
        return CreatorApplicationStatus.pending;
    }
  }
}