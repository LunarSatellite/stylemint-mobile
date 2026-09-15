import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';

/// Catalog `CollectionKind`.
enum CollectionKind { editorial, creatorCollection, brandCollection, look }

/// A product placed in a collection. Looks may pin it on the cover.
class CollectionItem {
  const CollectionItem({
    required this.product,
    this.sortOrder = 0,
    this.note,
    this.positionX,
    this.positionY,
  });

  final CatalogProduct product;
  final int sortOrder;
  final String? note;

  /// Fractions (0..1) of the cover's width and height; both or neither.
  final double? positionX;
  final double? positionY;

  bool get hasPosition => positionX != null && positionY != null;
}

/// `GET v1/public/collections/{slug}`: the header plus one page of items.
class CollectionDetail {
  const CollectionDetail({
    required this.id,
    required this.slug,
    required this.title,
    required this.kind,
    required this.items,
    this.subtitle,
    this.description,
    this.coverImageUrl,
    this.ownerDisplayName,
    this.itemCount = 0,
  });

  final String id;
  final String slug;
  final String title;
  final CollectionKind kind;
  final String? subtitle;
  final String? description;
  final String? coverImageUrl;
  final String? ownerDisplayName;

  /// Publicly listed items across all pages.
  final int itemCount;
  final CatalogPage<CollectionItem> items;

  bool get isLook => kind == CollectionKind.look;
}
