import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';

part 'track_orders_notifier.freezed.dart';

@freezed
abstract class TrackOrdersState with _$TrackOrdersState {
  const TrackOrdersState._();

  const factory TrackOrdersState.initial() = _Initial;
  const factory TrackOrdersState.loadInProgress() = _LoadInProgress;
  const factory TrackOrdersState.loadSuccess(List<TrackedOrder> orders) =
      _LoadSuccess;
  const factory TrackOrdersState.loadFailure(NetworkExceptions failure) = _LoadFailure;
}

class TrackOrdersNotifier extends StateNotifier<TrackOrdersState> {
  TrackOrdersNotifier(this._repository)
    : super(const TrackOrdersState.initial()) {
    unawaited(fetchOrders());
  }

  final OrdersRepository _repository;

  Future<void> fetchOrders({int limit = 20, String? cursor}) async {
    state = const TrackOrdersState.loadInProgress();
    final either = await _repository.getTrackedOrders(
      limit: limit,
      cursor: cursor,
    );
    state = either.fold(
      TrackOrdersState.loadFailure,
      TrackOrdersState.loadSuccess,
    );
  }
}

@freezed
abstract class OrderDetailState with _$OrderDetailState {
  const OrderDetailState._();

  const factory OrderDetailState.initial() = _OrderInitial;
  const factory OrderDetailState.loadInProgress() = _OrderLoadInProgress;
  const factory OrderDetailState.loadSuccess(OrderDetail order) = _OrderLoadSuccess;
  const factory OrderDetailState.loadFailure(NetworkExceptions failure) = _OrderLoadFailure;
  const factory OrderDetailState.actionInProgress(OrderDetail order) = _OrderActionInProgress;
  const factory OrderDetailState.actionFailure(NetworkExceptions failure) = _OrderActionFailure;
}

class OrderDetailNotifier extends StateNotifier<OrderDetailState> {
  OrderDetailNotifier(this._repository)
      : super(const OrderDetailState.initial());

  final OrdersRepository _repository;

  Future<void> loadOrder(String orderId) async {
    state = const OrderDetailState.loadInProgress();
    final either = await _repository.getOrderDetail(orderId);
    state = either.fold(
      OrderDetailState.loadFailure,
      OrderDetailState.loadSuccess,
    );
  }

  Future<void> cancelOrder() async {
    state.maybeWhen(
      loadSuccess: (order) async {
        state = OrderDetailState.actionInProgress(order);
        final either = await _repository.cancelOrder(order.id);
        state = either.fold(
          (failure) {
            _onActionFailure(order, failure);
            return OrderDetailState.actionFailure(failure);
          },
          (_) {
            return OrderDetailState.loadSuccess(
              order.copyWith(
                status: OrderTrackStatus.cancelled,
                canCancel: false,
                canReturn: false,
              ),
            );
          },
        );
      },
      orElse: () {},
    );
  }

  Future<void> requestReturn(String reason) async {
    state.maybeWhen(
      loadSuccess: (order) async {
        state = OrderDetailState.actionInProgress(order);
        final either = await _repository.requestReturn(order.id, reason);
        state = either.fold(
          (failure) {
            _onActionFailure(order, failure);
            return OrderDetailState.actionFailure(failure);
          },
          (_) {
            return OrderDetailState.loadSuccess(
              order.copyWith(canReturn: false),
            );
          },
        );
      },
      orElse: () {},
    );
  }

  Future<void> _onActionFailure(OrderDetail order, NetworkExceptions failure) async {
    state = OrderDetailState.actionFailure(failure);
    await Future<void>.delayed(const Duration(seconds: 2));
    state.maybeWhen(
      actionFailure: (_) {
        if (mounted) {
          state = OrderDetailState.loadSuccess(order);
        }
      },
      orElse: () {},
    );
  }
}
