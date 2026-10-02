import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/product_reel_ref.dart';

/// A publicly listed product as a Catalog listing card.
class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    required this.price,
    this.vendorAccountId,
    this.vendorDisplayName,
    this.imageUrl,
    this.compareAtPrice,
    this.rating,
    this.reviewCount = 0,
    this.isLowStock = false,
    this.isOutOfStock = false,
    this.reel,
    this.requiresOptionSelection = true,
    this.defaultVariantId,
    this.isInStock = false,
    this.productKind,
  });

  /// Catalog `ProductKind` as the server stated it, or null when the payload
  /// carried none. Drives the digital-goods gate; never defaulted to
  /// physical, because "unknown" and "physical" are different facts.
  final int? productKind;

  /// The reel this product is sold through. Null for most products.
  final ProductReelRef? reel;

  /// Whether the buyer has to choose a size or a colour before this can go in
  /// a cart. Defaults to `true`: a card that did not say is never quick-added.
  final bool requiresOptionSelection;

  /// The variant a quick add sends. Null when the server sent none.
  final String? defaultVariantId;

  /// Whether the server proved the default variant can currently be bought.
  final bool isInStock;

  final String id;
  final String name;

  /// Current price; a running flash sale has already lowered it.
  final Money price;
  final String? vendorAccountId;
  final String? vendorDisplayName;
  final String? imageUrl;

  /// The pre-sale price while a flash sale runs, else null.
  final Money? compareAtPrice;

  /// Null when the product has no rated reviews.
  final double? rating;
  final int reviewCount;
  final bool isLowStock;
  final bool isOutOfStock;
}

/// One cursor page of a Catalog list.
class CatalogPage<T> {
  const CatalogPage({required this.items, this.nextCursor, this.totalCount});

  final List<T> items;

  /// Pass back unchanged for the next page; null on the last page.
  final String? nextCursor;
  final int? totalCount;

  bool get hasMore => nextCursor != null;

  /// The same page with only the items [keep] accepts. The cursor and
  /// [totalCount] are the server's and are left alone: they describe what the
  /// server holds, not what this build chose to show.
  CatalogPage<T> where(bool Function(T item) keep) => CatalogPage<T>(
    items: items.where(keep).toList(growable: false),
    nextCursor: nextCursor,
    totalCount: totalCount,
  );
}
