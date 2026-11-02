import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
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
  CartNotifier(this._repository, {CartBundlesRepository? bundles})
    : _bundles = bundles,
      super(const CartState.initial()) {
    unawaited(fetchCart());
  }

  final CartRepository _repository;

  /// The bundle group calls; null where the app wires no bundles (old
  /// tests, the preview build), and every bundle action then just reloads.
  final CartBundlesRepository? _bundles;

  /// Scales bundle group [groupId] to [quantity] bundles. Returns the
  /// failure, or null when it worked. A refused change keeps the cart on
  /// screen (it does not turn into the error page) and reloads it.
  Future<NetworkExceptions?> setBundleQuantity(String groupId, int quantity) =>
      _bundleCall((r) => r.setBundleQuantity(groupId, quantity));

  /// Takes the whole bundle [groupId] out of the cart.
  Future<NetworkExceptions?> removeBundle(String groupId) =>
      _bundleCall((r) => r.removeBundle(groupId));

  /// Keeps bundle [groupId]'s lines at their list prices.
  Future<NetworkExceptions?> unbundle(String groupId) =>
      _bundleCall((r) => r.unbundle(groupId));

  Future<NetworkExceptions?> _bundleCall(
    Future<Either<NetworkExceptions, Cart>> Function(CartBundlesRepository r)
    call,
  ) async {
    final repo = _bundles;
    if (repo == null) {
      await fetchCart();
      return const NetworkExceptions.unexpectedError();
    }
    final either = await call(repo);
    final failure = either.fold<NetworkExceptions?>((l) => l, (_) => null);
    if (failure == null) {
      either.fold((_) {}, (cart) => state = CartState.loadSuccess(cart));
      return null;
    }
    final refreshed = await _repository.getCart();
    refreshed.fold((_) {}, (cart) => state = CartState.loadSuccess(cart));
    return failure;
  }

  /// Clears any leftover cart state from a previous account's session.
  /// The provider is an app-lifetime singleton, so without this a fresh
  /// login (or a brand-new signup) after another account's session on the
  /// same device kept showing that other account's cart until the next
  /// manual mutation happened to overwrite it.
  void reset() {
    state = const CartState.initial();
    unawaited(fetchCart());
  }

  /// Shows [cart] as the server returned it from a write made elsewhere —
  /// a stay or trip added on its item page goes through the services'
  /// own repository (service cart contract v1), which answers with the cart.
  void showCart(Cart cart) => state = CartState.loadSuccess(cart);

  Future<void> fetchCart() async {
    state = const CartState.loadInProgress();
    final either = await _repository.getCart();
    state = either.fold(
      CartState.loadFailure,
      CartState.loadSuccess,
    );
  }

  /// Returns whether the add succeeded. Callers must use this return value
  /// rather than re-reading [state] afterward — under rapid repeat taps, a
  /// later overlapping call can flip state back to loadInProgress before an
  /// earlier call's post-await check runs, making that earlier call see the
  /// wrong (in-progress) state even though its own request actually
  /// succeeded.
  Future<bool> addItem({
    required String productId,
    required int quantity,
    String? variantId,
    String? reelTagContextId,
    required String idempotencyKey,
  }) async {
    state = const CartState.loadInProgress();
    final either = await _repository.addToCart(
      productId: productId,
      quantity: quantity,
      variantId: variantId,
      reelTagContextId: reelTagContextId,
      idempotencyKey: idempotencyKey,
    );
    state = either.fold(
      CartState.loadFailure,
      CartState.loadSuccess,
    );
    return either.isRight();
  }

  Future<void> updateItem({
    required String itemId,
    required int quantity,
  }) async {
    final current = state;
    if (current is _LoadSuccess) {
      // Optimistic update: reflect the new quantity immediately in the UI.
      final optimistic = current.cart.copyWith(
        items: current.cart.items
            .map((i) => i.id == itemId ? i.copyWith(quantity: quantity) : i)
            .toList(),
      );
      state = CartState.loadSuccess(optimistic);
    }
    final either = await _repository.updateCartItem(
      itemId: itemId,
      quantity: quantity,
    );
    // Server response replaces optimistic state (includes recalculated totals).
    state = either.fold(
      CartState.loadFailure,
      CartState.loadSuccess,
    );
  }

  Future<void> removeItem(String itemId) async {
    final current = state;
    if (current is _LoadSuccess) {
      // Optimistic update: remove the item immediately in the UI.
      final optimistic = current.cart.copyWith(
        items: current.cart.items.where((i) => i.id != itemId).toList(),
      );
      state = CartState.loadSuccess(optimistic);
    }
    final either = await _repository.removeCartItem(itemId);
    // Server response replaces optimistic state (includes recalculated totals).
    state = either.fold(
      CartState.loadFailure,
      CartState.loadSuccess,
    );
  }

  Future<bool> applyPromo(String code) async {
    final either = await _repository.applyPromo(code);
    state = either.fold(CartState.loadFailure, CartState.loadSuccess);
    return either.isRight();
  }

  Future<bool> removePromo() async {
    final either = await _repository.removePromo();
    state = either.fold(CartState.loadFailure, CartState.loadSuccess);
    return either.isRight();
  }

  Future<bool> saveForLater(String lineId) async {
    final either = await _repository.saveForLater(lineId);
    state = either.fold(CartState.loadFailure, CartState.loadSuccess);
    return either.isRight();
  }
}
