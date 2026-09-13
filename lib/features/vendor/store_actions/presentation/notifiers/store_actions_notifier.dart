import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/domain/entities/store_actions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/domain/repositories/store_actions_repository.dart';

sealed class StoreActionsState {
  const StoreActionsState();
}

final class StoreActionsLoading extends StoreActionsState {
  const StoreActionsLoading();
}

final class StoreActionsLoaded extends StoreActionsState {
  const StoreActionsLoaded(this.queue);

  final StoreActionQueue queue;
}

final class StoreActionsFailed extends StoreActionsState {
  const StoreActionsFailed(this.failure);

  final NetworkExceptions failure;
}

/// Loads the vendor's store to-do list.
class StoreActionsNotifier extends StateNotifier<StoreActionsState> {
  StoreActionsNotifier(this._repository) : super(const StoreActionsLoading()) {
    unawaited(load());
  }

  final StoreActionsRepository _repository;
  int _requestSeq = 0;

  /// Shows the page loader, then the list or a retryable error.
  Future<void> load() => _fetch(showLoader: true);

  /// Re-checks the list while keeping the current one on screen, e.g. after
  /// the vendor comes back from fixing a product.
  Future<void> refresh() => _fetch(showLoader: false);

  Future<void> _fetch({required bool showLoader}) async {
    final seq = ++_requestSeq;
    if (showLoader || state is! StoreActionsLoaded) {
      state = const StoreActionsLoading();
    }
    final result = await _repository.getStoreActions();
    // A newer load started meanwhile; its answer wins.
    if (!mounted || seq != _requestSeq) return;
    state = result.fold(StoreActionsFailed.new, StoreActionsLoaded.new);
  }
}
