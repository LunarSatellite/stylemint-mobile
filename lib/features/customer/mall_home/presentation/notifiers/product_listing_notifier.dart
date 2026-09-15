import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_catalog_repository.dart';

part 'product_listing_notifier.freezed.dart';

/// Loaded pages of a listing.
@immutable
class ProductListingData {
  const ProductListingData({
    required this.query,
    required this.products,
    this.nextCursor,
    this.totalCount,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final ProductListingQuery query;

  /// Every page so far, each product once.
  final List<CatalogProduct> products;
  final String? nextCursor;
  final int? totalCount;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  bool get hasMore => nextCursor != null;

  ProductListingData _copyWith({
    List<CatalogProduct>? products,
    String? nextCursor,
    bool clearCursor = false,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) => ProductListingData(
    query: query,
    products: products ?? this.products,
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    totalCount: totalCount,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

@freezed
abstract class ProductListingState with _$ProductListingState {
  const ProductListingState._();

  const factory ProductListingState.initial(ProductListingQuery query) =
      _Initial;
  const factory ProductListingState.loadInProgress(ProductListingQuery query) =
      _LoadInProgress;
  const factory ProductListingState.loadSuccess(ProductListingData data) =
      _LoadSuccess;
  const factory ProductListingState.loadFailure(
    ProductListingQuery query,
    NetworkExceptions failure,
  ) = _LoadFailure;

  /// The sort and filters currently applied.
  ProductListingQuery get activeQuery => when(
    initial: (query) => query,
    loadInProgress: (query) => query,
    loadSuccess: (data) => data.query,
    loadFailure: (query, _) => query,
  );
}

/// `GET v1/public/products` with cursor paging. Changing the sort or filters
/// starts again from the first page; a response for an older query is
/// ignored.
class ProductListingNotifier extends StateNotifier<ProductListingState> {
  ProductListingNotifier(
    this._repository, {
    required ProductListingQuery query,
  }) : super(ProductListingState.initial(query)) {
    unawaited(load());
  }

  static const pageSize = 20;

  final MallCatalogRepository _repository;
  int _request = 0;

  /// Reloads the first page of the current query.
  Future<void> load() => applyQuery(state.activeQuery);

  Future<void> applyQuery(ProductListingQuery query) async {
    final request = ++_request;
    state = ProductListingState.loadInProgress(query);
    final result = await _repository.getProducts(query, pageSize: pageSize);
    if (!mounted || request != _request) return;
    state = result.fold(
      (failure) => ProductListingState.loadFailure(query, failure),
      (page) => ProductListingState.loadSuccess(
        ProductListingData(
          query: query,
          products: _unique(const [], page.items),
          nextCursor: page.nextCursor,
          totalCount: page.totalCount,
        ),
      ),
    );
  }

  /// Appends the next page. No-op while a page loads or at the end.
  Future<void> loadMore() async {
    final data = state.maybeWhen(loadSuccess: (d) => d, orElse: () => null);
    final cursor = data?.nextCursor;
    if (data == null || cursor == null || data.isLoadingMore) return;
    final request = _request;
    state = ProductListingState.loadSuccess(
      data._copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    final result = await _repository.getProducts(
      data.query,
      cursor: cursor,
      pageSize: pageSize,
    );
    if (!mounted || request != _request) return;
    state = ProductListingState.loadSuccess(
      result.fold(
        (_) => data._copyWith(isLoadingMore: false, loadMoreFailed: true),
        (page) => data._copyWith(
          products: _unique(data.products, page.items),
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          isLoadingMore: false,
          loadMoreFailed: false,
        ),
      ),
    );
  }

  static List<CatalogProduct> _unique(
    List<CatalogProduct> existing,
    List<CatalogProduct> incoming,
  ) {
    final seen = {for (final p in existing) p.id};
    return List.unmodifiable([
      ...existing,
      ...incoming.where((p) => seen.add(p.id)),
    ]);
  }
}
