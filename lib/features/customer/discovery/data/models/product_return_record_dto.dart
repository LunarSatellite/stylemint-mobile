import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_return_record.dart';

/// Wire shape of `GET /v1/public/products/{id}/return-record` — backend
/// `ProductReturnRecord { ProductId, CategoryId, WindowDays, OrderingApplied,
/// OrderingSkippedReason, Basis, Options[] }`, camelCase.
///
/// `comparedWithCategory` arrives as the enum *name* (the server pins
/// `JsonStringEnumConverter`); ints are tolerated for older builds. Anything
/// this app does not recognise becomes [CategoryComparison.unknown] rather
/// than being coerced into a middle value — an unfamiliar comparison must
/// disappear, not land on "about typical".
///
/// Rates are read only when their denominator survived the parse, so a
/// malformed payload cannot produce a percentage with nothing behind it.
class ProductReturnRecordDto {
  const ProductReturnRecordDto(this.record);

  factory ProductReturnRecordDto.fromJson(Map<String, dynamic> json) =>
      ProductReturnRecordDto(
        ProductReturnRecord(
          productId: _string(json['productId']),
          categoryId: _string(json['categoryId']),
          windowDays: _int(json['windowDays']) ?? 0,
          orderingApplied: json['orderingApplied'] == true,
          orderingSkippedReason: _nonBlank(json['orderingSkippedReason']),
          basis: _basis(json['basis']),
          options: _options(json['options']),
        ),
      );

  final ProductReturnRecord record;

  ProductReturnRecord toDomain() => record;
}

/// Parses the backend `CategoryComparison`: names first, then ints.
CategoryComparison parseCategoryComparison(Object? raw) {
  final name = '${raw ?? ''}'.trim().toLowerCase();
  switch (name) {
    case 'notenoughdata':
      return CategoryComparison.notEnoughData;
    case 'belowcategorytypical':
      return CategoryComparison.belowCategoryTypical;
    case 'aboutcategorytypical':
      return CategoryComparison.aboutCategoryTypical;
    case 'abovecategorytypical':
      return CategoryComparison.aboveCategoryTypical;
  }
  final asInt = raw is num ? raw.toInt() : int.tryParse(name);
  return switch (asInt) {
    0 => CategoryComparison.notEnoughData,
    1 => CategoryComparison.belowCategoryTypical,
    2 => CategoryComparison.aboutCategoryTypical,
    3 => CategoryComparison.aboveCategoryTypical,
    _ => CategoryComparison.unknown,
  };
}

CategoryReturnBasis _basis(Object? raw) {
  final map = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
  final unitsSold = _int(map['unitsSold']) ?? 0;
  final available = map['available'] == true;
  return CategoryReturnBasis(
    categoryId: _string(map['categoryId']),
    available: available,
    unavailableReason: _nonBlank(map['unavailableReason']),
    productsCounted: _int(map['productsCounted']) ?? 0,
    unitsSold: unitsSold,
    unitsReturned: _int(map['unitsReturned']) ?? 0,
    // A rate without a denominator is exactly what this capability exists to
    // refuse, so it is dropped here rather than guarded at every render.
    returnsPerHundredSold: available && unitsSold > 0
        ? _int(map['returnsPerHundredSold'])
        : null,
  );
}

List<ProductReturnOption> _options(Object? raw) {
  if (raw is! List) return const <ProductReturnOption>[];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(_option)
      .where((o) => o.productId.isNotEmpty)
      .toList(growable: false);
}

ProductReturnOption _option(Map<String, dynamic> json) {
  final unitsSold = _int(json['unitsSold']) ?? 0;
  final hasEnoughSales = json['hasEnoughSales'] == true;
  return ProductReturnOption(
    position: _int(json['position']) ?? 0,
    suppliedPosition: _int(json['suppliedPosition']) ?? 0,
    productId: _string(json['productId']),
    productName: _string(json['productName']).trim(),
    hasEnoughSales: hasEnoughSales,
    unitsSold: unitsSold,
    unitsReturned: _int(json['unitsReturned']) ?? 0,
    returnsPerHundredSold: hasEnoughSales && unitsSold > 0
        ? _int(json['returnsPerHundredSold'])
        : null,
    comparedWithCategory: parseCategoryComparison(json['comparedWithCategory']),
    returnedUnits: _split(json['returnedUnits']),
    facts: _facts(json['facts']),
  );
}

/// Absent, or short of its own counts, means "not classified" — never a row
/// of zeros.
ReturnedUnitSplit? _split(Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  final classified = _int(raw['classifiedReturns']);
  final fit = _int(raw['fitToResell']);
  final notFit = _int(raw['notFitToResell']);
  if (classified == null || fit == null || notFit == null) return null;
  if (classified <= 0) return null;
  return ReturnedUnitSplit(
    classifiedReturns: classified,
    fitToResell: fit,
    notFitToResell: notFit,
  );
}

List<String> _facts(Object? raw) =>
    (raw is List ? raw : const <Object?>[])
        .whereType<String>()
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList(growable: false);

String _string(Object? raw) => raw is String ? raw : '';

String? _nonBlank(Object? raw) =>
    raw is String && raw.trim().isNotEmpty ? raw.trim() : null;

int? _int(Object? raw) =>
    raw is num ? raw.toInt() : (raw is String ? int.tryParse(raw) : null);
