import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/data/models/storefront_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_collection.dart';

/// One `CollectionCardDto` of `GET v1/public/collections`.
class StorefrontCollectionDto {
  const StorefrontCollectionDto({
    required this.id,
    required this.slug,
    required this.title,
    this.kind,
    this.subtitle,
    this.coverImageUrl,
    this.itemCount = 0,
    this.previewImageUrls = const [],
  });

  factory StorefrontCollectionDto.fromJson(Map<String, dynamic> json) =>
      StorefrontCollectionDto(
        id: readString(json['id']),
        slug: readString(json['slug']),
        title: readString(json['title']),
        kind: parseCollectionKind(json['kind']),
        subtitle: readOptionalString(json['subtitle']),
        coverImageUrl: readOptionalString(json['coverImageUrl']),
        itemCount: readInt(json['itemCount']),
        previewImageUrls: readStorefrontStrings(json['previewImageUrls']),
      );

  final String id;
  final String slug;
  final String title;
  final CollectionKind? kind;
  final String? subtitle;
  final String? coverImageUrl;
  final int itemCount;
  final List<String> previewImageUrls;

  /// Null when the card can't open a collection (no slug or title).
  StorefrontCollection? toDomain() {
    if (slug.isEmpty || title.isEmpty) return null;
    return StorefrontCollection(
      id: id.isEmpty ? slug : id,
      slug: slug,
      title: title,
      kind: kind ?? CollectionKind.editorial,
      subtitle: subtitle,
      coverImageUrl: coverImageUrl,
      itemCount: itemCount < 0 ? 0 : itemCount,
      previewImageUrls: previewImageUrls,
    );
  }
}

/// Catalog `CollectionKind` from its number or name; null when unknown.
CollectionKind? parseCollectionKind(Object? raw) =>
    switch (normalizeWireEnum(raw)) {
      1 || 'editorial' => CollectionKind.editorial,
      2 || 'creatorcollection' => CollectionKind.creatorCollection,
      3 || 'brandcollection' => CollectionKind.brandCollection,
      4 || 'look' => CollectionKind.look,
      _ => null,
    };
