import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/domain/entities/brand_studio.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'brand_studio_dto.freezed.dart';
part 'brand_studio_dto.g.dart';

@freezed
abstract class CampaignTemplateDto with _$CampaignTemplateDto {
  const factory CampaignTemplateDto({
    required String id,
    required String title,
    required String description,
    required String industry,
    required double recommendedCommission,
    required double recommendedBudgetAmount,
    @Default('NPR') String recommendedBudgetCurrency,
    @Default([]) List<String> tips,
    @Default([]) List<String> successMetrics,
  }) = _CampaignTemplateDto;

  const CampaignTemplateDto._();

  factory CampaignTemplateDto.fromJson(Map<String, dynamic> json) =>
      _$CampaignTemplateDtoFromJson(json);

  CampaignTemplate toDomain() => CampaignTemplate(
    id: id,
    title: title,
    description: description,
    industry: industry,
    recommendedCommission: recommendedCommission,
    recommendedBudget: Money(
      amount: recommendedBudgetAmount,
      currency: recommendedBudgetCurrency,
    ),
    tips: tips,
    successMetrics: successMetrics,
  );
}

@freezed
abstract class CreatorPerformanceDto with _$CreatorPerformanceDto {
  const factory CreatorPerformanceDto({
    required String creatorId,
    required String creatorName,
    required String avatarUrl,
    required double salesGeneratedAmount,
    @Default('NPR') String salesGeneratedCurrency,
    required int impressions,
    required int clicks,
    required double conversionRate,
  }) = _CreatorPerformanceDto;

  const CreatorPerformanceDto._();

  factory CreatorPerformanceDto.fromJson(Map<String, dynamic> json) =>
      _$CreatorPerformanceDtoFromJson(json);

  CreatorPerformance toDomain() => CreatorPerformance(
    creatorId: creatorId,
    creatorName: creatorName,
    avatarUrl: avatarUrl,
    salesGenerated: Money(
      amount: salesGeneratedAmount,
      currency: salesGeneratedCurrency,
    ),
    impressions: impressions,
    clicks: clicks,
    conversionRate: conversionRate,
  );
}

@freezed
abstract class CampaignAnalyticsDto with _$CampaignAnalyticsDto {
  const factory CampaignAnalyticsDto({
    required String campaignId,
    required int impressions,
    required int clicks,
    required int conversions,
    required double conversionRate,
    required double roi,
    required List<CreatorPerformanceDto> topCreators,
    required String trend,
  }) = _CampaignAnalyticsDto;

  const CampaignAnalyticsDto._();

  factory CampaignAnalyticsDto.fromJson(Map<String, dynamic> json) =>
      _$CampaignAnalyticsDtoFromJson(json);

  CampaignAnalytics toDomain() {
    final trendEnum = TrendDirection.values.firstWhere(
      (t) => t.name == trend,
      orElse: () => TrendDirection.flat,
    );
    return CampaignAnalytics(
      campaignId: campaignId,
      impressions: impressions,
      clicks: clicks,
      conversions: conversions,
      conversionRate: conversionRate,
      roi: roi,
      topCreators: topCreators.map((c) => c.toDomain()).toList(growable: false),
      trend: trendEnum,
    );
  }
}

@freezed
abstract class MarketInsightDto with _$MarketInsightDto {
  const factory MarketInsightDto({
    required String category,
    @Default(false) bool trending,
    required double averageCommission,
    required String competitionLevel,
    @Default([]) List<String> recommendedActions,
  }) = _MarketInsightDto;

  const MarketInsightDto._();

  factory MarketInsightDto.fromJson(Map<String, dynamic> json) =>
      _$MarketInsightDtoFromJson(json);

  MarketInsight toDomain() {
    final level = CompetitionLevel.values.firstWhere(
      (c) => c.name == competitionLevel,
      orElse: () => CompetitionLevel.medium,
    );
    return MarketInsight(
      category: category,
      trending: trending,
      averageCommission: averageCommission,
      competitionLevel: level,
      recommendedActions: recommendedActions,
    );
  }
}
