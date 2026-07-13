import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/domain/entities/creator_performance.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

Money _money(Map<String, dynamic>? json) => Money(
  amount: (json?['amount'] as num?)?.toDouble() ?? 0,
  currency: json?['currency'] as String? ?? 'NPR',
);

/// Mirrors `TopCreatorDto` — one item of `VendorCreatorPerformancePageDto`
/// returned by `GET /v1/vendor/analytics/creators` (Vendor §8B).
class CreatorPerformanceDto {
  const CreatorPerformanceDto({
    required this.creatorAccountId,
    required this.unitsSold,
    required this.attributedRevenue,
    required this.commissionPaid,
    required this.distinctReelCount,
  });

  final String creatorAccountId;
  final int unitsSold;
  final Money attributedRevenue;
  final Money commissionPaid;
  final int distinctReelCount;

  factory CreatorPerformanceDto.fromJson(Map<String, dynamic> json) {
    return CreatorPerformanceDto(
      creatorAccountId: json['creatorAccountId'] as String? ?? '',
      unitsSold: (json['unitsSold'] as num?)?.toInt() ?? 0,
      attributedRevenue: _money(
        json['attributedRevenue'] as Map<String, dynamic>?,
      ),
      commissionPaid: _money(json['commissionPaid'] as Map<String, dynamic>?),
      distinctReelCount: (json['distinctReelCount'] as num?)?.toInt() ?? 0,
    );
  }

  CreatorPerformance toDomain() => CreatorPerformance(
    creatorAccountId: creatorAccountId,
    unitsSold: unitsSold,
    attributedRevenue: attributedRevenue,
    commissionPaid: commissionPaid,
    distinctReelCount: distinctReelCount,
  );
}

/// Mirrors `VendorCreatorPerformancePageDto` — `{ window, items[] }`.
class CreatorPerformancePageDto {
  const CreatorPerformancePageDto({required this.items});

  final List<CreatorPerformanceDto> items;

  factory CreatorPerformancePageDto.fromJson(Map<String, dynamic> json) {
    return CreatorPerformancePageDto(
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (e) => CreatorPerformanceDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }
}
