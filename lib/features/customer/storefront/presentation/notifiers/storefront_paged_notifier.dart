import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_page.dart';

/// Loads the page after [cursor] (the first page when null).
typedef StorefrontPageLoader<T> =
    Future<Either<NetworkExceptions, StorefrontPage<T>>> Function(
      String? cursor,
    );

/// A cursor-paged storefront list.
sealed class StorefrontPagedState<T> {
  const StorefrontPagedState();
}

/// The first page is loading.
final class StorefrontPagedLoading<T> extends StorefrontPagedState<T> {
  const StorefrontPagedLoading();
}

/// The first page failed.
final class StorefrontPagedFailure<T> extends StorefrontPagedState<T> {
  const StorefrontPagedFailure(this.failure);

  final NetworkExceptions failure;
}

/// Every page loaded so far.
@immutable
final class StorefrontPagedLoaded<T> extends StorefrontPagedState<T> {
  const StorefrontPagedLoaded({
    required this.items,
    this.nextCursor,
    this.totalCount,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  /// Each item once, in server order.
  final List<T> items;
  final String? nextCursor;
  final int? totalCount;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  bool get hasMore => nextCursor != null;

  bool get isEmpty => items.isEmpty && !hasMore;

  /// Whether scrolling near the end should fetch the next page.
  bool get canLoadMore => hasMore && !isLoadingMore && !loadMoreFailed;

  StorefrontPagedLoaded<T> _copyWith({
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) => StorefrontPagedLoaded<T>(
    items: items,
    nextCursor: nextCursor,
    totalCount: totalCount,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

/// Cursor paging for one storefront list. The first page loads on creation.
class StorefrontPagedNotifier<T>
    extends StateNotifier<StorefrontPagedState<T>> {
  StorefrontPagedNotifier(
    this._load, {
    required String Function(T item) idOf,
    bool loadOnCreate = true,
  }) : _idOf = idOf,
       super(StorefrontPagedLoading<T>()) {
    if (loadOnCreate) unawaited(refresh());
  }

  final StorefrontPageLoader<T> _load;
  final String Function(T item) _idOf;

  /// Pages the server emptied by filtering are followed at most this many
  /// times in a row before the list settles.
  static const int maxEmptyPagesFollowed = 3;

  int _generation = 0;

  /// Loads the first page again.
  Future<void> refresh() async {
    final generation = ++_generation;
    state = StorefrontPagedLoading<T>();
    final result = await _loadFrom(null);
    if (!mounted || generation != _generation) return;
    state = result.fold(
      StorefrontPagedFailure<T>.new,
      (page) => StorefrontPagedLoaded<T>(
        items: _merge(const [], page.items),
        nextCursor: page.nextCursor,
        totalCount: page.totalCount,
      ),
    );
  }

  /// Appends the next page. No-op while a page is loading, after a failed
  /// page (use [retryLoadMore]) or on the last page.
  Future<void> loadMore() async {
    final current = state;
    if (current is! StorefrontPagedLoaded<T> || !current.canLoadMore) return;
    await _appendAfter(current);
  }

  /// Tries the page that failed again.
  Future<void> retryLoadMore() async {
    final current = state;
    if (current is! StorefrontPagedLoaded<T> ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }
    await _appendAfter(current);
  }

  Future<void> _appendAfter(StorefrontPagedLoaded<T> current) async {
    final generation = _generation;
    state = current._copyWith(isLoadingMore: true, loadMoreFailed: false);
    final result = await _loadFrom(current.nextCursor);
    if (!mounted || generation != _generation) return;
    state = result.fold(
      (_) => current._copyWith(isLoadingMore: false, loadMoreFailed: true),
      (page) => StorefrontPagedLoaded<T>(
        items: _merge(current.items, page.items),
        nextCursor: page.nextCursor,
        totalCount: page.totalCount ?? current.totalCount,
      ),
    );
  }

  /// Loads the page at [cursor]. A page left empty by server-side filtering
  /// that still has a cursor is followed, so the viewer isn't shown a blank
  /// list while more items exist.
  Future<Either<NetworkExceptions, StorefrontPage<T>>> _loadFrom(
    String? cursor,
  ) async {
    var result = await _load(cursor);
    for (var followed = 0; followed < maxEmptyPagesFollowed; followed++) {
      final next = result.fold(
        (_) => null,
        (page) => page.items.isEmpty ? page.nextCursor : null,
      );
      if (next == null || !mounted) break;
      result = await _load(next);
    }
    return result;
  }

  List<T> _merge(List<T> existing, List<T> incoming) {
    final seen = {for (final item in existing) _idOf(item)};
    return [
      ...existing,
      for (final item in incoming)
        if (seen.add(_idOf(item))) item,
    ];
  }
}
