import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/domain/entities/vendor_dashboard.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'vendor_dashboard_dto.freezed.dart';
part 'vendor_dashboard_dto.g.dart';

/// Matches the backend `GET /v1/vendor/analytics/overview` contract (Vendor §8A):
///
/// ```json
/// {
///   "window": { "fromUtc": "...", "toUtc": "...", "durationDays": 30 },
///   "grossSales":  { "current": {Money}, "previous": {Money}, "deltaPercent": null },
///   "netRevenue":  { "current": {Money}, "previous": {Money}, "deltaPercent": null },
///   "conversionRate": { "current": 0, "previous": 0, "deltaPercent": null },
///   "totalOrders":    { "current": 0, "previous": 0, "deltaPercent": null },
///   "revenueTrend": [], "topProducts": [], "topCreators": [], "trafficSources": []
/// }
/// ```
///
/// Every field is nullable/defaulted so a sparse or partial payload (e.g. a
/// brand-new vendor with all zeros, or `deltaPercent: null`) parses cleanly
/// instead of throwing. Unknown keys (`window`, `conversionRate`, `revenueTrend`,
/// `topCreators`, `trafficSources`) are ignored by json_serializable — the
/// dashboard screen doesn't render them yet.
///
/// NOTE: this is *not* the same endpoint as `/v1/vendor/dashboard`, which
/// returns the unrelated Brand Studio `VendorDashboardSnapshot` (creators,
/// reach diagnostics, benchmark, recipes) for the separate Brand Studio screen.

/// `{ amount, currency }` — the standard backend Money shape.
@freezed
abstract class MoneyDto with _$MoneyDto {
  const factory MoneyDto({
    @Default(0) double amount,
    @Default('NPR') String currency,
  }) = _MoneyDto;

  const MoneyDto._();

  factory MoneyDto.fromJson(Map<String, dynamic> json) =>
      _$MoneyDtoFromJson(json);

  Money toDomain() => Money(amount: amount, currency: currency);
}

/// A money metric with current/previous and an optional percent delta.
@freezed
abstract class MoneyDeltaDto with _$MoneyDeltaDto {
  const factory MoneyDeltaDto({
    MoneyDto? current,
    MoneyDto? previous,
    double? deltaPercent,
  }) = _MoneyDeltaDto;

  factory MoneyDeltaDto.fromJson(Map<String, dynamic> json) =>
      _$MoneyDeltaDtoFromJson(json);
}

/// A numeric metric with current/previous and an optional percent delta.
@freezed
abstract class NumberDeltaDto with _$NumberDeltaDto {
  const factory NumberDeltaDto({
    @Default(0) num current,
    @Default(0) num previous,
    double? deltaPercent,
  }) = _NumberDeltaDto;

  factory NumberDeltaDto.fromJson(Map<String, dynamic> json) =>
      _$NumberDeltaDtoFromJson(json);
}

/// An item of `topProducts`:
/// `{ productId, name, thumbnailUrl, unitsSold, totalRevenue, distinctCreatorCount }`.
@freezed
abstract class TopProductDto with _$TopProductDto {
  const factory TopProductDto({
    @Default('') String productId,
    String? name,
    String? thumbnailUrl,
    @Default(0) int unitsSold,
    MoneyDto? totalRevenue,
    @Default(0) int distinctCreatorCount,
  }) = _TopProductDto;

  const TopProductDto._();

  factory TopProductDto.fromJson(Map<String, dynamic> json) =>
      _$TopProductDtoFromJson(json);

  VendorTopProduct toDomain() => VendorTopProduct(
    productId: productId,
    name: name ?? '',
    thumbnailUrl: thumbnailUrl,
    unitsSold: unitsSold,
    totalRevenue: totalRevenue?.toDomain() ?? const Money(amount: 0, currency: 'NPR'),
    distinctCreatorCount: distinctCreatorCount,
  );
}

@freezed
abstract class VendorAnalyticsOverviewDto with _$VendorAnalyticsOverviewDto {
  const factory VendorAnalyticsOverviewDto({
    MoneyDeltaDto? grossSales,
    MoneyDeltaDto? netRevenue,
    NumberDeltaDto? totalOrders,
    @Default(<TopProductDto>[]) List<TopProductDto> topProducts,
  }) = _VendorAnalyticsOverviewDto;

  const VendorAnalyticsOverviewDto._();

  factory VendorAnalyticsOverviewDto.fromJson(Map<String, dynamic> json) =>
      _$VendorAnalyticsOverviewDtoFromJson(json);

  VendorDashboard toDomain() => VendorDashboard(
    grossSales:
        grossSales?.current?.toDomain() ?? const Money(amount: 0, currency: 'NPR'),
    grossSalesDeltaPercent: grossSales?.deltaPercent,
    netRevenue:
        netRevenue?.current?.toDomain() ?? const Money(amount: 0, currency: 'NPR'),
    totalOrders: (totalOrders?.current ?? 0).round(),
    topProducts: topProducts.map((p) => p.toDomain()).toList(growable: false),
  );
}
