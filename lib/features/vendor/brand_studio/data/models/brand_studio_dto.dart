import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/domain/entities/brand_studio.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

Money _money(num? amount, String? currency) =>
    Money(amount: amount?.toDouble() ?? 0, currency: currency ?? 'NPR');

class TopCreatorByAttributedSalesDto {
  const TopCreatorByAttributedSalesDto({
    required this.creatorAccountId,
    required this.reelsInWindow,
    required this.attributedUnitsSold,
    required this.attributedRevenueAmount,
    required this.attributedRevenueCurrency,
    required this.commissionPaidAmount,
    required this.commissionPaidCurrency,
    required this.roiRatio,
  });

  factory TopCreatorByAttributedSalesDto.fromJson(Map<String, dynamic> json) =>
      TopCreatorByAttributedSalesDto(
        creatorAccountId: json['creatorAccountId'] as String? ?? '',
        reelsInWindow: json['reelsInWindow'] as int? ?? 0,
        attributedUnitsSold: json['attributedUnitsSold'] as int? ?? 0,
        attributedRevenueAmount:
            (json['attributedRevenueAmount'] as num?)?.toDouble() ?? 0,
        attributedRevenueCurrency:
            json['attributedRevenueCurrency'] as String? ?? 'NPR',
        commissionPaidAmount:
            (json['commissionPaidAmount'] as num?)?.toDouble() ?? 0,
        commissionPaidCurrency:
            json['commissionPaidCurrency'] as String? ?? 'NPR',
        roiRatio: (json['roiRatio'] as num?)?.toDouble() ?? 0,
      );

  final String creatorAccountId;
  final int reelsInWindow;
  final int attributedUnitsSold;
  final double attributedRevenueAmount;
  final String attributedRevenueCurrency;
  final double commissionPaidAmount;
  final String commissionPaidCurrency;
  final double roiRatio;

  TopCreatorByAttributedSales toDomain() => TopCreatorByAttributedSales(
    creatorAccountId: creatorAccountId,
    reelsInWindow: reelsInWindow,
    attributedUnitsSold: attributedUnitsSold,
    attributedRevenue: _money(
      attributedRevenueAmount,
      attributedRevenueCurrency,
    ),
    commissionPaid: _money(commissionPaidAmount, commissionPaidCurrency),
    roiRatio: roiRatio,
  );
}

class ReachDiagnosticsSummaryDto {
  const ReachDiagnosticsSummaryDto({
    required this.totalImpressions,
    required this.uniqueAudience,
    required this.topRegions,
    required this.underperformingRegions,
    required this.audienceGrowthRate,
  });

  factory ReachDiagnosticsSummaryDto.fromJson(Map<String, dynamic>? json) =>
      ReachDiagnosticsSummaryDto(
        totalImpressions: json?['totalImpressions'] as int? ?? 0,
        uniqueAudience: json?['uniqueAudience'] as int? ?? 0,
        topRegions: (json?['topRegions'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        underperformingRegions:
            (json?['underperformingRegions'] as List<dynamic>? ?? [])
                .map((e) => e as String)
                .toList(),
        audienceGrowthRate:
            (json?['audienceGrowthRate'] as num?)?.toDouble() ?? 0,
      );

  final int totalImpressions;
  final int uniqueAudience;
  final List<String> topRegions;
  final List<String> underperformingRegions;
  final double audienceGrowthRate;

  ReachDiagnosticsSummary toDomain() => ReachDiagnosticsSummary(
    totalImpressions: totalImpressions,
    uniqueAudience: uniqueAudience,
    topRegions: topRegions,
    underperformingRegions: underperformingRegions,
    audienceGrowthRate: audienceGrowthRate,
  );
}

class FormatLearningDto {
  const FormatLearningDto({
    required this.formatLabel,
    required this.count,
    required this.avgCompletionRate,
    required this.avgConversionRate,
    required this.takeaway,
  });

  factory FormatLearningDto.fromJson(Map<String, dynamic> json) =>
      FormatLearningDto(
        formatLabel: json['formatLabel'] as String? ?? '',
        count: json['count'] as int? ?? 0,
        avgCompletionRate: (json['avgCompletionRate'] as num?)?.toDouble() ?? 0,
        avgConversionRate: (json['avgConversionRate'] as num?)?.toDouble() ?? 0,
        takeaway: json['takeaway'] as String? ?? '',
      );

  final String formatLabel;
  final int count;
  final double avgCompletionRate;
  final double avgConversionRate;
  final String takeaway;

  FormatLearning toDomain() => FormatLearning(
    formatLabel: formatLabel,
    count: count,
    avgCompletionRate: avgCompletionRate,
    avgConversionRate: avgConversionRate,
    takeaway: takeaway,
  );
}

class CompetitiveBenchmarkSummaryDto {
  const CompetitiveBenchmarkSummaryDto({
    required this.yourAvgConversion,
    required this.cohortMedianConversion,
    required this.cohortTopQuartileConversion,
    required this.cohortLabel,
    required this.cohortMemberCount,
    required this.takeaway,
  });

  factory CompetitiveBenchmarkSummaryDto.fromJson(Map<String, dynamic> json) =>
      CompetitiveBenchmarkSummaryDto(
        yourAvgConversion: (json['yourAvgConversion'] as num?)?.toDouble() ?? 0,
        cohortMedianConversion:
            (json['cohortMedianConversion'] as num?)?.toDouble() ?? 0,
        cohortTopQuartileConversion:
            (json['cohortTopQuartileConversion'] as num?)?.toDouble() ?? 0,
        cohortLabel: json['cohortLabel'] as String? ?? '',
        cohortMemberCount: json['cohortMemberCount'] as int? ?? 0,
        takeaway: json['takeaway'] as String? ?? '',
      );

  final double yourAvgConversion;
  final double cohortMedianConversion;
  final double cohortTopQuartileConversion;
  final String cohortLabel;
  final int cohortMemberCount;
  final String takeaway;

  CompetitiveBenchmarkSummary toDomain() => CompetitiveBenchmarkSummary(
    yourAvgConversion: yourAvgConversion,
    cohortMedianConversion: cohortMedianConversion,
    cohortTopQuartileConversion: cohortTopQuartileConversion,
    cohortLabel: cohortLabel,
    cohortMemberCount: cohortMemberCount,
    takeaway: takeaway,
  );
}

class SuggestedCreatorDto {
  const SuggestedCreatorDto({
    required this.creatorAccountId,
    required this.creatorHandle,
    required this.matchScore,
    required this.topThreeReasons,
  });

  factory SuggestedCreatorDto.fromJson(Map<String, dynamic> json) =>
      SuggestedCreatorDto(
        creatorAccountId: json['creatorAccountId'] as String? ?? '',
        creatorHandle: json['creatorHandle'] as String? ?? '',
        matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0,
        topThreeReasons: json['topThreeReasons'] as String? ?? '',
      );

  final String creatorAccountId;
  final String creatorHandle;
  final double matchScore;
  final String topThreeReasons;

  SuggestedCreator toDomain() => SuggestedCreator(
    creatorAccountId: creatorAccountId,
    creatorHandle: creatorHandle,
    matchScore: matchScore,
    topThreeReasons: topThreeReasons,
  );
}

class RecipePerformanceDto {
  const RecipePerformanceDto({
    required this.recipeId,
    required this.recipeVersion,
    required this.citingCreatorCount,
    required this.citedReelCount,
    required this.attributedUnits,
    required this.attributedRevenueAmount,
    required this.attributedRevenueCurrency,
    this.bestReelId,
    this.bestReelRevenueAmount,
  });

  factory RecipePerformanceDto.fromJson(Map<String, dynamic> json) =>
      RecipePerformanceDto(
        recipeId: json['recipeId'] as String? ?? '',
        recipeVersion: json['recipeVersion'] as int? ?? 0,
        citingCreatorCount: json['citingCreatorCount'] as int? ?? 0,
        citedReelCount: json['citedReelCount'] as int? ?? 0,
        attributedUnits: json['attributedUnits'] as int? ?? 0,
        attributedRevenueAmount:
            (json['attributedRevenueAmount'] as num?)?.toDouble() ?? 0,
        attributedRevenueCurrency:
            json['attributedRevenueCurrency'] as String? ?? 'NPR',
        bestReelId: json['bestReelId'] as String?,
        bestReelRevenueAmount: (json['bestReelRevenueAmount'] as num?)
            ?.toDouble(),
      );

  final String recipeId;
  final int recipeVersion;
  final int citingCreatorCount;
  final int citedReelCount;
  final int attributedUnits;
  final double attributedRevenueAmount;
  final String attributedRevenueCurrency;
  final String? bestReelId;
  final double? bestReelRevenueAmount;

  RecipePerformance toDomain() => RecipePerformance(
    recipeId: recipeId,
    recipeVersion: recipeVersion,
    citingCreatorCount: citingCreatorCount,
    citedReelCount: citedReelCount,
    attributedUnits: attributedUnits,
    attributedRevenue: _money(
      attributedRevenueAmount,
      attributedRevenueCurrency,
    ),
    bestReelId: bestReelId,
    bestReelRevenue: bestReelRevenueAmount,
  );
}

/// Mirrors `GET /v1/vendor/dashboard` (Brand Studio Intelligence Dashboard).
class BrandStudioInsightsDto {
  const BrandStudioInsightsDto({
    required this.windowStartUtc,
    required this.windowEndExclusiveUtc,
    required this.topCreatorsByAttributedSales,
    required this.reach,
    required this.formatLearnings,
    required this.suggestedCreators,
    required this.byRecipe,
    this.benchmark,
  });

  factory BrandStudioInsightsDto.fromJson(Map<String, dynamic> json) =>
      BrandStudioInsightsDto(
        windowStartUtc: DateTime.parse(json['windowStartUtc'] as String),
        windowEndExclusiveUtc: DateTime.parse(
          json['windowEndExclusiveUtc'] as String,
        ),
        topCreatorsByAttributedSales:
            (json['topCreatorsByAttributedSales'] as List<dynamic>? ?? [])
                .map(
                  (e) => TopCreatorByAttributedSalesDto.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList(),
        reach: ReachDiagnosticsSummaryDto.fromJson(
          json['reach'] as Map<String, dynamic>?,
        ),
        formatLearnings: (json['formatLearnings'] as List<dynamic>? ?? [])
            .map((e) => FormatLearningDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        benchmark: json['benchmark'] == null
            ? null
            : CompetitiveBenchmarkSummaryDto.fromJson(
                json['benchmark'] as Map<String, dynamic>,
              ),
        suggestedCreators: (json['suggestedCreators'] as List<dynamic>? ?? [])
            .map(
              (e) => SuggestedCreatorDto.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        byRecipe: (json['byRecipe'] as List<dynamic>? ?? [])
            .map(
              (e) => RecipePerformanceDto.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );

  final DateTime windowStartUtc;
  final DateTime windowEndExclusiveUtc;
  final List<TopCreatorByAttributedSalesDto> topCreatorsByAttributedSales;
  final ReachDiagnosticsSummaryDto reach;
  final List<FormatLearningDto> formatLearnings;
  final CompetitiveBenchmarkSummaryDto? benchmark;
  final List<SuggestedCreatorDto> suggestedCreators;
  final List<RecipePerformanceDto> byRecipe;

  BrandStudioInsights toDomain() => BrandStudioInsights(
    windowStart: windowStartUtc,
    windowEndExclusive: windowEndExclusiveUtc,
    topCreators: topCreatorsByAttributedSales.map((e) => e.toDomain()).toList(),
    reach: reach.toDomain(),
    formatLearnings: formatLearnings.map((e) => e.toDomain()).toList(),
    benchmark: benchmark?.toDomain(),
    suggestedCreators: suggestedCreators.map((e) => e.toDomain()).toList(),
    byRecipe: byRecipe.map((e) => e.toDomain()).toList(),
  );
}
