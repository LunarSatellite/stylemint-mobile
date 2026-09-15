import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feedback.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/data/models/storefront_collection_dto.dart'
    show parseCollectionKind;

/// `GET api/v1/customer/feed/not-interested`. Entries with an unknown kind or
/// no id are dropped.
class NotInterestedListDto {
  const NotInterestedListDto(this.items);

  factory NotInterestedListDto.fromJson(Map<String, dynamic> json) =>
      NotInterestedListDto(readPagedItems(json));

  final List<Map<String, dynamic>> items;

  List<NotInterestedSignal> toDomain() => [
    for (final json in items)
      if ((
            NotInterestedKind.parse(json['targetKind']),
            readString(json['targetId']),
          )
          case (final kind?, final id) when id.isNotEmpty)
        NotInterestedSignal(
          target: NotInterestedTarget(kind, id),
          reason: readOptionalString(json['reason']),
          createdUtc: readDate(json['createdUtc']),
        ),
  ];
}

/// One `CollectionCardDto` page of `GET v1/public/collections`. Cards that
/// can't open a collection (no slug or title) are dropped.
class DiscoverCollectionPageDto {
  const DiscoverCollectionPageDto({required this.items, this.nextCursor});

  factory DiscoverCollectionPageDto.fromJson(Map<String, dynamic> json) =>
      DiscoverCollectionPageDto(
        items: readPagedItems(json),
        nextCursor: readNextCursor(json),
      );

  final List<Map<String, dynamic>> items;
  final String? nextCursor;

  CatalogPage<HomeCollection> toDomain() => CatalogPage(
    nextCursor: nextCursor,
    items: [
      for (final json in items) ?_collection(json),
    ],
  );

  static HomeCollection? _collection(Map<String, dynamic> json) {
    final slug = readString(json['slug']);
    final title = readString(json['title']);
    if (slug.isEmpty || title.isEmpty) return null;
    final count = readInt(json['itemCount']);
    final previews = json['previewImageUrls'];
    return HomeCollection(
      slug: slug,
      title: title,
      kind: parseCollectionKind(json['kind']) ?? CollectionKind.editorial,
      subtitle: readOptionalString(json['subtitle']),
      coverImageUrl: readOptionalString(json['coverImageUrl']),
      itemCount: count <= 0 ? null : count,
      previewImageUrls: previews is List
          ? [
              for (final url in previews) ?readOptionalString(url),
            ]
          : const [],
    );
  }
}
