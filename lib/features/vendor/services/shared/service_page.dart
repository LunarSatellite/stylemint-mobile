import 'package:stylemint_mobile_frontend/core/network/json_read.dart';

/// One page of a cursor-paged list (`PagedResult`).
class ServicePage<T> {
  const ServicePage({required this.items, this.nextCursor, this.totalCount});

  final List<T> items;

  /// Passed back unchanged for the next page; null on the last page.
  final String? nextCursor;
  final int? totalCount;

  bool get hasMore => nextCursor != null;
}

/// A `PagedResult` body (or a bare array) read with [item]. One unreadable
/// row is skipped rather than losing the page.
ServicePage<T> readServicePage<T>(
  Object? raw,
  T Function(Map<String, dynamic> json) item,
) {
  final List<dynamic> rows = raw is List
      ? raw
      : raw is Map && raw['items'] is List
      ? raw['items'] as List
      : const <dynamic>[];
  final items = <T>[];
  for (final row in rows) {
    if (row is! Map) continue;
    try {
      items.add(item(Map<String, dynamic>.from(row)));
    } on FormatException {
      continue;
    } on TypeError {
      continue;
    }
  }
  final hasMore = raw is Map && raw['hasMore'] == false ? false : true;
  final next = raw is Map ? readOptionalString(raw['nextCursor']) : null;
  return ServicePage<T>(
    items: List.unmodifiable(items),
    nextCursor: hasMore ? next : null,
    totalCount: raw is Map && raw['totalCount'] is num
        ? (raw['totalCount'] as num).toInt()
        : null,
  );
}

/// A bare array (or `{ items: [...] }`) read with [item].
List<T> readServiceList<T>(
  Object? raw,
  T Function(Map<String, dynamic> json) item,
) => readServicePage(raw, item).items;
