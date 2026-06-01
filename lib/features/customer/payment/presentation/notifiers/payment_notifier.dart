import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/domain/entities/payment_method.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/domain/repositories/payment_repository.dart';

part 'payment_notifier.freezed.dart';

@freezed
abstract class PaymentMethodsState with _$PaymentMethodsState {
  const PaymentMethodsState._();

  const factory PaymentMethodsState.initial() = _Initial;
  const factory PaymentMethodsState.loadInProgress() = _LoadInProgress;
  const factory PaymentMethodsState.loadSuccess(
    List<PaymentMethod> methods,
  ) = _LoadSuccess;
  const factory PaymentMethodsState.loadFailure(NetworkExceptions failure) = _LoadFailure;
}

class PaymentNotifier extends StateNotifier<PaymentMethodsState> {
  PaymentNotifier(this._repository) : super(const PaymentMethodsState.initial()) {
    unawaited(load());
  }

  final PaymentRepository _repository;

  Future<void> load() async {
    state = const PaymentMethodsState.loadInProgress();
    final either = await _repository.getPaymentMethods();
    state = either.fold(
      PaymentMethodsState.loadFailure,
      PaymentMethodsState.loadSuccess,
    );
  }

  Future<bool> addCard({
    required String cardNumber,
    required String expiry,
    required String cvv,
    required String cardholderName,
  }) async {
    final either = await _repository.addCard(
      cardNumber: cardNumber,
      expiry: expiry,
      cvv: cvv,
      cardholderName: cardholderName,
    );
    return either.fold((_) => false, (_) {
      unawaited(load());
      return true;
    });
  }

  Future<bool> delete(String id) async {
    final either = await _repository.deletePaymentMethod(id);
    return either.fold((_) => false, (_) {
      unawaited(load());
      return true;
    });
  }

  Future<bool> setDefault(String id) async {
    final either = await _repository.setDefault(id);
    return either.fold((_) => false, (_) {
      unawaited(load());
      return true;
    });
  }
}
