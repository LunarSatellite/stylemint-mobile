/// Minimal page envelope used by the messaging REST surface. Matches the
/// backend `PagedResult<T>` shape (see
/// `stylemint-backend/src/.../Pagination/PagedResult.cs`):
///   items        - the current page's records
///   totalCount   - total record count matching the filter (no pagination)
///   pageSize     - server-applied page size cap
///   nextCursor   - opaque token for the next page; null when no more
class PagedDto<T> {
  const PagedDto({
    required this.items,
    required this.totalCount,
    required this.pageSize,
    this.nextCursor,
  });

  final List<T> items;
  final int totalCount;
  final int pageSize;
  final String? nextCursor;

  factory PagedDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final raw = json['items'] as List<dynamic>? ?? const <dynamic>[];
    return PagedDto<T>(
      items: raw
          .map((e) => itemFromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
      nextCursor: json['nextCursor'] as String?,
    );
  }
}