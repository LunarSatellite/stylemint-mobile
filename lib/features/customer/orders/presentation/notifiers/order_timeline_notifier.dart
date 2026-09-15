import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_timeline.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';

part 'order_timeline_notifier.freezed.dart';

@freezed
abstract class OrderTimelineState with _$OrderTimelineState {
  const OrderTimelineState._();

  const factory OrderTimelineState.initial() = _TimelineInitial;
  const factory OrderTimelineState.loadInProgress() = _TimelineLoadInProgress;
  const factory OrderTimelineState.loadSuccess(OrderTimeline timeline) =
      _TimelineLoadSuccess;
  const factory OrderTimelineState.loadFailure(NetworkExceptions failure) =
      _TimelineLoadFailure;
}

/// Buyer tracking timeline for one order. The order detail screen falls back
/// to its derived timeline whenever this ends in a load failure.
class OrderTimelineNotifier extends StateNotifier<OrderTimelineState> {
  OrderTimelineNotifier(this._repository, this.orderNumber)
    : super(const OrderTimelineState.initial()) {
    unawaited(load());
  }

  final OrdersRepository _repository;
  final String orderNumber;

  Future<void> load() async {
    state = const OrderTimelineState.loadInProgress();
    final either = await _fetch();
    if (!mounted) return;
    state = either.fold(
      OrderTimelineState.loadFailure,
      OrderTimelineState.loadSuccess,
    );
  }

  /// Pull-to-refresh: the current timeline stays on screen while fetching,
  /// and a failed refresh keeps it rather than dropping to the fallback.
  Future<void> refresh() async {
    final hasTimeline = state.maybeWhen(
      loadSuccess: (_) => true,
      orElse: () => false,
    );
    if (!hasTimeline) return load();
    final either = await _fetch();
    if (!mounted) return;
    either.fold((_) {}, (t) => state = OrderTimelineState.loadSuccess(t));
  }

  Future<Either<NetworkExceptions, OrderTimeline>> _fetch() async {
    try {
      return await _repository.getOrderTimeline(orderNumber);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}
