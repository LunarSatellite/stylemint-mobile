import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/domain/entities/reach.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'reach_dto.freezed.dart';
part 'reach_dto.g.dart';

@freezed
abstract class PublishTargetDto with _$PublishTargetDto {
  const factory PublishTargetDto({
    required String id,
    required String platform,
    required DateTime scheduledAt,
    @Default('scheduled') String status,
  }) = _PublishTargetDto;

  const PublishTargetDto._();

  factory PublishTargetDto.fromJson(Map<String, dynamic> json) =>
      _$PublishTargetDtoFromJson(json);

  PublishTarget toDomain() {
    final platformEnum = SocialPlatform.values.firstWhere(
      (p) => p.name == platform,
      orElse: () => SocialPlatform.instagram,
    );
    final statusEnum = PublishStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => PublishStatus.scheduled,
    );
    return PublishTarget(
      id: id,
      platform: platformEnum,
      scheduledAt: scheduledAt,
      status: statusEnum,
    );
  }
}

@freezed
abstract class BoostCampaignDto with _$BoostCampaignDto {
  const factory BoostCampaignDto({
    required String id,
    required String reelId,
    required String platform,
    required double budgetAmount,
    @Default('NPR') String budgetCurrency,
    required double spentAmountAmount,
    @Default('NPR') String spentAmountCurrency,
    @Default(0) int impressions,
    @Default(0) int clicks,
    required String status,
    required DateTime startedAt,
    DateTime? endAt,
  }) = _BoostCampaignDto;

  const BoostCampaignDto._();

  factory BoostCampaignDto.fromJson(Map<String, dynamic> json) =>
      _$BoostCampaignDtoFromJson(json);

  BoostCampaign toDomain() {
    final platformEnum = SocialPlatform.values.firstWhere(
      (p) => p.name == platform,
      orElse: () => SocialPlatform.instagram,
    );
    final statusEnum = BoostStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => BoostStatus.active,
    );
    return BoostCampaign(
      id: id,
      reelId: reelId,
      platform: platformEnum,
      budget: Money(amount: budgetAmount, currency: budgetCurrency),
      spentAmount: Money(
        amount: spentAmountAmount,
        currency: spentAmountCurrency,
      ),
      impressions: impressions,
      clicks: clicks,
      status: statusEnum,
      startedAt: startedAt,
      endAt: endAt,
    );
  }
}

/// Maps backend `PerPlatformSummaryDto` — one row per connected platform
/// inside `UnifiedReachSnapshotDto.platforms`.
@freezed
abstract class PerPlatformSummaryDto with _$PerPlatformSummaryDto {
  const factory PerPlatformSummaryDto({
    @Default(0) int postsPublished,
    @Default(0) int reach,
    @Default(0) int engagements,
  }) = _PerPlatformSummaryDto;

  const PerPlatformSummaryDto._();

  factory PerPlatformSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$PerPlatformSummaryDtoFromJson(json);
}

/// Maps `GET /v1/reach/dashboard`'s real response shape — backend
/// `UnifiedReachSnapshotDto` (StyleMint.Modules.Reach). There is no flat
/// totalImpressions/totalClicks/periodStart on the wire; reach and
/// engagement totals are summed client-side from `platforms[]`, and there
/// is no click-through concept in this snapshot at all.
@freezed
abstract class ReachAnalyticsDto with _$ReachAnalyticsDto {
  const factory ReachAnalyticsDto({
    @Default(<PerPlatformSummaryDto>[]) List<PerPlatformSummaryDto> platforms,
    @Default(0) double totalBoostSpendAmount,
    @Default('NPR') String totalBoostSpendCurrency,
    required DateTime windowStartUtc,
    required DateTime windowEndUtc,
  }) = _ReachAnalyticsDto;

  const ReachAnalyticsDto._();

  factory ReachAnalyticsDto.fromJson(Map<String, dynamic> json) =>
      _$ReachAnalyticsDtoFromJson(json);

  ReachAnalytics toDomain() => ReachAnalytics(
    totalReach: platforms.fold(0, (sum, p) => sum + p.reach),
    totalPostsPublished: platforms.fold(0, (sum, p) => sum + p.postsPublished),
    totalEngagements: platforms.fold(0, (sum, p) => sum + p.engagements),
    totalSpent: Money(
      amount: totalBoostSpendAmount,
      currency: totalBoostSpendCurrency,
    ),
    periodStart: windowStartUtc,
    periodEnd: windowEndUtc,
  );
}
