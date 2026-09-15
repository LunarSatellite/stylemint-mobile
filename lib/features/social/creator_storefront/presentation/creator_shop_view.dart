import 'package:flutter/foundation.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/creator_shop_product.dart';

/// Orders of the creator shop grid.
enum CreatorShopSort {
  /// Most recently tagged first (the server order).
  newest('Newest'),

  /// Tagged in the most reels first.
  mostLoved('Most loved');

  const CreatorShopSort(this.label);

  final String label;
}

/// A brand among the loaded shop products.
@immutable
class CreatorShopBrand {
  const CreatorShopBrand({
    required this.key,
    required this.name,
    required this.count,
  });

  /// [creatorShopBrandKey] of its products.
  final String key;
  final String name;
  final int count;
}

/// Groups products by brand: the vendor account, or the brand name when the
/// account is missing.
String creatorShopBrandKey(CreatorShopProduct product) =>
    product.vendorAccountId.isNotEmpty
    ? product.vendorAccountId
    : 'name:${product.vendorDisplayName.trim().toLowerCase()}';

/// The brands in [products], most pieces first, then by name. Built from the
/// pages loaded so far. (The shop response has no category, so the shop can
/// only be grouped by brand.)
List<CreatorShopBrand> creatorShopBrands(List<CreatorShopProduct> products) {
  final counts = <String, int>{};
  final names = <String, String>{};
  for (final product in products) {
    final key = creatorShopBrandKey(product);
    counts[key] = (counts[key] ?? 0) + 1;
    final name = product.vendorDisplayName.trim();
    names.putIfAbsent(key, () => name.isEmpty ? 'Other brands' : name);
  }
  return [
    for (final MapEntry(:key, :value) in counts.entries)
      CreatorShopBrand(key: key, name: names[key]!, count: value),
  ]..sort((a, b) {
    final byCount = b.count.compareTo(a.count);
    return byCount != 0
        ? byCount
        : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
}

/// [products] of the brand [brandKey] (all brands when null) in [sort]
/// order. Ties keep the server order.
List<CreatorShopProduct> creatorShopView(
  List<CreatorShopProduct> products, {
  String? brandKey,
  CreatorShopSort sort = CreatorShopSort.newest,
}) {
  final indexed = [
    for (final (index, product) in products.indexed)
      if (brandKey == null || creatorShopBrandKey(product) == brandKey)
        (index, product),
  ];
  if (sort == CreatorShopSort.mostLoved) {
    indexed.sort((a, b) {
      final byReels = b.$2.reelCount.compareTo(a.$2.reelCount);
      return byReels != 0 ? byReels : a.$1.compareTo(b.$1);
    });
  }
  return [for (final (_, product) in indexed) product];
}
