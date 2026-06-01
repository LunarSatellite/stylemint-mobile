import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class CampaignTemplate {
  const CampaignTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.industry,
    required this.recommendedCommission,
    required this.recommendedBudget,
    required this.tips,
    required this.successMetrics,
  });

  final String id;
  final String title;
  final String description;
  final String industry;
  final double recommendedCommission;
  final Money recommendedBudget;
  final List<String> tips;
  final List<String> successMetrics;

  CampaignTemplate copyWith({
    String? id,
    String? title,
    String? description,
    String? industry,
    double? recommendedCommission,
    Money? recommendedBudget,
    List<String>? tips,
    List<String>? successMetrics,
  }) {
    return CampaignTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      industry: industry ?? this.industry,
      recommendedCommission: recommendedCommission ?? this.recommendedCommission,
      recommendedBudget: recommendedBudget ?? this.recommendedBudget,
      tips: tips ?? this.tips,
      successMetrics: successMetrics ?? this.successMetrics,
    );
  }
}

enum TrendDirection { up, down, flat }

class CreatorPerformance {
  const CreatorPerformance({
    required this.creatorId,
    required this.creatorName,
    required this.avatarUrl,
    required this.salesGenerated,
    required this.impressions,
    required this.clicks,
    required this.conversionRate,
  });

  final String creatorId;
  final String creatorName;
  final String avatarUrl;
  final Money salesGenerated;
  final int impressions;
  final int clicks;
  final double conversionRate;

  CreatorPerformance copyWith({
    String? creatorId,
    String? creatorName,
    String? avatarUrl,
    Money? salesGenerated,
    int? impressions,
    int? clicks,
    double? conversionRate,
  }) {
    return CreatorPerformance(
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      salesGenerated: salesGenerated ?? this.salesGenerated,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      conversionRate: conversionRate ?? this.conversionRate,
    );
  }
}

class CampaignAnalytics {
  const CampaignAnalytics({
    required this.campaignId,
    required this.impressions,
    required this.clicks,
    required this.conversions,
    required this.conversionRate,
    required this.roi,
    required this.topCreators,
    required this.trend,
  });

  final String campaignId;
  final int impressions;
  final int clicks;
  final int conversions;
  final double conversionRate;
  final double roi;
  final List<CreatorPerformance> topCreators;
  final TrendDirection trend;

  CampaignAnalytics copyWith({
    String? campaignId,
    int? impressions,
    int? clicks,
    int? conversions,
    double? conversionRate,
    double? roi,
    List<CreatorPerformance>? topCreators,
    TrendDirection? trend,
  }) {
    return CampaignAnalytics(
      campaignId: campaignId ?? this.campaignId,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      conversions: conversions ?? this.conversions,
      conversionRate: conversionRate ?? this.conversionRate,
      roi: roi ?? this.roi,
      topCreators: topCreators ?? this.topCreators,
      trend: trend ?? this.trend,
    );
  }
}

enum CompetitionLevel { low, medium, high }

class MarketInsight {
  const MarketInsight({
    required this.category,
    required this.trending,
    required this.averageCommission,
    required this.competitionLevel,
    required this.recommendedActions,
  });

  final String category;
  final bool trending;
  final double averageCommission;
  final CompetitionLevel competitionLevel;
  final List<String> recommendedActions;

  MarketInsight copyWith({
    String? category,
    bool? trending,
    double? averageCommission,
    CompetitionLevel? competitionLevel,
    List<String>? recommendedActions,
  }) {
    return MarketInsight(
      category: category ?? this.category,
      trending: trending ?? this.trending,
      averageCommission: averageCommission ?? this.averageCommission,
      competitionLevel: competitionLevel ?? this.competitionLevel,
      recommendedActions: recommendedActions ?? this.recommendedActions,
    );
  }
}
