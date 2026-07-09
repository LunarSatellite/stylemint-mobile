import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// A row of `topCreatorsByAttributedSales` on the Intelligence Dashboard.
class TopCreatorByAttributedSales {
  const TopCreatorByAttributedSales({
    required this.creatorAccountId,
    required this.reelsInWindow,
    required this.attributedUnitsSold,
    required this.attributedRevenue,
    required this.commissionPaid,
    required this.roiRatio,
  });

  final String creatorAccountId;
  final int reelsInWindow;
  final int attributedUnitsSold;
  final Money attributedRevenue;
  final Money commissionPaid;
  final double roiRatio;
}

class ReachDiagnosticsSummary {
  const ReachDiagnosticsSummary({
    required this.totalImpressions,
    required this.uniqueAudience,
    required this.topRegions,
    required this.underperformingRegions,
    required this.audienceGrowthRate,
  });

  final int totalImpressions;
  final int uniqueAudience;
  final List<String> topRegions;
  final List<String> underperformingRegions;
  final double audienceGrowthRate;
}

class FormatLearning {
  const FormatLearning({
    required this.formatLabel,
    required this.count,
    required this.avgCompletionRate,
    required this.avgConversionRate,
    required this.takeaway,
  });

  final String formatLabel;
  final int count;
  final double avgCompletionRate;
  final double avgConversionRate;
  final String takeaway;
}

/// `benchmark` is `null` on the wire when the cohort has fewer than 5
/// members (skill's privacy floor) — callers must hide the card entirely
/// in that case, never render "n/a".
class CompetitiveBenchmarkSummary {
  const CompetitiveBenchmarkSummary({
    required this.yourAvgConversion,
    required this.cohortMedianConversion,
    required this.cohortTopQuartileConversion,
    required this.cohortLabel,
    required this.cohortMemberCount,
    required this.takeaway,
  });

  final double yourAvgConversion;
  final double cohortMedianConversion;
  final double cohortTopQuartileConversion;
  final String cohortLabel;
  final int cohortMemberCount;
  final String takeaway;
}

class SuggestedCreator {
  const SuggestedCreator({
    required this.creatorAccountId,
    required this.creatorHandle,
    required this.matchScore,
    required this.topThreeReasons,
  });

  final String creatorAccountId;
  final String creatorHandle;
  final double matchScore;

  /// Free-text summary from the matching model, not a structured list on
  /// the wire — render as-is.
  final String topThreeReasons;
}

class RecipePerformance {
  const RecipePerformance({
    required this.recipeId,
    required this.recipeVersion,
    required this.citingCreatorCount,
    required this.citedReelCount,
    required this.attributedUnits,
    required this.attributedRevenue,
    this.bestReelId,
    this.bestReelRevenue,
  });

  final String recipeId;
  final int recipeVersion;
  final int citingCreatorCount;
  final int citedReelCount;
  final int attributedUnits;
  final Money attributedRevenue;
  final String? bestReelId;
  final double? bestReelRevenue;
}

/// Mirrors `GET /v1/vendor/dashboard` — the Brand Studio Intelligence
/// Dashboard (materialized, refreshed every 30 min). Distinct from
/// `/v1/vendor/analytics/overview` (gross sales / net revenue / top
/// products), which the plain vendor home screen uses.
class BrandStudioInsights {
  const BrandStudioInsights({
    required this.windowStart,
    required this.windowEndExclusive,
    required this.topCreators,
    required this.reach,
    required this.formatLearnings,
    required this.suggestedCreators,
    required this.byRecipe,
    this.benchmark,
  });

  final DateTime windowStart;
  final DateTime windowEndExclusive;
  final List<TopCreatorByAttributedSales> topCreators;
  final ReachDiagnosticsSummary reach;
  final List<FormatLearning> formatLearnings;

  /// `null` when the cohort has fewer than 5 members — hide the benchmark
  /// card entirely rather than showing a placeholder.
  final CompetitiveBenchmarkSummary? benchmark;
  final List<SuggestedCreator> suggestedCreators;
  final List<RecipePerformance> byRecipe;
}
