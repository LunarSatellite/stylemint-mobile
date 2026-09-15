import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/product_reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/repositories/in_store_repository.dart';

sealed class ProductReelsState {
  const ProductReelsState();
}

final class ProductReelsLoading extends ProductReelsState {
  const ProductReelsLoading();
}

final class ProductReelsLoaded extends ProductReelsState {
  const ProductReelsLoaded(this.reels);

  final List<ProductReel> reels;
}

final class ProductReelsFailed extends ProductReelsState {
  const ProductReelsFailed(this.failure);

  final NetworkExceptions failure;
}

/// Reels tagging one product, for the in-store product screen.
class ProductReelsNotifier extends StateNotifier<ProductReelsState> {
  ProductReelsNotifier(this._repository, this.productId)
    : super(const ProductReelsLoading()) {
    unawaited(load());
  }

  final InStoreRepository _repository;
  final String productId;

  Future<void> load() async {
    state = const ProductReelsLoading();
    final result = await _repository.getProductReels(productId);
    if (!mounted) return;
    state = result.fold(ProductReelsFailed.new, ProductReelsLoaded.new);
  }
}
