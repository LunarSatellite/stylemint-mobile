import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/domain/entities/creator_dashboard.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'creator_dashboard_dto.freezed.dart';
part 'creator_dashboard_dto.g.dart';

/// Matches the backend `GET /v1/creator/analytics/dashboard` contract:
///
/// ```json
/// {
///   "window": { "fromUtc": "...", "toUtc": "...", "durationDays": 30 },
///   "totalEarnings": { "current": {Money}, "previous": {Money}, "deltaPercent": null },
///   "pendingBalance": {Money},
///   "totalSales":     { "current": 0, "previous": 0, "deltaPercent": null },
///   "totalViews":     { "current": 0, "previous": 0, "deltaPercent": null },
///   "conversionRate": { "current": 0, "previous": 0, "deltaPercent": null },
///   "topReels": [], "topProducts": []
/// }
/// ```
///
/// Every field is nullable/defaulted so a sparse or partial payload (e.g. a
/// brand-new creator with all zeros, or `deltaPercent: null`) parses cleanly
/// instead of throwing. Unknown keys (`window`, `conversionRate`, `topProducts`)
/// are ignored by json_serializable.

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

/// An item of `topReels`:
/// `{ reelId, title, thumbnailUrl, publishedAtUtc, views, likes, impressions,
///    shares, comments, sales, earnings }`.
/// Fields are tolerant (defaulted/nullable) so a partial item never crashes the
/// dashboard. `earnings` is intentionally not modelled (unconfirmed type, not
/// rendered) — json_serializable ignores the unknown key.
@freezed
abstract class CreatorReelDto with _$CreatorReelDto {
  const factory CreatorReelDto({
    @Default('') String reelId,
    @Default('') String title,
    @Default('') String thumbnailUrl,
    DateTime? publishedAtUtc,
    @Default(0) int views,
    @Default(0) int likes,
    @Default(0) int comments,
    @Default(0) int shares,
    @Default(0) int impressions,
    @Default(0) int sales,
  }) = _CreatorReelDto;

  const CreatorReelDto._();

  factory CreatorReelDto.fromJson(Map<String, dynamic> json) =>
      _$CreatorReelDtoFromJson(json);

  CreatorReel toDomain() => CreatorReel(
    id: reelId,
    title: title,
    thumbnailUrl: thumbnailUrl,
    publishedAt:
        publishedAtUtc ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    views: views,
    likes: likes,
    comments: comments,
    shares: shares,
  );
}

@freezed
abstract class CreatorDashboardDto with _$CreatorDashboardDto {
  const factory CreatorDashboardDto({
    MoneyDeltaDto? totalEarnings,
    MoneyDto? pendingBalance,
    NumberDeltaDto? totalSales,
    NumberDeltaDto? totalViews,
    @Default(<CreatorReelDto>[]) List<CreatorReelDto> topReels,
  }) = _CreatorDashboardDto;

  const CreatorDashboardDto._();

  factory CreatorDashboardDto.fromJson(Map<String, dynamic> json) =>
      _$CreatorDashboardDtoFromJson(json);

  CreatorDashboard toDomain() => CreatorDashboard(
    earnings: totalEarnings?.current?.toDomain() ??
        const Money(amount: 0, currency: 'NPR'),
    earningsDeltaPercent: totalEarnings?.deltaPercent,
    pendingBalance:
        pendingBalance?.toDomain() ?? const Money(amount: 0, currency: 'NPR'),
    totalSales: (totalSales?.current ?? 0).round(),
    totalViews: (totalViews?.current ?? 0).round(),
    topReels: topReels.map((r) => r.toDomain()).toList(growable: false),
  );
}
