import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_option.dart';

/// The variant to put in the cart for a size-chart label ("M"), so "Add to
/// cart in size M" uses the product page's own add-to-cart.
///
/// Size-chart labels are free text the vendor typed; variant option values
/// are too. They are matched case- and space-insensitively. Among variants
/// carrying that size, one that keeps the buyer's other picks
/// ([keepValueIds], e.g. the colour already chosen) and is in stock wins.
/// Null when the product has no variant for that size.
String? variantIdForSize(
  ProductDetail product,
  String sizeLabel, {
  Set<String> keepValueIds = const {},
}) {
  final needle = _norm(sizeLabel);
  if (needle.isEmpty) return null;

  // Structured options (Catalog §8).
  final sizeOption = product.options.where(
    (o) => o.kind == ProductOptionKind.size || _norm(o.name).contains('size'),
  );
  for (final option in sizeOption) {
    final value = option.values.where((v) => _norm(v.value) == needle);
    if (value.isEmpty) continue;
    final valueId = value.first.id;
    final candidates = product.optionVariants
        .where((v) => v.optionValueIds.contains(valueId))
        .toList();
    if (candidates.isEmpty) continue;
    int score(ProductVariantOption v) {
      final kept = v.optionValueIds.intersection(keepValueIds).length;
      final inStock = !v.trackInventory || v.quantityOnHand > 0;
      return kept * 2 + (inStock ? 1 : 0);
    }

    // First best wins, so catalogue order breaks ties deterministically.
    var best = candidates.first;
    for (final c in candidates.skip(1)) {
      if (score(c) > score(best)) best = c;
    }
    return best.variantId;
  }

  // Legacy chip groups: a size group, or a SKU group whose labels are sizes.
  for (final group in product.variants) {
    for (final value in group.values) {
      if (_norm(value) != needle) continue;
      final id = group.optionVariantIds[value];
      if (id != null && id.isNotEmpty) return id;
    }
  }
  return null;
}

String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
