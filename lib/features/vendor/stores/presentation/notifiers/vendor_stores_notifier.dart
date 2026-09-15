import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store_draft.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/repositories/vendor_stores_repository.dart';

sealed class VendorStoresState {
  const VendorStoresState();
}

final class VendorStoresLoading extends VendorStoresState {
  const VendorStoresLoading();
}

final class VendorStoresLoaded extends VendorStoresState {
  const VendorStoresLoaded(this.stores);

  /// Active stores only; archived ones get no new codes.
  final List<VendorStore> stores;
}

final class VendorStoresFailed extends VendorStoresState {
  const VendorStoresFailed(this.failure);

  final NetworkExceptions failure;
}

/// The vendor's stores: list, create, edit and archive.
class VendorStoresNotifier extends StateNotifier<VendorStoresState> {
  VendorStoresNotifier(this._repository) : super(const VendorStoresLoading()) {
    unawaited(load());
  }

  final VendorStoresRepository _repository;

  Future<void> load() async {
    state = const VendorStoresLoading();
    final result = await _repository.getStores();
    if (!mounted) return;
    state = result.fold(
      VendorStoresFailed.new,
      (stores) => VendorStoresLoaded(
        stores.where((store) => store.isActive).toList(growable: false),
      ),
    );
  }

  /// The loaded store with [storeId], if any.
  VendorStore? storeById(String storeId) {
    final current = state;
    return current is VendorStoresLoaded
        ? current.stores.firstWhereOrNull((store) => store.id == storeId)
        : null;
  }

  Future<Either<NetworkExceptions, VendorStore>> create(
    VendorStoreDraft draft,
  ) async {
    final result = await _repository.createStore(draft);
    if (mounted) result.fold((_) {}, _upsert);
    return result;
  }

  Future<Either<NetworkExceptions, VendorStore>> update(
    String storeId,
    VendorStoreDraft draft,
  ) async {
    final result = await _repository.updateStore(storeId, draft);
    if (mounted) result.fold((_) {}, _upsert);
    return result;
  }

  /// Returns the failure, or null once the store is gone from the list.
  Future<NetworkExceptions?> archive(String storeId) async {
    final result = await _repository.archiveStore(storeId);
    if (!mounted) return result.getLeft().toNullable();
    return result.fold((failure) => failure, (_) {
      _remove(storeId);
      return null;
    });
  }

  void _upsert(VendorStore store) {
    if (!store.isActive) {
      _remove(store.id);
      return;
    }
    final current = state;
    if (current is! VendorStoresLoaded) {
      unawaited(load());
      return;
    }
    final index = current.stores.indexWhere((s) => s.id == store.id);
    state = VendorStoresLoaded(
      index < 0
          ? [...current.stores, store]
          : [
              for (var i = 0; i < current.stores.length; i++)
                i == index ? store : current.stores[i],
            ],
    );
  }

  void _remove(String storeId) {
    final current = state;
    if (current is! VendorStoresLoaded) return;
    state = VendorStoresLoaded(
      current.stores
          .where((store) => store.id != storeId)
          .toList(growable: false),
    );
  }
}
