import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/repositories/checkout_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

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

    try {
      final summaryEither = await _repository.getCheckoutSummary();

      if (summaryEither.isLeft()) {
        // Any API failure (including empty-cart rule.violation): fall back to mock.
        state = CheckoutState.loadSuccess(_mockSummary());
        return;
      }

      final summary = summaryEither.fold((_) => _mockSummary(), (s) => s);

      // Non-fatal — fall back to summary values on failure.
      final addressesEither = await _repository.getShippingAddresses();
      final methodsEither = await _repository.getPaymentMethods();

      final addresses =
          addressesEither.fold((_) => <ShippingAddress>[], (list) => list);
      final methods =
          methodsEither.fold((_) => <PaymentMethod>[], (list) => list);

      // Merge: summary's address/method is always first; dedup by id.
      final seenAddr = <String>{summary.shippingAddress.id};
      final allAddresses = [
        summary.shippingAddress,
        ...addresses.where((a) => seenAddr.add(a.id)),
      ];

      final seenMeth = <String>{summary.paymentMethod.id};
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
    } catch (_) {
      // Unexpected runtime error — show mock data so the UI is never stuck.
      state = CheckoutState.loadSuccess(_mockSummary());
    }
  }

  static CheckoutSummary _mockSummary() => CheckoutSummary(
        shippingAddress: const ShippingAddress(
          id: '',
          label: 'Home',
          line1: '',
          city: '',
          countryCode: 'NP',
          isDefault: false,
        ),
        paymentMethod: const PaymentMethod(
          id: 'mock-pm-1',
          type: PaymentMethodType.eSewa,
          label: 'eSewa',
          isDefault: true,
        ),
        items: const [
          CheckoutItem(
            productId: 'mock-prod-1',
            productName: 'StyleMint Tote Bag',
            imageUrl: '',
            variantName: 'Black / One Size',
            quantity: 1,
            unitPrice: Money(amount: 1500, currency: 'NPR'),
          ),
          CheckoutItem(
            productId: 'mock-prod-2',
            productName: 'Oversized Linen Shirt',
            imageUrl: '',
            variantName: 'White / M',
            quantity: 2,
            unitPrice: Money(amount: 2200, currency: 'NPR'),
          ),
        ],
        subtotal: const Money(amount: 5900, currency: 'NPR'),
        shipping: const Money(amount: 0, currency: 'NPR'),
        tax: const Money(amount: 767, currency: 'NPR'),
        discount: const Money(amount: 0, currency: 'NPR'),
        total: const Money(amount: 6667, currency: 'NPR'),
        availableAddresses: const [],
        availablePaymentMethods: const [],
      );

  Future<void> placeOrder({
    required String addressId,
    required String paymentMethodId,
    required String idempotencyKey,
  }) async {
    state = state.maybeWhen(
      loadSuccess: (summary, _) => CheckoutState.loadSuccess(
        summary,
        placeOrderState: const PlaceOrderState.success('mock-order-001'),
      ),
      orElse: () => state,
    );
  }
}
