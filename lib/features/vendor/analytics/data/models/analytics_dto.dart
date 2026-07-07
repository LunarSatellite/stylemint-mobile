import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/domain/entities/vendor_analytics_summary.dart';

// ---------------------------------------------------------------------------
// Matches the backend `GET /v1/vendor/analytics/overview` contract (Vendor
// §8A) — a single round-trip composite. Every field below comes from that one
// response.
//
// NOTE: this datasource previously fired four additional requests
// (`/v1/vendor/analytics/earnings`, `/top-products`, `/top-creators`,
// `/traffic-sources`) that don't exist on the backend — any 404 among them
// failed the whole `Future.wait`, which is why the screen always showed
// "Failed to load analytics." `revenueTrend`, `topProducts`, `topCreators`
// and `trafficSources` are all embedded fields on the overview response.
// ---------------------------------------------------------------------------

class MoneyDto {
  const MoneyDto({required this.amount, this.currency = 'NPR'});

  factory MoneyDto.fromJson(Map<String, dynamic>? json) => MoneyDto(
    amount: (json?['amount'] as num?)?.toDouble() ?? 0,
    currency: json?['currency'] as String? ?? 'NPR',
  );

  final double amount;
  final String currency;
}

class MoneyDeltaDto {
  const MoneyDeltaDto({this.current, this.deltaPercent});

  factory MoneyDeltaDto.fromJson(Map<String, dynamic>? json) => MoneyDeltaDto(
    current: json?['current'] == null
        ? null
        : MoneyDto.fromJson(json!['current'] as Map<String, dynamic>),
    deltaPercent: (json?['deltaPercent'] as num?)?.toDouble(),
  );

  final MoneyDto? current;
  final double? deltaPercent;
}

class NumberDeltaDto {
  const NumberDeltaDto({this.current = 0, this.deltaPercent});

  factory NumberDeltaDto.fromJson(Map<String, dynamic>? json) => NumberDeltaDto(
    current: (json?['current'] as num?) ?? 0,
    deltaPercent: (json?['deltaPercent'] as num?)?.toDouble(),
  );

  final num current;
  final double? deltaPercent;
}

/// "+23%" / "-5%" / "" (no baseline yet) — the backend sends a raw
/// `deltaPercent`, not a display string.
String _formatBadge(double? deltaPercent) {
  if (deltaPercent == null) return '';
  final r = deltaPercent.round();
  return '${r >= 0 ? '+' : ''}$r%';
}

// ---------------------------------------------------------------------------
// Revenue overview (`grossSales`, `netRevenue`, `conversionRate`, `totalOrders`)
// ---------------------------------------------------------------------------

class AnalyticsOverviewDto {
  const AnalyticsOverviewDto({
    required this.grossSales,
    required this.netRevenue,
    required this.conversionRate,
    required this.totalOrders,
  });

  factory AnalyticsOverviewDto.fromJson(Map<String, dynamic> json) =>
      AnalyticsOverviewDto(
        grossSales: MoneyDeltaDto.fromJson(
          json['grossSales'] as Map<String, dynamic>?,
        ),
        netRevenue: MoneyDeltaDto.fromJson(
          json['netRevenue'] as Map<String, dynamic>?,
        ),
        conversionRate: NumberDeltaDto.fromJson(
          json['conversionRate'] as Map<String, dynamic>?,
        ),
        totalOrders: NumberDeltaDto.fromJson(
          json['totalOrders'] as Map<String, dynamic>?,
        ),
      );

  final MoneyDeltaDto grossSales;
  final MoneyDeltaDto netRevenue;
  final NumberDeltaDto conversionRate;
  final NumberDeltaDto totalOrders;

  RevenueOverview toDomain() => RevenueOverview(
    grossSales: grossSales.current?.amount ?? 0,
    grossSalesBadge: _formatBadge(grossSales.deltaPercent),
    netRevenue: netRevenue.current?.amount ?? 0,
    netRevenueBadge: _formatBadge(netRevenue.deltaPercent),
    conversionRate: conversionRate.current.toDouble(),
    conversionRateBadge: _formatBadge(conversionRate.deltaPercent),
    totalOrders: totalOrders.current.round(),
    totalOrdersBadge: _formatBadge(totalOrders.deltaPercent),
    currency: grossSales.current?.currency ?? 'NPR',
  );
}

// ---------------------------------------------------------------------------
// Earnings chart point — from `revenueTrend[]`: `{ date, amount }`
// ---------------------------------------------------------------------------

class EarningsPointDto {
  const EarningsPointDto({required this.date, required this.amount});

  factory EarningsPointDto.fromJson(Map<String, dynamic> json) =>
      EarningsPointDto(
        date: DateTime.parse(json['date'] as String),
        amount: MoneyDto.fromJson(json['amount'] as Map<String, dynamic>?),
      );

  final DateTime date;
  final MoneyDto amount;

  EarningsPoint toDomain() => EarningsPoint(
    label: DateFormat('d MMM').format(date),
    value: amount.amount,
  );
}

// ---------------------------------------------------------------------------
// Top product — from `topProducts[]`: `{ productId, name, thumbnailUrl,
// unitsSold, totalRevenue, distinctCreatorCount }`. The backend doesn't send
// a per-unit price or an explicit rank; rank is the list position.
// ---------------------------------------------------------------------------

class AnalyticsTopProductDto {
  const AnalyticsTopProductDto({
    required this.productId,
    this.name,
    this.thumbnailUrl,
    required this.unitsSold,
    required this.totalRevenue,
  });

  factory AnalyticsTopProductDto.fromJson(Map<String, dynamic> json) =>
      AnalyticsTopProductDto(
        productId: json['productId'] as String? ?? '',
        name: json['name'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        unitsSold: json['unitsSold'] as int? ?? 0,
        totalRevenue: MoneyDto.fromJson(
          json['totalRevenue'] as Map<String, dynamic>?,
        ),
      );

  final String productId;
  final String? name;
  final String? thumbnailUrl;
  final int unitsSold;
  final MoneyDto totalRevenue;

  /// NOTE: `TopProduct.price` holds this window's `totalRevenue`, not a
  /// per-unit price — the backend doesn't return one.
  TopProduct toDomain(int rank) => TopProduct(
    rank: rank,
    productId: productId,
    name: (name?.isNotEmpty ?? false) ? name! : 'Unnamed product',
    price: totalRevenue.amount,
    currency: totalRevenue.currency,
    unitsSold: unitsSold,
    imageUrl: thumbnailUrl,
  );
}

// ---------------------------------------------------------------------------
// Top creator — from `topCreators[]`: `{ creatorAccountId, unitsSold,
// attributedRevenue, commissionPaid, distinctReelCount }`. No handle/display
// name yet (creator identity lookup isn't wired server-side).
// ---------------------------------------------------------------------------

class AnalyticsTopCreatorDto {
  const AnalyticsTopCreatorDto({
    required this.creatorAccountId,
    required this.attributedRevenue,
    required this.distinctReelCount,
  });

  factory AnalyticsTopCreatorDto.fromJson(Map<String, dynamic> json) =>
      AnalyticsTopCreatorDto(
        creatorAccountId: json['creatorAccountId'] as String? ?? '',
        attributedRevenue: MoneyDto.fromJson(
          json['attributedRevenue'] as Map<String, dynamic>?,
        ),
        distinctReelCount: json['distinctReelCount'] as int? ?? 0,
      );

  final String creatorAccountId;
  final MoneyDto attributedRevenue;
  final int distinctReelCount;

  TopCreatorSummary toDomain(int rank) => TopCreatorSummary(
    rank: rank,
    creatorAccountId: creatorAccountId,
    attributedRevenue: attributedRevenue.amount,
    currency: attributedRevenue.currency,
    distinctReelCount: distinctReelCount,
  );
}

// ---------------------------------------------------------------------------
// Traffic source — from `trafficSources[]`: `{ platform, percent }`
// ---------------------------------------------------------------------------

class AnalyticsTrafficSourceDto {
  const AnalyticsTrafficSourceDto({
    required this.platform,
    required this.percent,
  });

  factory AnalyticsTrafficSourceDto.fromJson(Map<String, dynamic> json) =>
      AnalyticsTrafficSourceDto(
        platform: json['platform'] as String? ?? '',
        percent: (json['percent'] as num?)?.toDouble() ?? 0,
      );

  final String platform;
  final double percent;

  TrafficSource toDomain() =>
      TrafficSource(platform: platform, percentage: percent);
}

// ---------------------------------------------------------------------------
// Aggregate DTO — the whole `/v1/vendor/analytics/overview` response body.
// ---------------------------------------------------------------------------

class VendorAnalyticsSummaryDto {
  const VendorAnalyticsSummaryDto({
    required this.overview,
    required this.revenueTrend,
    required this.topProducts,
    required this.topCreators,
    required this.trafficSources,
  });

  factory VendorAnalyticsSummaryDto.fromJson(Map<String, dynamic> json) =>
      VendorAnalyticsSummaryDto(
        overview: AnalyticsOverviewDto.fromJson(json),
        revenueTrend: (json['revenueTrend'] as List<dynamic>? ?? [])
            .map((e) => EarningsPointDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        topProducts: (json['topProducts'] as List<dynamic>? ?? [])
            .map(
              (e) => AnalyticsTopProductDto.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        topCreators: (json['topCreators'] as List<dynamic>? ?? [])
            .map(
              (e) => AnalyticsTopCreatorDto.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        trafficSources: (json['trafficSources'] as List<dynamic>? ?? [])
            .map(
              (e) =>
                  AnalyticsTrafficSourceDto.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );

  final AnalyticsOverviewDto overview;
  final List<EarningsPointDto> revenueTrend;
  final List<AnalyticsTopProductDto> topProducts;
  final List<AnalyticsTopCreatorDto> topCreators;
  final List<AnalyticsTrafficSourceDto> trafficSources;

  VendorAnalyticsSummary toDomain() => VendorAnalyticsSummary(
    revenueOverview: overview.toDomain(),
    earningsPoints: revenueTrend.map((e) => e.toDomain()).toList(),
    topProducts: topProducts
        .asMap()
        .entries
        .map((e) => e.value.toDomain(e.key + 1))
        .toList(),
    topCreators: topCreators
        .asMap()
        .entries
        .map((e) => e.value.toDomain(e.key + 1))
        .toList(),
    trafficSources: trafficSources.map((e) => e.toDomain()).toList(),
  );
}
