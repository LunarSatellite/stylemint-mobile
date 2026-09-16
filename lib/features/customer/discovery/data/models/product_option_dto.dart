import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_option.dart';

/// The size/colour chooser fields of `GET v1/public/products/{id}`
/// (catalog contract §8), hand-written because the freezed `ProductDetailDto`
/// does not map them. List and card rows deliberately send `options: []` and
/// a null `optionLabel`, so this parses to empty there and the product page
/// keeps its existing single-variant behaviour.
class ProductOptionsDto {
  const ProductOptionsDto({
    this.options = const <ProductOption>[],
    this.variants = const <ProductVariantOption>[],
  });

  factory ProductOptionsDto.fromJson(Map<String, dynamic> json) {
    final options =
        (json['options'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(_option)
            .where((option) => option.values.isNotEmpty)
            .toList()
          ..sort(_byOptionOrder);
    if (options.isEmpty) return const ProductOptionsDto();

    final variants = (json['variants'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_variant)
        .where((variant) => variant.optionValueIds.isNotEmpty)
        .toList(growable: false);
    if (variants.isEmpty) return const ProductOptionsDto();

    return ProductOptionsDto(
      options: List.unmodifiable(options),
      variants: List.unmodifiable(variants),
    );
  }

  /// Ordered by `sortOrder`, then name — the order the chooser rows render in.
  final List<ProductOption> options;
  final List<ProductVariantOption> variants;

  bool get isEmpty => options.isEmpty || variants.isEmpty;

  static int _byOptionOrder(ProductOption a, ProductOption b) {
    final order = a.sortOrder.compareTo(b.sortOrder);
    return order != 0 ? order : a.name.compareTo(b.name);
  }

  static ProductOption _option(Map<String, dynamic> json) {
    final values =
        (json['values'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(_value)
            .where((value) => value.id.isNotEmpty)
            .toList()
          ..sort((a, b) {
            final order = a.sortOrder.compareTo(b.sortOrder);
            return order != 0 ? order : a.value.compareTo(b.value);
          });
    final kind = ProductOptionKind.fromWire((json['kind'] as num?)?.toInt());
    return ProductOption(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      kind: kind,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      values: List.unmodifiable(values),
    );
  }

  static ProductOptionValue _value(Map<String, dynamic> json) {
    final swatch = (json['swatchHex'] as String?)?.trim();
    return ProductOptionValue(
      id: json['id'] as String? ?? '',
      value: json['value'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      swatchHex: swatch == null || swatch.isEmpty ? null : swatch.toUpperCase(),
    );
  }

  static ProductVariantOption _variant(Map<String, dynamic> json) {
    final label = (json['optionLabel'] as String?)?.trim();
    return ProductVariantOption(
      variantId: json['id'] as String? ?? '',
      optionValueIds: {
        ...(json['optionValueIds'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .where((id) => id.isNotEmpty),
      },
      optionLabel: label == null || label.isEmpty ? null : label,
      priceAmount: (json['priceAmount'] as num?)?.toDouble() ?? 0,
      priceCurrency: json['priceCurrency'] as String? ?? 'NPR',
      trackInventory: json['trackInventory'] as bool? ?? true,
      quantityOnHand: (json['quantityOnHand'] as num?)?.toInt() ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
