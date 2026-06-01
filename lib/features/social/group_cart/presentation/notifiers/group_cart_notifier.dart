import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/domain/entities/group_cart.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/domain/repositories/group_cart_repository.dart';

part 'group_cart_notifier.freezed.dart';

@freezed
abstract class GroupCartsState with _$GroupCartsState {
  const GroupCartsState._();

  const factory GroupCartsState.initial() = _GroupCartsInitial;
  const factory GroupCartsState.loadInProgress() = _GroupCartsLoadInProgress;
  const factory GroupCartsState.loadSuccess(List<GroupCart> carts) =
      _GroupCartsLoadSuccess;
  const factory GroupCartsState.loadFailure(NetworkExceptions failure) =
      _GroupCartsLoadFailure;
}

@freezed
abstract class GroupCartDetailState with _$GroupCartDetailState {
  const GroupCartDetailState._();

  const factory GroupCartDetailState.initial() = _GroupCartDetailInitial;
  const factory GroupCartDetailState.loadInProgress() =
      _GroupCartDetailLoadInProgress;
  const factory GroupCartDetailState.loadSuccess(GroupCart cart) =
      _GroupCartDetailLoadSuccess;
  const factory GroupCartDetailState.loadFailure(NetworkExceptions failure) =
      _GroupCartDetailLoadFailure;
}

class GroupCartNotifier extends StateNotifier<GroupCartsState> {
  GroupCartNotifier(this._repository)
      : super(const GroupCartsState.initial()) {
    unawaited(loadAll());
  }

  final GroupCartRepository _repository;

  Future<void> loadAll() async {
    state = const GroupCartsState.loadInProgress();
    final either = await _repository.getGroupCarts();
    state = either.fold(
      GroupCartsState.loadFailure,
      GroupCartsState.loadSuccess,
    );
  }

  Future<Either<NetworkExceptions, GroupCart>> create(String name) async {
    final either = await _repository.createGroupCart(name);
    either.fold(
      (_) {},
      (_) => unawaited(loadAll()),
    );
    return either;
  }

  Future<Either<NetworkExceptions, GroupCart>> join(String inviteCode) async {
    final either = await _repository.joinGroupCart(inviteCode);
    either.fold(
      (_) {},
      (_) => unawaited(loadAll()),
    );
    return either;
  }

  Future<Either<NetworkExceptions, Unit>> checkout(String cartId) async {
    final either = await _repository.checkoutGroupCart(cartId);
    either.fold(
      (_) {},
      (_) => unawaited(loadAll()),
    );
    return either;
  }
}

class GroupCartDetailNotifier extends StateNotifier<GroupCartDetailState> {
  GroupCartDetailNotifier(this._repository, String cartId)
      : super(const GroupCartDetailState.initial()) {
    unawaited(loadCart(cartId));
  }

  final GroupCartRepository _repository;

  Future<void> loadCart(String cartId) async {
    state = const GroupCartDetailState.loadInProgress();
    final either = await _repository.getGroupCart(cartId);
    state = either.fold(
      GroupCartDetailState.loadFailure,
      GroupCartDetailState.loadSuccess,
    );
  }

  Future<Either<NetworkExceptions, GroupCartItem>> addItem(
    String cartId,
    String productId,
    int qty,
  ) async {
    final either = await _repository.addToGroupCart(cartId, productId, qty);
    either.fold(
      (_) {},
      (_) => unawaited(loadCart(cartId)),
    );
    return either;
  }

  Future<Either<NetworkExceptions, Unit>> removeItem(
    String cartId,
    String itemId,
  ) async {
    final either = await _repository.removeFromGroupCart(cartId, itemId);
    either.fold(
      (_) {},
      (_) => unawaited(loadCart(cartId)),
    );
    return either;
  }

  Future<Either<NetworkExceptions, Unit>> checkout(String cartId) async {
    final either = await _repository.checkoutGroupCart(cartId);
    either.fold(
      (_) {},
      (_) => unawaited(loadCart(cartId)),
    );
    return either;
  }
}
