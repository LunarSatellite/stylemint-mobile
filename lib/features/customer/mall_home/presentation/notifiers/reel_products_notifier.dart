import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';

part 'reel_products_notifier.freezed.dart';

@freezed
abstract class ReelProductsState with _$ReelProductsState {
  const ReelProductsState._();

  const factory ReelProductsState.initial() = _Initial;
  const factory ReelProductsState.loadInProgress() = _LoadInProgress;

  /// The reel detail, whose tagged products carry the tag id used for
  /// commission attribution on add to cart.
  const factory ReelProductsState.loadSuccess(Reel reel) = _LoadSuccess;
  const factory ReelProductsState.loadFailure(NetworkExceptions failure) =
      _LoadFailure;
}

/// The quick product sheet: a reel's tagged products, from
/// `GET v1/public/reels/{id}`.
class ReelProductsNotifier extends StateNotifier<ReelProductsState> {
  ReelProductsNotifier(this._repository, {required this.reelId})
    : super(const ReelProductsState.initial()) {
    unawaited(load());
  }

  final ReelsRepository _repository;
  final String reelId;

  Future<void> load() async {
    state = const ReelProductsState.loadInProgress();
    final result = await _repository.getReelDetail(reelId);
    if (!mounted) return;
    state = result.fold(
      ReelProductsState.loadFailure,
      ReelProductsState.loadSuccess,
    );
  }
}
