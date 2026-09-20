import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/creator_analytics_overview_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/creator_reel_analytics_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/full_analytics_report_dto.dart';

/// **Every rate on the creator's analytics screens was a hundredth of
/// itself.**
///
/// `CreatorAnalyticsService` produces its rates as ratios in `0..1`:
/// `salesCount / views` for conversion, `attributedUnits / inAppViews` for
/// a reel's conversion, `completedViews / inAppViews` for completion.
/// `KpiTileDto<double>` and `ReelStatisticsDto` carry them over the wire
/// untouched, and three screens print each one with a literal `%`:
///
///   * `analytics_screen.dart` — `'${conversionRate.current
///     .toStringAsFixed(1)}%'`
///   * `full_analytics_report_screen.dart` — `toStringAsFixed(2)%`, in a
///     tile and in the text the share button sends out of the app
///   * `reel_detail_analytics_screen.dart` — the same for conversion,
///     click-through and completion
///
/// So a creator whose reels converted 3.4 % of viewers read "0.0%", and
/// one whose reel 62 % of viewers watched to the end read "Completion
/// rate: 0.62%". Both read as "almost nobody", which is a claim about
/// their work, not a blank.
///
/// Asserted over the parsed values and the strings the screens build from
/// them.
void main() {
  group('overview conversion tile', () {
    test('a 3.4 % conversion parses as 3.4, not 0.034', () {
      final overview = CreatorAnalyticsOverviewDto.fromJson(
        _overviewJson(ratio: 0.034, priorRatio: 0.02),
      ).toDomain();

      expect(overview.conversionRate.current, closeTo(3.4, 1e-9));
      expect(overview.conversionRate.previous, closeTo(2.0, 1e-9));
      expect(
        '${overview.conversionRate.current.toStringAsFixed(1)}%',
        '3.4%',
      );
    });

    test('the delta is left alone — it is already a percentage', () {
      final overview = CreatorAnalyticsOverviewDto.fromJson(
        _overviewJson(ratio: 0.034, priorRatio: 0.02, delta: 70.0),
      ).toDomain();

      expect(overview.conversionRate.deltaPercent, 70.0);
    });

    test('a genuine zero stays zero', () {
      final overview = CreatorAnalyticsOverviewDto.fromJson(
        _overviewJson(ratio: 0, priorRatio: 0),
      ).toDomain();

      expect(overview.conversionRate.current, 0);
    });

    test('earnings are money and are not scaled with the rate', () {
      final overview = CreatorAnalyticsOverviewDto.fromJson(
        _overviewJson(ratio: 0.034, priorRatio: 0.02),
      ).toDomain();

      expect(overview.totalEarnings.current.amount, 24500);
      expect(overview.pendingBalance.amount, 4210.02);
    });
  });

  group('full report conversion metrics', () {
    test('conversion is a percent and the order value is untouched', () {
      final metrics = ConversionMetricsDto.fromJson(<String, dynamic>{
        'totalClicks': 0,
        'totalOrders': 34,
        'conversionRate': 0.034,
        'averageOrderValue': {'amount': 2500.0, 'currency': 'NPR'},
      }).toDomain();

      expect(metrics.conversionRate, closeTo(3.4, 1e-9));
      expect('${metrics.conversionRate.toStringAsFixed(2)}%', '3.40%');
      expect(metrics.averageOrderValue.amount, 2500.0);
      expect(metrics.totalOrders, 34);
    });
  });

  group('reel statistics', () {
    test('all three rates become percentages', () {
      final stats = ReelStatisticsDto.fromJson(<String, dynamic>{
        'conversionRate': 0.034,
        'clickThroughRate': 0.012,
        'completionRate': 0.62,
        'uniqueViewersEstimate': 18432,
      }).toDomain();

      expect(stats.conversionRate, closeTo(3.4, 1e-9));
      expect(stats.clickThroughRate, closeTo(1.2, 1e-9));
      expect(stats.completionRate, closeTo(62.0, 1e-9));
      expect('${stats.completionRate.toStringAsFixed(2)}%', '62.00%');
    });

    test('a count beside them is not scaled', () {
      final stats = ReelStatisticsDto.fromJson(<String, dynamic>{
        'conversionRate': 0.034,
        'clickThroughRate': 0,
        'completionRate': 0.62,
        'uniqueViewersEstimate': 18432,
      }).toDomain();

      expect(stats.uniqueViewersEstimate, 18432);
    });

    test('a ratio of 1 is a hundred percent, not one', () {
      final stats = ReelStatisticsDto.fromJson(<String, dynamic>{
        'conversionRate': 0,
        'clickThroughRate': 0,
        'completionRate': 1,
        'uniqueViewersEstimate': 10,
      }).toDomain();

      expect(stats.completionRate, closeTo(100, 1e-9));
    });
  });
}

/// The shape `GET /v1/creator/analytics/overview` serialises
/// `CreatorAnalyticsOverviewDto` into.
Map<String, dynamic> _overviewJson({
  required double ratio,
  required double priorRatio,
  double? delta,
}) => <String, dynamic>{
  'window': {
    'fromUtc': '2026-08-21T00:00:00Z',
    'toUtc': '2026-09-20T00:00:00Z',
    'durationDays': 30,
  },
  'totalEarnings': {
    'current': {'amount': 24500.0, 'currency': 'NPR'},
    'previous': {'amount': 20000.0, 'currency': 'NPR'},
    'deltaPercent': 22.5,
  },
  'totalSales': {'current': 34, 'previous': 20, 'deltaPercent': 70.0},
  'conversionRate': {
    'current': ratio,
    'previous': priorRatio,
    'deltaPercent': delta,
  },
  'totalViews': {'current': 1000, 'previous': 900, 'deltaPercent': 11.1},
  'pendingBalance': {'amount': 4210.02, 'currency': 'NPR'},
};
