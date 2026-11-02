import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Multi-shop bundles, buyer side (shop bundles contract §B6–B10).
///
/// A bundle is a set of products from one or more shops sold together at a
/// discount. Each shop ships its own items as its own parcel; the bundle only
/// sets the price.

/// Why a bundle cannot be bought right now (`unavailableReason`).
enum BundleUnavailableReason {
  paused,
  itemOutOfStock,
  itemUnavailable,
  other;

  static BundleUnavailableReason? fromWire(Object? raw) {
    if (raw == null) return null;
    final s = raw.toString().trim().toLowerCase().replaceAll(
      RegExp(r'[\s_\-]'),
      '',
    );
    if (s.isEmpty) return null;
    return switch (s) {
      'paused' || '1' => paused,
      'itemoutofstock' || 'outofstock' || '2' => itemOutOfStock,
      'itemunavailable' || 'unavailable' || '3' => itemUnavailable,
      _ => other,
    };
  }

  /// What the buyer reads under the price.
  String get sentence => switch (this) {
    paused => 'This bundle is paused for now. Check back soon.',
    itemOutOfStock =>
      'One of the items is out of stock, so the bundle cannot be bought '
          'right now.',
    itemUnavailable =>
      'One of the items is no longer sold, so the bundle cannot be bought '
          'right now.',
    other => 'This bundle cannot be bought right now.',
  };
}

/// Who put the bundle together.
enum BundleCuratorKind {
  platform,
  creator,
  vendor;

  static BundleCuratorKind fromWire(Object? raw) {
    final s = raw?.toString().trim().toLowerCase() ?? '';
    return switch (s) {
      '1' || 'platform' => platform,
      '2' || 'creator' => creator,
      _ => vendor,
    };
  }
}

class BundleCurator {
  const BundleCurator({
    required this.kind,
    required this.accountId,
    required this.name,
    this.handle,
    this.avatarUrl,
  });

  final BundleCuratorKind kind;
  final String accountId;
  final String name;
  final String? handle;
  final String? avatarUrl;

  /// "Picked by @asha", "From Peak Gear", "A StyleMint pick".
  String get byline => switch (kind) {
    BundleCuratorKind.platform => 'A StyleMint pick',
    BundleCuratorKind.creator =>
      'Picked by ${handle != null ? '@$handle' : name}',
    BundleCuratorKind.vendor => 'From $name',
  };
}

/// One variant the buyer can pick for an item.
class BundleVariant {
  const BundleVariant({
    required this.id,
    required this.label,
    required this.price,
    required this.inStock,
    this.stockQuantity,
    this.isDefault = false,
  });

  final String id;
  final String label;

  /// The list (catalog) price of this variant.
  final Money price;
  final bool inStock;

  /// Units on hand, when the server says.
  final int? stockQuantity;
  final bool isDefault;

  /// Whether [quantity] units of this variant can be bought.
  bool canCover(int quantity) =>
      inStock && (stockQuantity == null || stockQuantity! >= quantity);
}

/// One product in a bundle, with its quantity per bundle.
class BundleItem {
  const BundleItem({
    required this.id,
    required this.productId,
    required this.vendorAccountId,
    required this.shopName,
    required this.title,
    required this.quantity,
    required this.listUnitPrice,
    required this.bundleUnitPrice,
    required this.variants,
    this.thumbnailUrl,
    this.note,
    this.available = true,
  });

  /// The bundle item id (`bundleItemId` on the add call).
  final String id;
  final String productId;
  final String vendorAccountId;
  final String shopName;
  final String title;
  final String? thumbnailUrl;
  final String? note;
  final int quantity;

  /// Per unit, at the default variant, before and after the discount.
  final Money listUnitPrice;
  final Money bundleUnitPrice;
  final List<BundleVariant> variants;
  final bool available;

  /// More than one variant to choose from.
  bool get needsChoice => variants.length > 1;

  /// The variant picked before the buyer touches anything: the default
  /// one when it can cover the quantity, else the first that can.
  BundleVariant? get initialVariant {
    for (final v in variants) {
      if (v.isDefault && v.canCover(quantity)) return v;
    }
    for (final v in variants) {
      if (v.canCover(quantity)) return v;
    }
    return null;
  }
}

/// A bundle's items from one shop: one parcel.
class BundleShopGroup {
  const BundleShopGroup({
    required this.vendorAccountId,
    required this.shopName,
    required this.items,
  });

  final String vendorAccountId;
  final String shopName;
  final List<BundleItem> items;
}

/// `BundleDetailDto` — the bundle page.
class BundleDetail {
  const BundleDetail({
    required this.id,
    required this.title,
    required this.discountPercent,
    required this.termsVersion,
    required this.isPurchasable,
    required this.items,
    required this.currency,
    this.description,
    this.coverImageUrl,
    this.unavailableReason,
    this.curator,
  });

  final String id;
  final String title;
  final String? description;
  final String? coverImageUrl;

  /// 0–50. 0 is a "kit": sold together with no discount.
  final double discountPercent;

  /// Sent back on the add call; a stale one is refused with
  /// `bundle_terms_changed`.
  final int termsVersion;
  final bool isPurchasable;
  final BundleUnavailableReason? unavailableReason;
  final BundleCurator? curator;
  final List<BundleItem> items;
  final String currency;

  bool get hasDiscount => discountPercent > 0;

  /// The items grouped by shop, in the order their shops first appear.
  List<BundleShopGroup> get shops {
    final order = <String>[];
    final byShop = <String, List<BundleItem>>{};
    for (final item in items) {
      final key = item.vendorAccountId.isEmpty
          ? item.shopName
          : item.vendorAccountId;
      if (!byShop.containsKey(key)) order.add(key);
      (byShop[key] ??= <BundleItem>[]).add(item);
    }
    return [
      for (final key in order)
        BundleShopGroup(
          vendorAccountId: byShop[key]!.first.vendorAccountId,
          shopName: byShop[key]!.first.shopName,
          items: List.unmodifiable(byShop[key]!),
        ),
    ];
  }

  int get shopCount => shops.length;
}

/// `BundleCardDto` — a bundle on a rail, a reel or a storefront.
class BundleCard {
  const BundleCard({
    required this.id,
    required this.title,
    required this.discountPercent,
    required this.listTotal,
    required this.bundleTotal,
    this.coverImageUrl,
    this.itemCount = 0,
    this.shopCount = 0,
    this.thumbnailUrls = const <String>[],
    this.isPurchasable = true,
    this.curatorName,
  });

  final String id;
  final String title;
  final String? coverImageUrl;
  final double discountPercent;
  final Money listTotal;
  final Money bundleTotal;
  final int itemCount;
  final int shopCount;
  final List<String> thumbnailUrls;
  final bool isPurchasable;
  final String? curatorName;

  Money get saving => Money(
    amount: (listTotal.amount - bundleTotal.amount).clamp(0, double.infinity),
    currency: bundleTotal.currency,
  );

  bool get hasSaving => saving.amount > 0;

  /// The picture for the card: the cover, else the first item photo.
  String? get imageUrl =>
      coverImageUrl ?? (thumbnailUrls.isEmpty ? null : thumbnailUrls.first);
}

/// A bundle tagged on a reel (`TaggedBundle`, contract §B9).
class ReelTaggedBundle {
  const ReelTaggedBundle({
    required this.taggedBundleId,
    required this.bundle,
    this.x,
    this.y,
    this.appearAtSeconds,
    this.disappearAtSeconds,
  });

  final String taggedBundleId;
  final BundleCard bundle;
  final double? x;
  final double? y;
  final double? appearAtSeconds;
  final double? disappearAtSeconds;
}

/// Where the bundles on a rail come from: a shop's storefront or a
/// creator's profile.
typedef BundleListKey = ({String? vendorAccountId, String? creatorAccountId});
