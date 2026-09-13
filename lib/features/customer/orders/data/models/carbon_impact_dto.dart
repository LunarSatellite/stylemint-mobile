import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/carbon_impact.dart';

/// Wire shape of GET `/v1/customer/delivery/carbon-impact` — backend
/// `CarbonSavingsDto { KgCO2Saved, DeliveryCount, ComparedToTraditionalKg }`
/// serialized camelCase (`kgCO2Saved`, `deliveryCount`,
/// `comparedToTraditionalKg`). Missing fields default to zero so a partial
/// payload degrades to "nothing to show" rather than a parse failure.
class CarbonImpactDto {
  const CarbonImpactDto({
    required this.kgCo2Saved,
    required this.deliveryCount,
    required this.comparedToTraditionalKg,
  });

  factory CarbonImpactDto.fromJson(Map<String, dynamic> json) =>
      CarbonImpactDto(
        kgCo2Saved:
            ((json['kgCO2Saved'] ?? json['kgCo2Saved']) as num?)?.toDouble() ??
            0,
        deliveryCount: (json['deliveryCount'] as num?)?.toInt() ?? 0,
        comparedToTraditionalKg:
            (json['comparedToTraditionalKg'] as num?)?.toDouble() ?? 0,
      );

  final double kgCo2Saved;
  final int deliveryCount;
  final double comparedToTraditionalKg;

  CarbonImpact toDomain() => CarbonImpact(
    kgCo2Saved: kgCo2Saved,
    deliveryCount: deliveryCount,
    comparedToTraditionalKg: comparedToTraditionalKg,
  );
}
