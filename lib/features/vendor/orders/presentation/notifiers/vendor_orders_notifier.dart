import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/bulk_action_result.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/packing_slip.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/repositories/vendor_orders_repository.dart';

part 'vendor_orders_notifier.freezed.dart';

@freezed
abstract class OrdersState with _$OrdersState {
  const OrdersState._();

  const factory OrdersState.initial() = _OInitial;
  const factory OrdersState.loadInProgress() = _OLoadInProgress;
  const factory OrdersState.loadSuccess(
    List<VendorOrder> orders, {
    required String? nextCursor,
    required bool hasMore,
    required String? activeFilter,
  }) = _OLoadSuccess;
  const factory OrdersState.loadFailure(NetworkExceptions failure) = _OLoadFailure;
}

@freezed
abstract class OrderDetailState with _$OrderDetailState {
  const OrderDetailState._();

  const factory OrderDetailState.initial() = _ODInitial;
  const factory OrderDetailState.loadInProgress() = _ODLoadInProgress;
  const factory OrderDetailState.loadSuccess(VendorOrder order) =
      _ODLoadSuccess;
  const factory OrderDetailState.loadFailure(NetworkExceptions failure) =
      _ODLoadFailure;
  const factory OrderDetailState.actionInProgress(VendorOrder order) =
      _ODActionInProgress;
  const factory OrderDetailState.actionFailure(VendorOrder order, NetworkExceptions failure) =
      _ODActionFailure;
}

class VendorOrdersNotifier extends StateNotifier<OrdersState> {
  VendorOrdersNotifier(this._repository)
      : super(const OrdersState.initial()) {
    unawaited(loadOrders());
  }

  final VendorOrdersRepository _repository;

  String? _activeFilter;

  Future<void> loadOrders({String? status}) async {
    state = const OrdersState.loadInProgress();
    _activeFilter = status;
    final either = await _repository.getOrders(
      limit: 20,
      status: status,
    );
    state = either.fold(
      OrdersState.loadFailure,
      (paged) => OrdersState.loadSuccess(
        paged.items,
        nextCursor: paged.nextCursor,
        hasMore: paged.hasMore,
        activeFilter: status,
      ),
    );
  }

  Future<void> loadMoreOrders() async {
    state.maybeWhen(
      loadSuccess: (orders, nextCursor, hasMore, activeFilter) async {
        if (!hasMore || nextCursor == null) return;
        final either = await _repository.getOrders(
          limit: 20,
          cursor: nextCursor,
          status: _activeFilter,
        );
        state = either.fold(
          (f) => OrdersState.loadFailure(f),
          (paged) => OrdersState.loadSuccess(
            [...orders, ...paged.items],
            nextCursor: paged.nextCursor,
            hasMore: paged.hasMore,
            activeFilter: _activeFilter,
          ),
        );
      },
      orElse: () {},
    );
  }

  /// Single-id "Mark as Shipped" — used from the Ready-to-Ship list's 3-dot
  /// menu and the bulk select bar. Reloads the list on success so the item
  /// drops out of the To-Ship bucket.
  Future<bool> markReadyToShip(String orderId) async {
    final either = await _repository.markReadyToShip(orderId);
    return either.fold((_) => false, (_) {
      unawaited(loadOrders(status: _activeFilter));
      return true;
    });
  }

  Future<BulkActionResult?> bulkMarkReadyToShip(List<String> orderIds) async {
    final either = await _repository.bulkMarkReadyToShip(orderIds);
    return either.fold((_) => null, (result) {
      unawaited(loadOrders(status: _activeFilter));
      return result;
    });
  }

  Future<PackingSlip?> getPackingSlip(String orderId) async {
    final either = await _repository.getPackingSlip(orderId);
    return either.fold((_) => null, (slip) => slip);
  }

  Future<BulkActionResult?> bulkPackingSlips(List<String> orderIds) async {
    final either = await _repository.bulkPackingSlips(orderIds);
    return either.fold((_) => null, (result) => result);
  }

  /// "Assign Tracking No." from the Orders Awaiting Tracking list.
  Future<bool> addTracking(
    String orderId, {
    required String carrier,
    required String trackingNumber,
  }) async {
    final either = await _repository.addTracking(
      orderId,
      carrier: carrier,
      trackingNumber: trackingNumber,
    );
    return either.fold((_) => false, (_) {
      unawaited(loadOrders(status: _activeFilter));
      return true;
    });
  }
}

class VendorOrderDetailNotifier extends StateNotifier<OrderDetailState> {
  VendorOrderDetailNotifier(this._repository)
      : super(const OrderDetailState.initial());

  final VendorOrdersRepository _repository;

  Future<void> loadOrder(String orderId) async {
    state = const OrderDetailState.loadInProgress();
    final either = await _repository.getOrderDetail(orderId);
    state = either.fold(
      (failure) => OrderDetailState.loadFailure(failure),
      OrderDetailState.loadSuccess,
    );
  }

  Future<void> updateStatus(VendorOrderStatus newStatus) async {
    state.maybeWhen(
      loadSuccess: (order) async {
        state = OrderDetailState.actionInProgress(order);
        final either = await _repository.updateOrderStatus(order.id, newStatus);
        state = either.fold(
          (f) {
            _onActionFailure(order, f);
            return OrderDetailState.actionFailure(order, f);
          },
          (updated) => OrderDetailState.loadSuccess(updated),
        );
      },
      orElse: () {},
    );
  }

  Future<void> handleReturn(String action) async {
    state.maybeWhen(
      loadSuccess: (order) async {
        state = OrderDetailState.actionInProgress(order);
        final either = await _repository.handleReturn(order.id, action);
        state = either.fold(
          (f) {
            _onActionFailure(order, f);
            return OrderDetailState.actionFailure(order, f);
          },
          (_) => OrderDetailState.loadSuccess(
            order.copyWith(status: VendorOrderStatus.returned),
          ),
        );
      },
      orElse: () {},
    );
  }

  /// "Mark as Shipped" from the order detail screen.
  Future<void> markReadyToShip() async {
    state.maybeWhen(
      loadSuccess: (order) async {
        state = OrderDetailState.actionInProgress(order);
        final either = await _repository.markReadyToShip(order.id);
        state = either.fold(
          (f) {
            _onActionFailure(order, f);
            return OrderDetailState.actionFailure(order, f);
          },
          OrderDetailState.loadSuccess,
        );
      },
      orElse: () {},
    );
  }

  Future<void> addTracking({
    required String carrier,
    required String trackingNumber,
  }) async {
    state.maybeWhen(
      loadSuccess: (order) async {
        state = OrderDetailState.actionInProgress(order);
        final either = await _repository.addTracking(
          order.id,
          carrier: carrier,
          trackingNumber: trackingNumber,
        );
        state = either.fold(
          (f) {
            _onActionFailure(order, f);
            return OrderDetailState.actionFailure(order, f);
          },
          OrderDetailState.loadSuccess,
        );
      },
      orElse: () {},
    );
  }

  Future<void> markDelivered() async {
    state.maybeWhen(
      loadSuccess: (order) async {
        state = OrderDetailState.actionInProgress(order);
        final either = await _repository.markDelivered(order.id);
        state = either.fold(
          (f) {
            _onActionFailure(order, f);
            return OrderDetailState.actionFailure(order, f);
          },
          OrderDetailState.loadSuccess,
        );
      },
      orElse: () {},
    );
  }

  Future<PackingSlip?> getPackingSlip() async {
    final order = state.maybeWhen(
      loadSuccess: (o) => o,
      actionInProgress: (o) => o,
      actionFailure: (o, _) => o,
      orElse: () => null,
    );
    if (order == null) return null;
    final either = await _repository.getPackingSlip(order.id);
    return either.fold((_) => null, (slip) => slip);
  }

  Future<void> _onActionFailure(VendorOrder order, NetworkExceptions failure) async {
    state = OrderDetailState.actionFailure(order, failure);
    await Future<void>.delayed(const Duration(seconds: 2));
    state.maybeWhen(
      actionFailure: (o, _) {
        if (mounted) {
          state = OrderDetailState.loadSuccess(o);
        }
      },
      orElse: () {},
    );
  }
}
