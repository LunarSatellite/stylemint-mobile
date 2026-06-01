import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';

part 'cart_notifier.freezed.dart';

@freezed
abstract class CartState with _$CartState {
  const CartState._();

  const factory CartState.initial() = _Initial;
  const factory CartState.loadInProgress() = _LoadInProgress;
  const factory CartState.loadSuccess(Cart cart) = _LoadSuccess;
  const factory CartState.loadFailure(NetworkExceptions failure) = _LoadFailure;
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(this._repository) : super(const CartState.initial()) {
    unawaited(fetchCart());
  }

  final CartRepository _repository;

  Future<void> fetchCart() async {
    state = const CartState.loadInProgress();
    final either = await _repository.getCart();
    state = either.fold(
      CartState.loadFailure,
      CartState.loadSuccess,
    );
  }

  Future<void> addItem({
    required String productId,
    required int quantity,
    String? variantId,
    required String idempotencyKey,
  }) async {
    state = const CartState.loadInProgress();
    final either = await _repository.addToCart(
      productId: productId,
      quantity: quantity,
      variantId: variantId,
      idempotencyKey: idempotencyKey,
    );
    state = either.fold(
      CartState.loadFailure,
      CartState.loadSuccess,
    );
  }

  Future<void> updateItem({
    required String itemId,
    required int quantity,
  }) async {
    final current = state;
    if (current is _LoadSuccess) {
      state = CartState.loadSuccess(current.cart);
    }
    final either = await _repository.updateCartItem(
      itemId: itemId,
      quantity: quantity,
    );
    state = either.fold(
      CartState.loadFailure,
      CartState.loadSuccess,
    );
  }

  Future<void> removeItem(String itemId) async {
    final current = state;
    if (current is _LoadSuccess) {
      state = CartState.loadSuccess(current.cart);
    }
    final either = await _repository.removeCartItem(itemId);
    state = either.fold(
      CartState.loadFailure,
      CartState.loadSuccess,
    );
  }
}
