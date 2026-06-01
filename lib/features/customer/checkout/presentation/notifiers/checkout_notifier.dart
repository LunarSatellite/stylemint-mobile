import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/repositories/checkout_repository.dart';

part 'checkout_notifier.freezed.dart';

@freezed
abstract class PlaceOrderState with _$PlaceOrderState {
  const PlaceOrderState._();

  const factory PlaceOrderState.initial() = _OrderInitial;
  const factory PlaceOrderState.processing() = _OrderProcessing;
  const factory PlaceOrderState.success(String orderId) = _OrderSuccess;
  const factory PlaceOrderState.failure(NetworkExceptions failure) = _OrderFailure;
}

@freezed
abstract class CheckoutState with _$CheckoutState {
  const CheckoutState._();

  const factory CheckoutState.initial({
    @Default(PlaceOrderState.initial()) PlaceOrderState placeOrderState,
  }) = _Initial;

  const factory CheckoutState.loadInProgress({
    @Default(PlaceOrderState.initial()) PlaceOrderState placeOrderState,
  }) = _LoadInProgress;

  const factory CheckoutState.loadSuccess(
    CheckoutSummary summary, {
    @Default(PlaceOrderState.initial()) PlaceOrderState placeOrderState,
  }) = _LoadSuccess;

  const factory CheckoutState.loadFailure(
    NetworkExceptions failure, {
    @Default(PlaceOrderState.initial()) PlaceOrderState placeOrderState,
  }) = _LoadFailure;
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier(this._repository) : super(const CheckoutState.initial()) {
    unawaited(load());
  }

  final CheckoutRepository _repository;

  Future<void> load() async {
    state = state.maybeWhen(
      loadSuccess: (summary, _) => const CheckoutState.loadInProgress(),
      orElse: () => const CheckoutState.loadInProgress(),
    );
    final either = await _repository.getCheckoutSummary();
    state = either.fold(
      (failure) => CheckoutState.loadFailure(failure),
      (summary) => CheckoutState.loadSuccess(summary),
    );
  }

  Future<void> placeOrder({
    required String addressId,
    required String paymentMethodId,
    required String idempotencyKey,
  }) async {
    state = state.maybeWhen(
      loadSuccess: (summary, _) => CheckoutState.loadSuccess(
        summary,
        placeOrderState: const PlaceOrderState.processing(),
      ),
      orElse: () => state,
    );

    final either = await _repository.placeOrder(
      addressId: addressId,
      paymentMethodId: paymentMethodId,
      idempotencyKey: idempotencyKey,
    );

    state = either.fold(
      (failure) => state.maybeWhen(
        loadSuccess: (summary, _) => CheckoutState.loadSuccess(
          summary,
          placeOrderState: PlaceOrderState.failure(failure),
        ),
        orElse: () => state,
      ),
      (orderId) => state.maybeWhen(
        loadSuccess: (summary, _) => CheckoutState.loadSuccess(
          summary,
          placeOrderState: PlaceOrderState.success(orderId),
        ),
        orElse: () => state,
      ),
    );
  }
}
