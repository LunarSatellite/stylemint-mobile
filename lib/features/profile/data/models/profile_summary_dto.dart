import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/profile_summary.dart';

part 'profile_summary_dto.freezed.dart';
part 'profile_summary_dto.g.dart';

/// DTO for the profile summary from `/v1/profile/summary`.
@freezed
abstract class ProfileSummaryDto with _$ProfileSummaryDto {
  const factory ProfileSummaryDto({
    required String displayName,
    required String email,
    @Default('') String avatarUrl,
    @Default(0) int savedItemsCount,
    @Default(0) int followingCount,
    @Default(0) int ordersCount,
    @Default('English') String language,
    @Default(true) bool pushEnabled,
  }) = _ProfileSummaryDto;

  const ProfileSummaryDto._();

  factory ProfileSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileSummaryDtoFromJson(json);

  ProfileSummary toDomain() => ProfileSummary(
    displayName: displayName,
    email: email,
    avatarUrl: avatarUrl,
    savedItemsCount: savedItemsCount,
    followingCount: followingCount,
    ordersCount: ordersCount,
    language: language,
    pushEnabled: pushEnabled,
  );
}
