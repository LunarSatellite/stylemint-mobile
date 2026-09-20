import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/data/models/analytics_dto.dart';

/// **A vendor converting 3.4 % of reel viewers was told 0.0 %.**
///
/// `VendorAnalyticsService.ComputeConversionRate` returns
/// `ReelAttributedOrderCount / AttributedViewCount` — a ratio in `0..1` —
/// and `KpiTileDto<double>` carries it through the wire untouched.
/// `AnalyticsOverviewDto.toDomain` read it straight into
/// `RevenueOverview.conversionRate`, which `vendor_analytics_screen.dart`
/// renders as `'${conversionRate.toStringAsFixed(1)}%'` on the KPI row and
/// `toStringAsFixed(2)%` in the shared report.
///
/// Every realistic e-commerce conversion rate is under 10 %, so every
/// realistic value printed as **"0.0%"** — the vendor read it as "nobody
/// who watched a reel ever bought", which is a claim, not a blank. The
/// shared report carried the same "0.00%" out of the app to whoever the
/// vendor sent it to.
///
/// Asserted over the parsed value and the strings the screens build from
/// it, not over source text.
void main() {
  test('a 3.4 % conversion survives parsing as 3.4, not 0.034', () {
    final overview = AnalyticsOverviewDto.fromJson(
      _overviewJson(conversionRatio: 0.034),
    ).toDomain();

    expect(overview.conversionRate, closeTo(3.4, 1e-9));
    // What the KPI row prints.
    expect('${overview.conversionRate.toStringAsFixed(1)}%', '3.4%');
    // What the shared report prints.
    expect('${overview.conversionRate.toStringAsFixed(2)}%', '3.40%');
  });

  test('a thin but real 0.8 % conversion does not round away to nothing', () {
    final overview = AnalyticsOverviewDto.fromJson(
      _overviewJson(conversionRatio: 0.008),
    ).toDomain();

    expect(overview.conversionRate, closeTo(0.8, 1e-9));
    expect('${overview.conversionRate.toStringAsFixed(1)}%', '0.8%');
  });

  test('a genuine zero still reads as zero', () {
    final overview = AnalyticsOverviewDto.fromJson(
      _overviewJson(conversionRatio: 0),
    ).toDomain();

    expect(overview.conversionRate, 0);
  });

  test('a perfect 1.0 ratio is a hundred percent, not one', () {
    final overview = AnalyticsOverviewDto.fromJson(
      _overviewJson(conversionRatio: 1),
    ).toDomain();

    expect(overview.conversionRate, closeTo(100, 1e-9));
  });

  test('the delta badge is left alone — it is already a percentage', () {
    final overview = AnalyticsOverviewDto.fromJson(
      _overviewJson(conversionRatio: 0.034, deltaPercent: 12.4),
    ).toDomain();

    expect(overview.conversionRateBadge, '+12%');
  });

  test('money tiles are not scaled by the conversion fix', () {
    final overview = AnalyticsOverviewDto.fromJson(
      _overviewJson(conversionRatio: 0.034),
    ).toDomain();

    expect(overview.grossSales, 100000);
    expect(overview.netRevenue, 90000);
  });
}

/// The shape `GET /v1/vendor/analytics/overview` serialises
/// `VendorAnalyticsOverviewDto` into.
Map<String, dynamic> _overviewJson({
  required double conversionRatio,
  double? deltaPercent,
}) => <String, dynamic>{
  'grossSales': {
    'current': {'amount': 100000, 'currency': 'NPR'},
    'previous': {'amount': 90000, 'currency': 'NPR'},
    'deltaPercent': null,
  },
  'netRevenue': {
    'current': {'amount': 90000, 'currency': 'NPR'},
    'previous': {'amount': 81000, 'currency': 'NPR'},
    'deltaPercent': null,
  },
  'conversionRate': {
    'current': conversionRatio,
    'previous': conversionRatio,
    'deltaPercent': deltaPercent,
  },
  'totalOrders': {'current': 12, 'previous': 10, 'deltaPercent': 20.0},
};
