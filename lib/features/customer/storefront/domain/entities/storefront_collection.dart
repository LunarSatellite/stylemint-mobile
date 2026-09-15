import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';

export 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart'
    show CollectionKind;

/// Who owns a collection (Catalog `CollectionOwnerKind`).
enum StorefrontOwnerKind {
  creator(2),
  vendor(3);

  const StorefrontOwnerKind(this.wire);

  final int wire;
}

/// The Catalog `CollectionKind` wire value of [kind].
int collectionKindWire(CollectionKind kind) => switch (kind) {
  CollectionKind.editorial => 1,
  CollectionKind.creatorCollection => 2,
  CollectionKind.brandCollection => 3,
  CollectionKind.look => 4,
};

/// A live collection or look as a storefront card.
class StorefrontCollection {
  const StorefrontCollection({
    required this.id,
    required this.slug,
    required this.title,
    required this.kind,
    this.subtitle,
    this.coverImageUrl,
    this.itemCount = 0,
    this.previewImageUrls = const [],
  });

  final String id;
  final String slug;
  final String title;
  final CollectionKind kind;
  final String? subtitle;
  final String? coverImageUrl;

  /// Publicly listed items.
  final int itemCount;

  /// Primary images of the first items (up to four).
  final List<String> previewImageUrls;

  bool get isLook => kind == CollectionKind.look;
}
