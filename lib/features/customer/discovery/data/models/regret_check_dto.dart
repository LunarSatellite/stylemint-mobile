import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/regret_check.dart';

/// Wire shape of GET `/v1/public/products/{id}/regret-check` — backend
/// `RegretAwareRanking { ProductId, Abstained, RecommendedProductId, Summary,
/// Options[], WindowDays }` with `RegretAssessment` options, camelCase.
/// `level` arrives as the enum int (1 Low, 2 Medium, 3 High, 4 Unknown);
/// string names are tolerated. Options without a product id are dropped.
class RegretCheckDto {
  const RegretCheckDto(this.check);

  factory RegretCheckDto.fromJson(Map<String, dynamic> json) => RegretCheckDto(
    RegretCheck(
      productId: _string(json['productId']),
      abstained: json['abstained'] == true,
      recommendedProductId: _nonBlank(json['recommendedProductId']),
      summary: _string(json['summary']).trim(),
      windowDays: _int(json['windowDays']) ?? 0,
      options: _options(json['options']),
    ),
  );

  final RegretCheck check;

  RegretCheck toDomain() => check;
}

/// Parses the backend `RegretLevel` enum: ints first, then names.
RegretLevel parseRegretLevel(Object? raw) {
  final asInt = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}'.trim());
  if (asInt != null) {
    return switch (asInt) {
      1 => RegretLevel.low,
      2 => RegretLevel.medium,
      3 => RegretLevel.high,
      _ => RegretLevel.unknown,
    };
  }
  return switch ('${raw ?? ''}'.trim().toLowerCase()) {
    'low' => RegretLevel.low,
    'medium' => RegretLevel.medium,
    'high' => RegretLevel.high,
    _ => RegretLevel.unknown,
  };
}

List<RegretOption> _options(Object? raw) {
  if (raw is! List) return const <RegretOption>[];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(
        (e) => RegretOption(
          rank: _int(e['rank']) ?? 0,
          productId: _string(e['productId']),
          productName: _string(e['productName']).trim(),
          // Missing means "not flagged ineligible" — don't dim it.
          eligible: e['eligible'] != false,
          level: parseRegretLevel(e['level']),
          regretScore: _double(e['regretScore']),
          returnRate: _double(e['returnRate']),
          averageRating: _double(e['averageRating']),
          reviewCount: _int(e['reviewCount']) ?? 0,
          reasons:
              (e['reasons'] is List
                      ? e['reasons'] as List
                      : const <Object?>[])
              .whereType<String>()
              .map((r) => r.trim())
              .where((r) => r.isNotEmpty)
              .toList(growable: false),
        ),
      )
      .where((o) => o.productId.isNotEmpty)
      .toList(growable: false);
}

String _string(Object? raw) => raw is String ? raw : '';

String? _nonBlank(Object? raw) =>
    raw is String && raw.trim().isNotEmpty ? raw.trim() : null;

int? _int(Object? raw) =>
    raw is num ? raw.toInt() : (raw is String ? int.tryParse(raw) : null);

double? _double(Object? raw) =>
    raw is num ? raw.toDouble() : (raw is String ? double.tryParse(raw) : null);
