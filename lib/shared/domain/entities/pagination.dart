/// Cursor-based pagination — used for feeds, infinite scroll.
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.totalCount,
    required this.pageSize,
    this.nextCursor,
    this.previousCursor,
    required this.hasMore,
  });

  final List<T> items;
  final int totalCount;
  final int pageSize;
  final String? nextCursor;     // opaque — send back as-is on next request
  final String? previousCursor;
  final bool hasMore;
}

/// Page-based pagination — used for admin-style lists.
class PagedList<T> {
  const PagedList({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPrevious,
    required this.hasNext,
  });

  final List<T> items;
  final int totalCount;
  final int pageNumber; // 1-based
  final int pageSize;
  final int totalPages;
  final bool hasPrevious;
  final bool hasNext;
}
