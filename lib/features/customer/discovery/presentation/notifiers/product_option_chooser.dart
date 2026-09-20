import 'package:flutter/foundation.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_option.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Why a value cannot be picked with the shopper's other picks.
enum OptionValueAvailability {
  available,

  /// No variant sells this combination at all.
  unavailable,

  /// A variant exists but has no stock left.
  outOfStock;

  bool get isSelectable => this == OptionValueAvailability.available;

  /// Short, shown next to the greyed value.
  String? get reason => switch (this) {
    OptionValueAvailability.available => null,
    OptionValueAvailability.unavailable => 'Not available',
    OptionValueAvailability.outOfStock => 'Out of stock',
  };
}

/// An immutable "which values are picked" snapshot for one product, plus the
/// resolution rules of catalog contract §8: the chosen variant is the one
/// whose `optionValueIds` contains every picked id.
@immutable
class ProductOptionSelection {
  const ProductOptionSelection({
    required this.options,
    required this.variants,
    required this.picked,
  });

  /// Preselects the default variant's values (the first variant when none is
  /// flagged), so the page opens on a real, priced combination.
  factory ProductOptionSelection.initial(
    List<ProductOption> options,
    List<ProductVariantOption> variants,
  ) {
    if (options.isEmpty || variants.isEmpty) {
      return const ProductOptionSelection(
        options: <ProductOption>[],
        variants: <ProductVariantOption>[],
        picked: <String, String>{},
      );
    }
    final preferred = variants.firstWhere(
      (variant) => variant.isDefault,
      orElse: () => variants.first,
    );
    return ProductOptionSelection(
      options: options,
      variants: variants,
      picked: {
        for (final option in options)
          if (_valueOf(option, preferred) case final String id) option.id: id,
      },
    );
  }

  final List<ProductOption> options;
  final List<ProductVariantOption> variants;

  /// Option id → picked value id.
  final Map<String, String> picked;

  bool get isEmpty => options.isEmpty || variants.isEmpty;

  /// True once every option has a pick.
  bool get isComplete => picked.length == options.length;

  /// The variant carrying every picked value, or null while the choice is
  /// incomplete or names a combination nobody sells.
  ProductVariantOption? get resolvedVariant {
    if (isEmpty || !isComplete) return null;
    final ids = picked.values.toSet();
    for (final variant in variants) {
      if (ids.every(variant.optionValueIds.contains)) return variant;
    }
    return null;
  }

  /// Why the current combination cannot be bought, or null when it can.
  String? get unavailableReason {
    if (isEmpty) return null;
    if (!isComplete) {
      final missing = options.where((o) => !picked.containsKey(o.id)).toList();
      return missing.isEmpty ? null : 'Choose a ${missing.first.name}';
    }
    final variant = resolvedVariant;
    if (variant == null) return 'This combination is not available';
    return variant.isBuyable ? null : 'This combination is out of stock';
  }

  /// Whether [valueId] can be picked given every *other* current pick.
  OptionValueAvailability availabilityOf(String optionId, String valueId) {
    final candidate = <String>{
      for (final MapEntry(:key, :value) in picked.entries)
        if (key != optionId) value,
      valueId,
    };
    var sawVariant = false;
    for (final variant in variants) {
      if (!candidate.every(variant.optionValueIds.contains)) continue;
      if (variant.isBuyable) return OptionValueAvailability.available;
      sawVariant = true;
    }
    return sawVariant
        ? OptionValueAvailability.outOfStock
        : OptionValueAvailability.unavailable;
  }

  ProductOptionSelection select(String optionId, String valueId) =>
      ProductOptionSelection(
        options: options,
        variants: variants,
        picked: {...picked, optionId: valueId},
      );

  /// Folds the picked variant's price and stock back onto [product] so the
  /// price row, stock line and the add-to-cart bar follow the choice.
  ProductDetail applyTo(ProductDetail product) {
    if (isEmpty) return product;
    final variant = resolvedVariant;
    if (variant == null) {
      return product.copyWith(isInStock: false, stockCount: 0);
    }
    // The flash sale on the detail payload prices the default variant only.
    final keepSalePrice = variant.isDefault && product.compareAtPrice != null;
    return product.copyWith(
      defaultVariantId: variant.variantId,
      isInStock: variant.isBuyable,
      stockCount: variant.trackInventory ? variant.quantityOnHand : null,
      clearStockCount: !variant.trackInventory,
      price: keepSalePrice
          ? product.price
          : Money(
              amount: variant.priceAmount,
              currency: variant.priceCurrency,
            ),
      clearCompareAtPrice: !keepSalePrice,
    );
  }

  static String? _valueOf(ProductOption option, ProductVariantOption variant) {
    for (final value in option.values) {
      if (variant.optionValueIds.contains(value.id)) return value.id;
    }
    return option.values.isEmpty ? null : option.values.first.id;
  }
}

/// Holds the product page's option picks. Local to the screen — nothing here
/// is fetched, so it needs no repository and no Riverpod provider.
class ProductOptionChooser extends ValueNotifier<ProductOptionSelection> {
  // ValueNotifier takes a private `_value`, so a super parameter can never
  // share its name — the matching-name lint is unwinnable here.
  // ignore: matching_super_parameters
  ProductOptionChooser(super.value);

  ProductOptionChooser.forProduct(ProductDetail product)
    : super(
        ProductOptionSelection.initial(product.options, product.optionVariants),
      );

  void select(String optionId, String valueId) {
    if (value.picked[optionId] == valueId) return;
    value = value.select(optionId, valueId);
  }
}
