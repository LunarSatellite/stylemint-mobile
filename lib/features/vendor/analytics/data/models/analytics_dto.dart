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

// ---------------------------------------------------------------------------
// Creator deep dive — `GET /v1/vendor/partnerships/{partnershipId}/
// creator-analytics`. Unlike the overview's `topCreators`, this endpoint's
// `header` does carry `displayName`/`avatarUrl`.
// ---------------------------------------------------------------------------

KpiTile<double> _moneyKpiTile(Map<String, dynamic>? json) => KpiTile<double>(
  current: MoneyDto.fromJson(json?['current'] as Map<String, dynamic>?).amount,
  deltaPercent: (json?['deltaPercent'] as num?)?.toDouble(),
);

KpiTile<int> _numberKpiTile(Map<String, dynamic>? json) => KpiTile<int>(
  current: (json?['current'] as num?)?.toInt() ?? 0,
  deltaPercent: (json?['deltaPercent'] as num?)?.toDouble(),
);

class DeepDiveRevenuePointDto {
  const DeepDiveRevenuePointDto({required this.date, required this.amount});

  factory DeepDiveRevenuePointDto.fromJson(Map<String, dynamic> json) =>
      DeepDiveRevenuePointDto(
        date: DateTime.parse(json['date'] as String),
        amount: MoneyDto.fromJson(json['amount'] as Map<String, dynamic>?),
      );

  final DateTime date;
  final MoneyDto amount;

  DeepDiveRevenuePoint toDomain() =>
      DeepDiveRevenuePoint(date: date, amount: amount.amount);
}

class DeepDiveTopProductDto {
  const DeepDiveTopProductDto({
    required this.productId,
    required this.name,
    required this.unitsSold,
    required this.totalRevenue,
    required this.distinctCreatorCount,
    this.thumbnailUrl,
  });

  factory DeepDiveTopProductDto.fromJson(Map<String, dynamic> json) =>
      DeepDiveTopProductDto(
        productId: json['productId'] as String? ?? '',
        name: json['name'] as String? ?? 'Unnamed product',
        thumbnailUrl: json['thumbnailUrl'] as String?,
        unitsSold: json['unitsSold'] as int? ?? 0,
        totalRevenue: MoneyDto.fromJson(
          json['totalRevenue'] as Map<String, dynamic>?,
        ),
        distinctCreatorCount: json['distinctCreatorCount'] as int? ?? 0,
      );

  final String productId;
  final String name;
  final String? thumbnailUrl;
  final int unitsSold;
  final MoneyDto totalRevenue;
  final int distinctCreatorCount;

  DeepDiveTopProduct toDomain() => DeepDiveTopProduct(
    productId: productId,
    name: name,
    thumbnailUrl: thumbnailUrl,
    unitsSold: unitsSold,
    totalRevenue: totalRevenue.amount,
    distinctCreatorCount: distinctCreatorCount,
  );
}

class DeepDiveTopReelDto {
  const DeepDiveTopReelDto({
    required this.reelId,
    required this.sourcePlatform,
    required this.externalUrl,
    required this.viewCount,
    required this.unitsSold,
    required this.attributedRevenue,
    this.caption,
  });

  factory DeepDiveTopReelDto.fromJson(Map<String, dynamic> json) =>
      DeepDiveTopReelDto(
        reelId: json['reelId'] as String? ?? '',
        sourcePlatform: json['sourcePlatform'] as String? ?? '',
        externalUrl: json['externalUrl'] as String? ?? '',
        caption: json['caption'] as String?,
        viewCount: json['viewCount'] as int? ?? 0,
        unitsSold: json['unitsSold'] as int? ?? 0,
        attributedRevenue: MoneyDto.fromJson(
          json['attributedRevenue'] as Map<String, dynamic>?,
        ),
      );

  final String reelId;
  final String sourcePlatform;
  final String externalUrl;
  final String? caption;
  final int viewCount;
  final int unitsSold;
  final MoneyDto attributedRevenue;

  DeepDiveTopReel toDomain() => DeepDiveTopReel(
    reelId: reelId,
    sourcePlatform: sourcePlatform,
    externalUrl: externalUrl,
    caption: caption,
    viewCount: viewCount,
    unitsSold: unitsSold,
    attributedRevenue: attributedRevenue.amount,
  );
}

class CreatorAnalyticsDeepDiveDto {
  const CreatorAnalyticsDeepDiveDto({
    required this.partnershipId,
    required this.creatorAccountId,
    required this.commissionMinPercent,
    required this.commissionMaxPercent,
    required this.attributedRevenue,
    required this.unitsSold,
    required this.commissionPaid,
    required this.distinctReelCount,
    required this.revenueTrend,
    required this.topProducts,
    required this.topReels,
    required this.currency,
    this.displayName,
    this.avatarUrl,
  });

  factory CreatorAnalyticsDeepDiveDto.fromJson(Map<String, dynamic> json) {
    final header = json['header'] as Map<String, dynamic>? ?? const {};
    final attributedRevenueJson =
        json['attributedRevenue'] as Map<String, dynamic>?;
    return CreatorAnalyticsDeepDiveDto(
      partnershipId: header['partnershipId'] as String? ?? '',
      creatorAccountId: header['creatorAccountId'] as String? ?? '',
      displayName: header['displayName'] as String?,
      avatarUrl: header['avatarUrl'] as String?,
      commissionMinPercent:
          (header['commissionMinPercent'] as num?)?.toDouble() ?? 0,
      commissionMaxPercent:
          (header['commissionMaxPercent'] as num?)?.toDouble() ?? 0,
      attributedRevenue: _moneyKpiTile(attributedRevenueJson),
      unitsSold: _numberKpiTile(json['unitsSold'] as Map<String, dynamic>?),
      commissionPaid: _moneyKpiTile(
        json['commissionPaid'] as Map<String, dynamic>?,
      ),
      distinctReelCount: _numberKpiTile(
        json['distinctReelCount'] as Map<String, dynamic>?,
      ),
      revenueTrend: (json['revenueTrend'] as List<dynamic>? ?? [])
          .map(
            (e) => DeepDiveRevenuePointDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      topProducts: (json['topProducts'] as List<dynamic>? ?? [])
          .map(
            (e) => DeepDiveTopProductDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      topReels: (json['topReels'] as List<dynamic>? ?? [])
          .map((e) => DeepDiveTopReelDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      currency: MoneyDto.fromJson(
        attributedRevenueJson?['current'] as Map<String, dynamic>?,
      ).currency,
    );
  }

  final String partnershipId;
  final String creatorAccountId;
  final String? displayName;
  final String? avatarUrl;
  final double commissionMinPercent;
  final double commissionMaxPercent;
  final KpiTile<double> attributedRevenue;
  final KpiTile<int> unitsSold;
  final KpiTile<double> commissionPaid;
  final KpiTile<int> distinctReelCount;
  final List<DeepDiveRevenuePointDto> revenueTrend;
  final List<DeepDiveTopProductDto> topProducts;
  final List<DeepDiveTopReelDto> topReels;
  final String currency;

  CreatorAnalyticsDeepDive toDomain() => CreatorAnalyticsDeepDive(
    partnershipId: partnershipId,
    creatorAccountId: creatorAccountId,
    displayName: displayName,
    avatarUrl: avatarUrl,
    commissionMinPercent: commissionMinPercent,
    commissionMaxPercent: commissionMaxPercent,
    attributedRevenue: attributedRevenue,
    unitsSold: unitsSold,
    commissionPaid: commissionPaid,
    distinctReelCount: distinctReelCount,
    revenueTrend: revenueTrend.map((e) => e.toDomain()).toList(),
    topProducts: topProducts.map((e) => e.toDomain()).toList(),
    topReels: topReels.map((e) => e.toDomain()).toList(),
    currency: currency,
  );
}
