import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';

part 'product_detail_notifier.freezed.dart';

@freezed
abstract class ProductDetailState with _$ProductDetailState {
  const ProductDetailState._();

  const factory ProductDetailState.initial() = _Initial;
  const factory ProductDetailState.loadInProgress() = _LoadInProgress;
  const factory ProductDetailState.loadSuccess(ProductDetail product) =
      _LoadSuccess;
  const factory ProductDetailState.loadFailure(NetworkExceptions failure) = _LoadFailure;
}

class ProductDetailNotifier extends StateNotifier<ProductDetailState> {
  ProductDetailNotifier(this._repository)
    : super(const ProductDetailState.initial());

  final DiscoveryRepository _repository;

  Future<void> loadProduct(String productId) async {
    state = const ProductDetailState.loadInProgress();
    final either = await _repository.getProductDetail(productId);
    state = either.fold(
      ProductDetailState.loadFailure,
      ProductDetailState.loadSuccess,
    );
  }

  Future<bool> addToCart({
    required String productId,
    required int qty,
    String? variantId,
  }) async {
    final either = await _repository.addToCart(
      productId: productId,
      qty: qty,
      variantId: variantId,
    );
    final result = either.fold(
      (_) => false,
      (_) => true,
    );
    if (result) {
      await _refreshProduct(productId);
    }
    return result;
  }

  Future<bool> toggleSave(String productId) async {
    final either = await _repository.toggleSaved(productId);
    return either.fold(
      (_) => false,
      (isSaved) {
        _updateSavedState(isSaved);
        return true;
      },
    );
  }

  Future<void> _refreshProduct(String productId) async {
    try {
      final either = await _repository.getProductDetail(productId);
      either.fold((_) {}, (product) {
        state = ProductDetailState.loadSuccess(product);
      });
    } catch (_) {}
  }

  void _updateSavedState(bool isSaved) {
    state.whenOrNull(loadSuccess: (product) {
      state = ProductDetailState.loadSuccess(product.copyWith(isSaved: isSaved));
    });
  }
}
