/// One cursor page of a public storefront list.
class StorefrontPage<T> {
  const StorefrontPage({
    required this.items,
    this.nextCursor,
    this.totalCount,
  });

  final List<T> items;

  /// Pass back unchanged for the next page; null on the last page.
  final String? nextCursor;
  final int? totalCount;

  bool get hasMore => nextCursor != null;
}
