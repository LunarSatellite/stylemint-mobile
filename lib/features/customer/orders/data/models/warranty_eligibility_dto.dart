import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/warranty_eligibility.dart';

/// `GET v1/warranties/orders/{orderNumber}/eligibility` — backend
/// `WarrantyEligibilityDto`.
///
/// Every nullable date here stays nullable all the way to the screen. A
/// missing coverage start is a fact about what was recorded, and the one thing
/// this layer must never do is invent a substitute for it.
class WarrantyEligibilityDto {
  const WarrantyEligibilityDto({
    required this.orderNumber,
    required this.items,
    this.generatedUtc,
  });

  factory WarrantyEligibilityDto.fromJson(Map<String, dynamic> json) =>
      WarrantyEligibilityDto(
        orderNumber: json['orderNumber']?.toString() ?? '',
        generatedUtc: _date(json['generatedUtc']),
        items: (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(WarrantyEligibilityItemDto.fromJson)
            .toList(growable: false),
      );

  final String orderNumber;
  final DateTime? generatedUtc;
  final List<WarrantyEligibilityItemDto> items;

  WarrantyEligibility toDomain() => WarrantyEligibility(
    orderNumber: orderNumber,
    generatedUtc: generatedUtc,
    items: items.map((item) => item.toDomain()).toList(growable: false),
  );
}

class WarrantyEligibilityItemDto {
  const WarrantyEligibilityItemDto({
    required this.subOrderId,
    required this.subOrderLineId,
    required this.productVariantId,
    required this.title,
    required this.isEligible,
    required this.statusExplanation,
    required this.hasOpenClaim,
    required this.units,
    this.variantLabel,
    this.thumbnailUrl,
    this.coverageDays,
    this.terms,
    this.coverageStartsUtc,
    this.coverageEndsUtc,
  });

  factory WarrantyEligibilityItemDto.fromJson(Map<String, dynamic> json) =>
      WarrantyEligibilityItemDto(
        subOrderId: json['subOrderId']?.toString() ?? '',
        subOrderLineId: json['subOrderLineId']?.toString() ?? '',
        productVariantId: json['productVariantId']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        variantLabel: _text(json['variantLabel']),
        thumbnailUrl: _text(json['thumbnailUrl']),
        isEligible: json['isEligible'] == true,
        statusExplanation: json['statusExplanation']?.toString() ?? '',
        hasOpenClaim: json['hasOpenClaim'] == true,
        coverageDays: _int(json['coverageDays']),
        terms: _text(json['terms']),
        coverageStartsUtc: _date(json['coverageStartsUtc']),
        coverageEndsUtc: _date(json['coverageEndsUtc']),
        // Absent, null and [] all mean the same thing: this line carries no
        // marker, so its warranty is a line-level warranty.
        units: (json['units'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(WarrantyUnitEligibilityDto.fromJson)
            .toList(growable: false),
      );

  final String subOrderId;
  final String subOrderLineId;
  final String productVariantId;
  final String title;
  final String? variantLabel;
  final String? thumbnailUrl;
  final bool isEligible;
  final String statusExplanation;
  final bool hasOpenClaim;
  final int? coverageDays;
  final String? terms;
  final DateTime? coverageStartsUtc;
  final DateTime? coverageEndsUtc;
  final List<WarrantyUnitEligibilityDto> units;

  WarrantyEligibilityItem toDomain() => WarrantyEligibilityItem(
    subOrderId: subOrderId,
    subOrderLineId: subOrderLineId,
    productVariantId: productVariantId,
    title: title,
    variantLabel: variantLabel,
    thumbnailUrl: thumbnailUrl,
    isEligible: isEligible,
    statusExplanation: statusExplanation,
    hasOpenClaim: hasOpenClaim,
    coverageDays: coverageDays,
    terms: terms,
    coverageStartsUtc: coverageStartsUtc,
    coverageEndsUtc: coverageEndsUtc,
    units: units.map((unit) => unit.toDomain()).toList(growable: false),
  );
}

class WarrantyUnitEligibilityDto {
  const WarrantyUnitEligibilityDto({
    required this.unitMarkerBindingId,
    required this.markerReference,
    required this.isEligible,
    required this.statusExplanation,
    required this.hasOpenClaim,
    this.inServiceSinceUtc,
    this.coverageStartsUtc,
    this.coverageEndsUtc,
    this.clockBasis,
  });

  factory WarrantyUnitEligibilityDto.fromJson(Map<String, dynamic> json) =>
      WarrantyUnitEligibilityDto(
        unitMarkerBindingId: json['unitMarkerBindingId']?.toString() ?? '',
        markerReference: json['markerReference']?.toString() ?? '',
        inServiceSinceUtc: _date(json['inServiceSinceUtc']),
        isEligible: json['isEligible'] == true,
        statusExplanation: json['statusExplanation']?.toString() ?? '',
        hasOpenClaim: json['hasOpenClaim'] == true,
        coverageStartsUtc: _date(json['coverageStartsUtc']),
        coverageEndsUtc: _date(json['coverageEndsUtc']),
        clockBasis: WarrantyClockBasis.fromJson(json['clockBasis']),
      );

  final String unitMarkerBindingId;
  final String markerReference;
  final DateTime? inServiceSinceUtc;
  final bool isEligible;
  final String statusExplanation;
  final bool hasOpenClaim;
  final DateTime? coverageStartsUtc;
  final DateTime? coverageEndsUtc;
  final WarrantyClockBasis? clockBasis;

  WarrantyUnitEligibility toDomain() => WarrantyUnitEligibility(
    unitMarkerBindingId: unitMarkerBindingId,
    markerReference: markerReference,
    inServiceSinceUtc: inServiceSinceUtc,
    isEligible: isEligible,
    statusExplanation: statusExplanation,
    hasOpenClaim: hasOpenClaim,
    coverageStartsUtc: coverageStartsUtc,
    coverageEndsUtc: coverageEndsUtc,
    clockBasis: clockBasis,
  );
}

/// An unparseable or absent date stays null. There is no epoch fallback here
/// on purpose: rendering 1 January 1970 as a coverage start would be a
/// fabricated fact, which is worse than an empty space.
DateTime? _date(Object? raw) {
  final value = raw?.toString();
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

int? _int(Object? raw) =>
    raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');

String? _text(Object? raw) {
  final value = raw?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}
