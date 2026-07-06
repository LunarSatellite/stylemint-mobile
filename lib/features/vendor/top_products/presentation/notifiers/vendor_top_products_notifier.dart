import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/top_products/domain/entities/vendor_top_product.dart';
import 'package:stylemint_mobile_frontend/features/vendor/top_products/domain/repositories/vendor_top_products_repository.dart';

part 'vendor_top_products_notifier.freezed.dart';

@freezed
abstract class VendorTopProductsState with _$VendorTopProductsState {
  const factory VendorTopProductsState.initial() = _Initial;
  const factory VendorTopProductsState.loadInProgress() = _LoadInProgress;
  const factory VendorTopProductsState.loadSuccess(
    List<VendorTopProduct> products,
  ) = _LoadSuccess;
  const factory VendorTopProductsState.loadFailure(NetworkExceptions failure) =
      _LoadFailure;
}

class VendorTopProductsNotifier extends StateNotifier<VendorTopProductsState> {
  VendorTopProductsNotifier(this._repository)
    : super(const VendorTopProductsState.initial()) {
    unawaited(load());
  }

  final VendorTopProductsRepository _repository;

  Future<void> load({DateTime? fromUtc, DateTime? toUtc, int? limit}) async {
    state = const VendorTopProductsState.loadInProgress();
    final either = await _repository.getTopProducts(
      fromUtc: fromUtc,
      toUtc: toUtc,
      limit: limit,
    );
    state = either.fold(
      VendorTopProductsState.loadFailure,
      VendorTopProductsState.loadSuccess,
    );
  }
}
