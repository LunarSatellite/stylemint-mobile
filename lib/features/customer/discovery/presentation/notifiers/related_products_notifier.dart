import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';

part 'related_products_notifier.freezed.dart';

@freezed
abstract class RelatedProductsState with _$RelatedProductsState {
  const RelatedProductsState._();

  const factory RelatedProductsState.initial() = _Initial;
  const factory RelatedProductsState.loadInProgress() = _LoadInProgress;
  const factory RelatedProductsState.loadSuccess(
    List<RelatedProduct> products,
  ) = _LoadSuccess;
  const factory RelatedProductsState.loadFailure(NetworkExceptions failure) =
      _LoadFailure;
}

class RelatedProductsNotifier extends StateNotifier<RelatedProductsState> {
  RelatedProductsNotifier(this._repository, {required String productId})
    : super(const RelatedProductsState.initial()) {
    _fetch(productId);
  }

  final DiscoveryRepository _repository;

  Future<void> _fetch(String productId) async {
    state = const RelatedProductsState.loadInProgress();
    final either = await _repository.getRelatedProducts(productId);
    state = either.fold(
      RelatedProductsState.loadFailure,
      RelatedProductsState.loadSuccess,
    );
  }
}
