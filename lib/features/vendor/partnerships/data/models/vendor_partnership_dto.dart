import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'vendor_partnership_dto.freezed.dart';
part 'vendor_partnership_dto.g.dart';

/// Matches `RoiProjectionSummary` (Vendor Â§5.4) â€” inline on `BrandBriefDto`
/// and standalone from `POST /v1/vendor/briefs/{id}/recompute-roi`.
@freezed
abstract class RoiProjectionSummaryDto with _$RoiProjectionSummaryDto {
  const factory RoiProjectionSummaryDto({
    @Default(0) double estimatedReachCostAmount,
    @Default('NPR') String estimatedReachCostCurrency,
    @Default(0) int estimatedReachLow,
    @Default(0) int estimatedReachHigh,
    @Default(0) int estimatedSalesLow,
    @Default(0) int estimatedSalesHigh,
    @Default(0) double estimatedRevenueLowAmount,
    @Default(0) double estimatedRevenueHighAmount,
    @Default('NPR') String estimatedRevenueCurrency,
  }) = _RoiProjectionSummaryDto;

  const RoiProjectionSummaryDto._();

  factory RoiProjectionSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$RoiProjectionSummaryDtoFromJson(json);

  RoiProjectionSummary toDomain() => RoiProjectionSummary(
    estimatedReachCost: Money(
      amount: estimatedReachCostAmount,
      currency: estimatedReachCostCurrency,
    ),
    estimatedReachLow: estimatedReachLow,
    estimatedReachHigh: estimatedReachHigh,
    estimatedSalesLow: estimatedSalesLow,
    estimatedSalesHigh: estimatedSalesHigh,
    estimatedRevenueLow: Money(
      amount: estimatedRevenueLowAmount,
      currency: estimatedRevenueCurrency,
    ),
    estimatedRevenueHigh: Money(
      amount: estimatedRevenueHighAmount,
      currency: estimatedRevenueCurrency,
    ),
  );
}

/// Matches `BrandBriefDto` from `GET/POST/PATCH /v1/vendor/briefs*` and the
/// lifecycle actions (`lock`/`fork`/`retire`/`recompute-roi`).
@freezed
abstract class CampaignBriefDto with _$CampaignBriefDto {
  const factory CampaignBriefDto({
    required String id,
    required String vendorProfileId,
    String? title,
    @Default(0) int primaryGoal,
    @Default(1) int state,
    @Default(1) int version,
    String? rootBriefId,
    String? parentBriefId,
    CommissionRangeDto? commissionRange,
    @Default(0) double boostBudgetAmount,
    @Default('NPR') String boostBudgetCurrency,
    RoiProjectionSummaryDto? roiProjection,
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
    state:
        BrandBriefState.values.elementAtOrNull(state - 1) ??
        BrandBriefState.draft,
    version: version,
    rootBriefId: rootBriefId ?? id,
    parentBriefId: parentBriefId,
    commissionMinPercent: commissionRange?.minPercent ?? 0,
    commissionMaxPercent: commissionRange?.maxPercent ?? 0,
    boostBudget: Money(
      amount: boostBudgetAmount,
      currency: boostBudgetCurrency,
    ),
    roiProjection: roiProjection?.toDomain(),
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
    /// Optional / back-compat only â€” the backend resolves the vendor from
    /// the authenticated caller (`VendorBriefsController.ResolveVendorAsync`).
    /// Omit rather than send an empty string: ASP.NET's default `Guid`
    /// model binder rejects `""`, it only tolerates a missing field.
    String? vendorProfileId,
    String? title,
    required int primaryGoal,
    List<String>? productVariantIds,
    String? currencyCode,
  }) = _DraftBriefVm;

  factory DraftBriefVm.fromJson(Map<String, dynamic> json) =>
      _$DraftBriefVmFromJson(json);
}

/// Request body for `PATCH /v1/vendor/briefs/{id}` (`UpdateBriefVm`) â€” only
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
/// (Vendor Â§7J â€” the invite picker).
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

/// Mirrors `PartnershipDto` from `GET /v1/vendor/partnerships`.
@freezed
abstract class VendorPartnershipDto with _$VendorPartnershipDto {
  const factory VendorPartnershipDto({
    required String id,
    required String vendorProfileId,
    required String creatorProfileId,
    required int state,
    @Default(0) double commissionMinPercent,
    @Default(0) double commissionMaxPercent,
    required DateTime invitedUtc,
    DateTime? respondedUtc,
    DateTime? endedUtc,
    String? endReason,
    String? brandBriefId,
    @Default(false) bool initiatedByCreator,
    String? requestMessage,
    double? vendorRating,
    // Joined at read time from stylemint-identity's CreatorProfile \u2014 mirrors
    // the existing vendorRating field. The vendor partnership list + chat
    // surfaces use these to display the creator's name/handle/avatar
    // without a separate profile lookup.
    String? creatorName,
    String? creatorHandle,
    String? creatorLogoUrl,
    String? creatorAccountId,
  }) = _VendorPartnershipDto;

  const VendorPartnershipDto._();

  factory VendorPartnershipDto.fromJson(Map<String, dynamic> json) =>
      _$VendorPartnershipDtoFromJson(json);

  VendorPartnership toDomain() => VendorPartnership(
    id: id,
    vendorProfileId: vendorProfileId,
    creatorProfileId: creatorProfileId,
    state:
        PartnershipState.values.elementAtOrNull(state - 1) ??
        PartnershipState.invited,
    commissionMinPercent: commissionMinPercent,
    commissionMaxPercent: commissionMaxPercent,
    invitedAt: invitedUtc,
    respondedAt: respondedUtc,
    endedAt: endedUtc,
    endReason: endReason,
    brandBriefId: brandBriefId,
    initiatedByCreator: initiatedByCreator,
    requestMessage: requestMessage,
    vendorRating: vendorRating,
    creatorName: creatorName ?? "",
    creatorHandle: creatorHandle ?? "",
    creatorLogoUrl: creatorLogoUrl,
    creatorAccountId: creatorAccountId,
  );
}
