import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'vendor_partnership_dto.freezed.dart';
part 'vendor_partnership_dto.g.dart';

/// Matches `BrandBriefDto` from `GET/POST/PATCH /v1/vendor/briefs*`.
@freezed
abstract class CampaignBriefDto with _$CampaignBriefDto {
  const factory CampaignBriefDto({
    required String id,
    required String vendorProfileId,
    String? title,
    @Default(0) int primaryGoal,
    @Default(1) int state,
    CommissionRangeDto? commissionRange,
    @Default(0) double boostBudgetAmount,
    @Default('NPR') String boostBudgetCurrency,
    required DateTime createdUtc,
    required DateTime updatedUtc,
    DateTime? lockedUtc,
  }) = _CampaignBriefDto;

  const CampaignBriefDto._();

  factory CampaignBriefDto.fromJson(Map<String, dynamic> json) =>
      _$CampaignBriefDtoFromJson(json);

  CampaignBrief toDomain() => CampaignBrief(
    id: id,
    vendorProfileId: vendorProfileId,
    title: title,
    primaryGoal: primaryGoal,
    state: BrandBriefState.values.elementAtOrNull(state - 1) ??
        BrandBriefState.draft,
    commissionMinPercent: commissionRange?.minPercent ?? 0,
    commissionMaxPercent: commissionRange?.maxPercent ?? 0,
    boostBudget: Money(amount: boostBudgetAmount, currency: boostBudgetCurrency),
    createdAt: createdUtc,
    updatedAt: updatedUtc,
    lockedAt: lockedUtc,
  );
}

@freezed
abstract class CommissionRangeDto with _$CommissionRangeDto {
  const factory CommissionRangeDto({
    @Default(0) double minPercent,
    @Default(0) double maxPercent,
  }) = _CommissionRangeDto;

  factory CommissionRangeDto.fromJson(Map<String, dynamic> json) =>
      _$CommissionRangeDtoFromJson(json);
}

/// Request body for `POST /v1/vendor/briefs` (`DraftBriefVm`).
@freezed
abstract class DraftBriefVm with _$DraftBriefVm {
  const factory DraftBriefVm({
    required String vendorProfileId,
    String? title,
    required int primaryGoal,
    List<String>? productVariantIds,
    String? currencyCode,
  }) = _DraftBriefVm;

  factory DraftBriefVm.fromJson(Map<String, dynamic> json) =>
      _$DraftBriefVmFromJson(json);
}

/// Request body for `PATCH /v1/vendor/briefs/{id}` (`UpdateBriefVm`) — only
/// the subset the mobile UI edits today.
@freezed
abstract class UpdateBriefVm with _$UpdateBriefVm {
  const factory UpdateBriefVm({
    String? title,
    int? primaryGoal,
    CommissionRangeDto? commissionRange,
    double? boostBudgetAmount,
    String? boostBudgetCurrency,
  }) = _UpdateBriefVm;

  factory UpdateBriefVm.fromJson(Map<String, dynamic> json) =>
      _$UpdateBriefVmFromJson(json);
}

/// Matches `CreatorPickerDto` from `GET /v1/vendor/partnerships/creators`
/// (Vendor §7J — the invite picker).
@freezed
abstract class CreatorInviteDto with _$CreatorInviteDto {
  const factory CreatorInviteDto({
    required String creatorAccountId,
    String? displayName,
    String? handle,
    String? avatarUrl,
    String? bio,
    int? followerCount,
    @Default(<String>[]) List<String> niches,
    @Default(false) bool hasExistingPartnership,
  }) = _CreatorInviteDto;

  const CreatorInviteDto._();

  factory CreatorInviteDto.fromJson(Map<String, dynamic> json) =>
      _$CreatorInviteDtoFromJson(json);

  CreatorInvite toDomain() => CreatorInvite(
    creatorAccountId: creatorAccountId,
    displayName: displayName,
    handle: handle,
    avatarUrl: avatarUrl,
    bio: bio,
    followerCount: followerCount,
    niches: niches,
    hasExistingPartnership: hasExistingPartnership,
  );
}
