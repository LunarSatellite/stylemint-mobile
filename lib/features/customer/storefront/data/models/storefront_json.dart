import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_page.dart';

/// Trimmed, non-blank strings of a JSON array; anything else reads as empty.
List<String> readStorefrontStrings(Object? raw) => raw is List
    ? raw
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false)
    : const [];

/// A `PagedResult<T>` body.
class StorefrontPageDto<T> {
  const StorefrontPageDto({
    required this.items,
    this.nextCursor,
    this.totalCount,
  });

  factory StorefrontPageDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) itemFromJson,
  ) => StorefrontPageDto(
    items: [for (final item in readPagedItems(json)) itemFromJson(item)],
    nextCursor: readNextCursor(json),
    totalCount: json['totalCount'] == null ? null : readInt(json['totalCount']),
  );

  final List<T> items;
  final String? nextCursor;
  final int? totalCount;

  /// Maps each item; items [toDomain] rejects (null) are dropped.
  StorefrontPage<E> toDomain<E extends Object>(E? Function(T item) toDomain) =>
      StorefrontPage(
        items: items.map(toDomain).nonNulls.toList(growable: false),
        nextCursor: nextCursor,
        totalCount: totalCount,
      );
}
