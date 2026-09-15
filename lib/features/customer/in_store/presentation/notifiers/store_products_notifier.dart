import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/store_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/repositories/in_store_repository.dart';

sealed class StoreProductsState {
  const StoreProductsState();
}

final class StoreProductsLoading extends StoreProductsState {
  const StoreProductsLoading();
}

final class StoreProductsLoaded extends StoreProductsState {
  const StoreProductsLoaded(
    this.products, {
    this.nextCursor,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<StoreProduct> products;

  /// Where the next page starts; null once the last page is in.
  final String? nextCursor;

  /// The next page is on its way.
  final bool loadingMore;

  /// The last next-page request failed; the products already shown stay.
  final bool loadMoreFailed;

  bool get hasMore => nextCursor != null;
}

final class StoreProductsFailed extends StoreProductsState {
  const StoreProductsFailed(this.failure);

  final NetworkExceptions failure;
}

/// A vendor's products for the in-store store screen, a page at a time.
class StoreProductsNotifier extends StateNotifier<StoreProductsState> {
  StoreProductsNotifier(this._repository, this.vendorId)
    : super(const StoreProductsLoading()) {
    unawaited(load());
  }

  final InStoreRepository _repository;
  final String vendorId;

  /// Loads the first page again.
  Future<void> load() async {
    state = const StoreProductsLoading();
    final result = await _repository.getVendorProducts(vendorId);
    if (!mounted) return;
    state = result.fold(
      StoreProductsFailed.new,
      (page) => StoreProductsLoaded(page.products, nextCursor: page.nextCursor),
    );
  }

  /// Appends the next page. Does nothing while a page is loading, before the
  /// first page is in, or after the last one.
  Future<void> loadMore() async {
    final current = state;
    if (current is! StoreProductsLoaded || current.loadingMore) return;
    final cursor = current.nextCursor;
    if (cursor == null) return;

    state = StoreProductsLoaded(
      current.products,
      nextCursor: cursor,
      loadingMore: true,
    );
    final result = await _repository.getVendorProducts(
      vendorId,
      cursor: cursor,
    );
    if (!mounted) return;
    state = result.fold(
      (_) => StoreProductsLoaded(
        current.products,
        nextCursor: cursor,
        loadMoreFailed: true,
      ),
      (page) {
        final shown = {for (final product in current.products) product.id};
        return StoreProductsLoaded(
          [
            ...current.products,
            ...page.products.where((product) => !shown.contains(product.id)),
          ],
          nextCursor: page.nextCursor,
        );
      },
    );
  }
}
