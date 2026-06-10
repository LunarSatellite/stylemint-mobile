import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/profile_summary.dart';

part 'profile_summary_dto.freezed.dart';
part 'profile_summary_dto.g.dart';

/// DTO for the profile header, sourced from `GET /v1/accounts/{accountId}`.
///
/// The account endpoint supplies identity fields only — `email`, the counters
/// (saved / following / orders) and `pushEnabled` are NOT part of this
/// response, so they default until wired to their own endpoints.
@freezed
abstract class ProfileSummaryDto with _$ProfileSummaryDto {
  const factory ProfileSummaryDto({
    required String displayName,
    String? avatarUrl,
    @Default('en-US') String locale,
  }) = _ProfileSummaryDto;

  const ProfileSummaryDto._();

  factory ProfileSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileSummaryDtoFromJson(json);

  ProfileSummary toDomain() => ProfileSummary(
    displayName: displayName,
    email: '',
    avatarUrl: avatarUrl ?? '',
    savedItemsCount: 0,
    followingCount: 0,
    ordersCount: 0,
    language: locale,
    pushEnabled: true,
  );
}
