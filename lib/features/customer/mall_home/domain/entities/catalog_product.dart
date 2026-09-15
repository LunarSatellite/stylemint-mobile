import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

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
  });

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
}
