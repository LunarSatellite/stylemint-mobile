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
  // Despite the name (kept for API-shape familiarity with the repository
  // method's return type), this carries the order NUMBER (e.g.
  // "NK2026-00001") — every order route is keyed by that, not the internal
  // orderId GUID. See CheckoutRemoteDataSource.placeOrder's doc comment.
  const factory PlaceOrderState.success(String orderId) = _OrderSuccess;
  const factory PlaceOrderState.failure(NetworkExceptions failure) =
      _OrderFailure;
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

    try {
      final summaryEither = await _repository.getCheckoutSummary();
      await summaryEither.fold(
        (f) async => state = CheckoutState.loadFailure(f),
        (summary) => _loadWithSummary(summary),
      );
    } catch (_) {
      state = const CheckoutState.loadFailure(
        NetworkExceptions.unexpectedError(),
      );
    }
  }

  Future<void> _loadWithSummary(CheckoutSummary summary) async {
    // Non-fatal — fall back to empty lists on failure.
    final addressesEither = await _repository.getShippingAddresses();
    final methodsEither = await _repository.getPaymentMethods();
    final deliveryEither = await _repository.getDeliveryChoices();

    final addresses = addressesEither.fold(
      (_) => <ShippingAddress>[],
      (list) => list,
    );
    final methods = methodsEither.fold(
      (_) => <PaymentMethod>[],
      (list) => list,
    );
    final delivery = deliveryEither.fold(
      (_) => const DeliveryChoices(choices: [], emissionsNote: ''),
      (value) => value,
    );

    // A fresh checkout session carries no address/payment of its own (see
    // CheckoutSummaryDto.toDomain) — default to the account's default saved
    // one, falling back to the sentinel "none selected" from the session.
    final defaultAddress = addresses.isEmpty
        ? summary.shippingAddress
        : addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => addresses.first,
          );
    final defaultMethod = methods.isEmpty
        ? const PaymentMethod(
            id: 'cod',
            type: PaymentMethodType.cod,
            label: 'Cash on Delivery',
            isDefault: true,
          )
        : methods.firstWhere((m) => m.isDefault, orElse: () => methods.first);

    state = CheckoutState.loadSuccess(
      summary.copyWith(
        shippingAddress: defaultAddress,
        paymentMethod: defaultMethod,
        availableAddresses: addresses,
        availablePaymentMethods: methods,
        deliveryChoices: delivery.choices,
        emissionsNote: delivery.emissionsNote,
        pickupNote: delivery.pickupNote,
        deliveryPreference: delivery.preferences,
        deliveryConsolidation: delivery.consolidation,
      ),
    );
  }

  Future<void> selectDeliveryChoice(DeliveryChoice choice) async {
    final summary = state.maybeWhen(
      loadSuccess: (s, _) => s,
      orElse: () => null,
    );
    if (summary == null || choice.selected) return;
    final result = await _repository.selectDeliveryChoice(choice);
    result.fold(
      (_) {},
      (_) {
        final updated = summary.deliveryChoices
            .map((item) => item.copyWith(selected: identical(item, choice)))
            .toList(growable: false);
        state = CheckoutState.loadSuccess(
          summary.copyWith(deliveryChoices: updated),
        );
      },
    );
  }

  Future<void> updateDeliveryPreference(DeliveryPreference preference) async {
    final summary = state.maybeWhen(
      loadSuccess: (value, _) => value,
      orElse: () => null,
    );
    if (summary == null) return;

    final result = await _repository.updateDeliveryPreference(preference);
    await result.fold((_) async {}, (saved) async {
      final refreshed = await _repository.getDeliveryChoices();
      refreshed.fold(
        (_) => state = CheckoutState.loadSuccess(
          summary.copyWith(deliveryPreference: saved),
        ),
        (delivery) => state = CheckoutState.loadSuccess(
          summary.copyWith(
            deliveryPreference: delivery.preferences,
            deliveryConsolidation: delivery.consolidation,
            deliveryChoices: delivery.choices,
            emissionsNote: delivery.emissionsNote,
            pickupNote: delivery.pickupNote,
          ),
        ),
      );
    });
  }

  Future<void> placeOrder({
    required String? addressId,
    required PaymentMethodType paymentMethod,
    required String idempotencyKey,
  }) async {
    final summary = state.maybeWhen(
      loadSuccess: (s, _) => s,
      orElse: () => null,
    );
    if (summary == null) return;

    state = CheckoutState.loadSuccess(
      summary,
      placeOrderState: const PlaceOrderState.processing(),
    );

    final either = await _repository.placeOrder(
      addressId: addressId,
      paymentMethod: paymentMethod,
      idempotencyKey: idempotencyKey,
    );

    // Stashed outside the freezed PlaceOrderState (which only carries the
    // order number, for API-shape/back-compat reasons — see its doc
    // comment) so the checkout screen can decide whether to send the
    // customer to finish payment before treating the order as placed.
    // Cleared on every new attempt so a stale redirect from a previous
    // call is never accidentally reused.
    lastPlaceOrderResult = either.fold((_) => null, (r) => r);

    state = CheckoutState.loadSuccess(
      summary,
      placeOrderState: either.fold(
        PlaceOrderState.failure,
        (result) => PlaceOrderState.success(result.orderNumber),
      ),
    );
  }

  /// Set alongside [PlaceOrderState.success] on every `placeOrder()` call
  /// (including failures, where it's null) — carries whether the customer
  /// still needs to complete payment via [PlaceOrderResult.paymentRedirectUrl]
  /// before the order can be treated as paid.
  PlaceOrderResult? lastPlaceOrderResult;
}
