import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_catalog_repository.dart';

part 'collection_notifier.freezed.dart';

/// A collection's header and the items loaded so far.
@immutable
class CollectionViewData {
  const CollectionViewData({
    required this.collection,
    required this.items,
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final CollectionDetail collection;

  /// Every page so far, each product once, in curator order.
  final List<CollectionItem> items;
  final String? nextCursor;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  bool get hasMore => nextCursor != null;
}

@freezed
abstract class CollectionState with _$CollectionState {
  const CollectionState._();

  const factory CollectionState.initial() = _Initial;
  const factory CollectionState.loadInProgress() = _LoadInProgress;
  const factory CollectionState.loadSuccess(CollectionViewData data) =
      _LoadSuccess;
  const factory CollectionState.loadFailure(NetworkExceptions failure) =
      _LoadFailure;
}

/// `GET v1/public/collections/{slug}` with its items paged by cursor.
class CollectionNotifier extends StateNotifier<CollectionState> {
  CollectionNotifier(this._repository, {required this.slug})
    : super(const CollectionState.initial()) {
    unawaited(load());
  }

  static const pageSize = 20;

  final MallCatalogRepository _repository;
  final String slug;
  int _request = 0;

  Future<void> load() async {
    final request = ++_request;
    state = const CollectionState.loadInProgress();
    final result = await _repository.getCollection(slug, pageSize: pageSize);
    if (!mounted || request != _request) return;
    state = result.fold(
      CollectionState.loadFailure,
      (detail) => CollectionState.loadSuccess(
        CollectionViewData(
          collection: detail,
          items: _unique(const [], detail.items.items),
          nextCursor: detail.items.nextCursor,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    final data = state.maybeWhen(loadSuccess: (d) => d, orElse: () => null);
    final cursor = data?.nextCursor;
    if (data == null || cursor == null || data.isLoadingMore) return;
    final request = _request;
    state = CollectionState.loadSuccess(
      CollectionViewData(
        collection: data.collection,
        items: data.items,
        nextCursor: cursor,
        isLoadingMore: true,
      ),
    );
    final result = await _repository.getCollection(
      slug,
      cursor: cursor,
      pageSize: pageSize,
    );
    if (!mounted || request != _request) return;
    state = CollectionState.loadSuccess(
      result.fold(
        (_) => CollectionViewData(
          collection: data.collection,
          items: data.items,
          nextCursor: cursor,
          loadMoreFailed: true,
        ),
        (detail) => CollectionViewData(
          collection: data.collection,
          items: _unique(data.items, detail.items.items),
          nextCursor: detail.items.nextCursor,
        ),
      ),
    );
  }

  static List<CollectionItem> _unique(
    List<CollectionItem> existing,
    List<CollectionItem> incoming,
  ) {
    final seen = {for (final item in existing) item.product.id};
    return List.unmodifiable([
      ...existing,
      ...incoming.where((item) => seen.add(item.product.id)),
    ]);
  }
}
