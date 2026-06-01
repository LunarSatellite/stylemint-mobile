import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/repositories/shipping_repository.dart';

part 'shipping_notifier.freezed.dart';

@freezed
abstract class AddressesState with _$AddressesState {
  const AddressesState._();

  const factory AddressesState.initial() = _Initial;
  const factory AddressesState.loadInProgress() = _LoadInProgress;
  const factory AddressesState.loadSuccess(
    List<ShippingAddress> addresses,
  ) = _LoadSuccess;
  const factory AddressesState.loadFailure(NetworkExceptions failure) = _LoadFailure;
}

class AddressNotifier extends StateNotifier<AddressesState> {
  AddressNotifier(this._repository) : super(const AddressesState.initial()) {
    unawaited(load());
  }

  final ShippingRepository _repository;

  Future<void> load() async {
    state = const AddressesState.loadInProgress();
    final either = await _repository.getAddresses();
    state = either.fold(
      AddressesState.loadFailure,
      AddressesState.loadSuccess,
    );
  }

  Future<bool> add(ShippingAddress address) async {
    final either = await _repository.addAddress(address);
    return either.fold((_) => false, (_) {
      unawaited(load());
      return true;
    });
  }

  Future<bool> update(String id, ShippingAddress address) async {
    final either = await _repository.updateAddress(id, address);
    return either.fold((_) => false, (_) {
      unawaited(load());
      return true;
    });
  }

  Future<bool> delete(String id) async {
    final either = await _repository.deleteAddress(id);
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
