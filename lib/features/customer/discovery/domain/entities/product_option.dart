import 'dart:ui' show Color;

/// `ProductOptionKind` of the Catalog contract (§8). Unknown wire values fall
/// back to [other] so a new server-side kind never breaks the product page.
enum ProductOptionKind {
  size(1),
  colour(2),
  material(3),
  style(4),
  other(99);

  const ProductOptionKind(this.wire);

  final int wire;

  static ProductOptionKind fromWire(int? value) {
    for (final kind in values) {
      if (kind.wire == value) return kind;
    }
    return other;
  }
}

/// One selectable value of a [ProductOption] — "M", "Emerald".
class ProductOptionValue {
  const ProductOptionValue({
    required this.id,
    required this.value,
    this.sortOrder = 0,
    this.swatchHex,
  });

  final String id;
  final String value;
  final int sortOrder;

  /// Upper-case `#RRGGBB`, only ever set on a [ProductOptionKind.colour]
  /// option. Never the only way a colour is conveyed — [value] is the label.
  final String? swatchHex;

  /// [swatchHex] as a colour, or null when it is missing or malformed.
  Color? get swatchColor {
    final hex = swatchHex;
    if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
    final rgb = int.tryParse(hex.substring(1), radix: 16);
    return rgb == null ? null : Color(0xFF000000 | rgb);
  }
}

/// A product's option row — "Size" with its values. Up to 3 per product.
class ProductOption {
  const ProductOption({
    required this.id,
    required this.name,
    required this.kind,
    this.sortOrder = 0,
    this.values = const <ProductOptionValue>[],
  });

  final String id;
  final String name;
  final ProductOptionKind kind;
  final int sortOrder;
  final List<ProductOptionValue> values;

  /// Colour options render as swatches, everything else as pills.
  bool get isSwatch => kind == ProductOptionKind.colour;
}

/// A buyable variant seen through its option values — the detail call's
/// `variants[]` plus `optionValueIds` and `optionLabel`.
class ProductVariantOption {
  const ProductVariantOption({
    required this.variantId,
    required this.optionValueIds,
    this.optionLabel,
    this.priceAmount = 0,
    this.priceCurrency = 'NPR',
    this.trackInventory = true,
    this.quantityOnHand = 0,
    this.isDefault = false,
  });

  final String variantId;

  /// One id per option, in `options` order.
  final Set<String> optionValueIds;

  /// The chosen values joined, e.g. "M / Emerald".
  final String? optionLabel;
  final double priceAmount;
  final String priceCurrency;
  final bool trackInventory;
  final int quantityOnHand;
  final bool isDefault;

  /// Untracked inventory is always buyable; tracked stock needs a unit left.
  bool get isBuyable => !trackInventory || quantityOnHand > 0;
}
