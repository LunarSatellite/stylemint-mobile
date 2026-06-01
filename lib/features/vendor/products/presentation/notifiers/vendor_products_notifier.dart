import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/repositories/vendor_products_repository.dart';

part 'vendor_products_notifier.freezed.dart';

@freezed
abstract class ProductsState with _$ProductsState {
  const ProductsState._();

  const factory ProductsState.initial() = _PInitial;
  const factory ProductsState.loadInProgress() = _PLoadInProgress;
  const factory ProductsState.loadSuccess(
    List<VendorProduct> products, {
    required String? nextCursor,
    required bool hasMore,
    required String? activeFilter,
  }) = _PLoadSuccess;
  const factory ProductsState.loadFailure(NetworkExceptions failure) = _PLoadFailure;
  const factory ProductsState.actionInProgress(List<VendorProduct> products) =
      _PActionInProgress;
  const factory ProductsState.actionFailure(
    List<VendorProduct> products,
    NetworkExceptions failure,
  ) = _PActionFailure;
}

class VendorProductsNotifier extends StateNotifier<ProductsState> {
  VendorProductsNotifier(this._repository)
      : super(const ProductsState.initial()) {
    unawaited(loadProducts());
  }

  final VendorProductsRepository _repository;

  String? _cursor;
  String? _activeFilter;

  Future<void> loadProducts({String? status}) async {
    state = const ProductsState.loadInProgress();
    _cursor = null;
    _activeFilter = status;
    final either = await _repository.getProducts(
      limit: 20,
      status: status,
    );
    state = either.fold(
      ProductsState.loadFailure,
      (paged) => ProductsState.loadSuccess(
        paged.items,
        nextCursor: paged.nextCursor,
        hasMore: paged.hasMore,
        activeFilter: status,
      ),
    );
  }

  Future<void> loadMoreProducts() async {
    state.maybeWhen(
      loadSuccess: (products, nextCursor, hasMore, activeFilter) async {
        if (!hasMore || nextCursor == null) return;
        final either = await _repository.getProducts(
          limit: 20,
          cursor: nextCursor,
          status: _activeFilter,
        );
        state = either.fold(
          (f) => ProductsState.loadFailure(f),
          (paged) => ProductsState.loadSuccess(
            [...products, ...paged.items],
            nextCursor: paged.nextCursor,
            hasMore: paged.hasMore,
            activeFilter: _activeFilter,
          ),
        );
      },
      orElse: () {},
    );
  }

  Future<void> updateStatus(String productId, VendorProductStatus status) async {
    state.maybeWhen(
      loadSuccess: (products, nextCursor, hasMore, filter) async {
        state = ProductsState.actionInProgress(products);
        final either = await _repository.updateProductStatus(productId, status);
        state = either.fold(
          (f) {
            _onActionFailure(products, f);
            return ProductsState.actionFailure(products, f);
          },
          (_) {
            final updated = products.map((p) {
              if (p.id == productId) return p.copyWith(status: status);
              return p;
            }).toList(growable: false);
            return ProductsState.loadSuccess(
              updated,
              nextCursor: nextCursor,
              hasMore: hasMore,
              activeFilter: filter,
            );
          },
        );
      },
      orElse: () {},
    );
  }

  Future<void> deleteProduct(String productId) async {
    state.maybeWhen(
      loadSuccess: (products, nextCursor, hasMore, filter) async {
        state = ProductsState.actionInProgress(products);
        final either = await _repository.deleteProduct(productId);
        state = either.fold(
          (f) {
            _onActionFailure(products, f);
            return ProductsState.actionFailure(products, f);
          },
          (_) {
            final updated = products.where((p) => p.id != productId).toList(growable: false);
            return ProductsState.loadSuccess(
              updated,
              nextCursor: nextCursor,
              hasMore: hasMore,
              activeFilter: filter,
            );
          },
        );
      },
      orElse: () {},
    );
  }

  Future<void> _onActionFailure(List<VendorProduct> products, NetworkExceptions failure) async {
    state = ProductsState.actionFailure(products, failure);
    await Future<void>.delayed(const Duration(seconds: 2));
    state.maybeWhen(
      actionFailure: (ps, _) {
        if (mounted) {
          state = ProductsState.loadSuccess(
            ps,
            nextCursor: _cursor,
            hasMore: false,
            activeFilter: _activeFilter,
          );
        }
      },
      orElse: () {},
    );
  }
}
