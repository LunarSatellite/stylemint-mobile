import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
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
