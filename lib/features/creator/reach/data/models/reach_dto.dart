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

@freezed
abstract class ReachAnalyticsDto with _$ReachAnalyticsDto {
  const factory ReachAnalyticsDto({
    required int totalImpressions,
    required int totalClicks,
    required int totalEngagements,
    required double totalSpentAmount,
    @Default('NPR') String totalSpentCurrency,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) = _ReachAnalyticsDto;

  const ReachAnalyticsDto._();

  factory ReachAnalyticsDto.fromJson(Map<String, dynamic> json) =>
      _$ReachAnalyticsDtoFromJson(json);

  ReachAnalytics toDomain() => ReachAnalytics(
    totalImpressions: totalImpressions,
    totalClicks: totalClicks,
    totalEngagements: totalEngagements,
    totalSpent: Money(amount: totalSpentAmount, currency: totalSpentCurrency),
    periodStart: periodStart,
    periodEnd: periodEnd,
  );
}
