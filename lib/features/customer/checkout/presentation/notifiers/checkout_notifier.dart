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
    state = const CheckoutState.loadInProgress();

    final summaryEither = await _repository.getCheckoutSummary();

    if (summaryEither.isLeft()) {
      summaryEither.fold(
        (failure) => state = CheckoutState.loadFailure(failure),
        (_) {},
      );
      return;
    }

    final summary = summaryEither.fold((_) => throw StateError(''), (s) => s);

    // Load addresses and payment methods in parallel; non-fatal — fall back to
    // the values already embedded in the summary.
    final addressesEither = await _repository.getShippingAddresses();
    final methodsEither = await _repository.getPaymentMethods();

    final addresses =
        addressesEither.fold((_) => <ShippingAddress>[], (list) => list);
    final methods =
        methodsEither.fold((_) => <PaymentMethod>[], (list) => list);

    // Merge: ensure the summary's selected address/method are always first
    // and dedup by id so they don't appear twice.
    final seenAddr = <String>{};
    final allAddresses = [
      summary.shippingAddress,
      ...addresses.where((a) => seenAddr.add(a.id)),
    ];

    final seenMeth = <String>{};
    final allMethods = [
      summary.paymentMethod,
      ...methods.where((m) => seenMeth.add(m.id)),
    ];

    state = CheckoutState.loadSuccess(
      summary.copyWith(
        availableAddresses: allAddresses,
        availablePaymentMethods: allMethods,
      ),
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
