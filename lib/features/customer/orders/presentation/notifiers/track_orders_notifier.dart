import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/reorder_suggestion_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/replacement_option.dart';
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
  const factory TrackOrdersState.loadFailure(NetworkExceptions failure) =
      _LoadFailure;
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

sealed class ReplenishmentPreferenceState {
  const ReplenishmentPreferenceState();
}

final class ReplenishmentPreferenceLoading
    extends ReplenishmentPreferenceState {
  const ReplenishmentPreferenceLoading();
}

final class ReplenishmentPreferenceLoaded extends ReplenishmentPreferenceState {
  const ReplenishmentPreferenceLoaded(this.enabled, {this.saving = false});

  final bool enabled;
  final bool saving;
}

final class ReplenishmentPreferenceFailed extends ReplenishmentPreferenceState {
  const ReplenishmentPreferenceFailed();
}

class ReplenishmentPreferenceNotifier
    extends StateNotifier<ReplenishmentPreferenceState> {
  ReplenishmentPreferenceNotifier(this._repository)
    : super(const ReplenishmentPreferenceLoading()) {
    unawaited(load());
  }

  final OrdersRepository _repository;

  Future<void> load() async {
    final result = await _repository.getReplenishmentPreference();
    state = result.fold(
      (_) => const ReplenishmentPreferenceFailed(),
      ReplenishmentPreferenceLoaded.new,
    );
  }

  Future<bool> setEnabled(bool enabled) async {
    final previous = state;
    state = ReplenishmentPreferenceLoaded(enabled, saving: true);
    final result = await _repository.setReplenishmentPreference(enabled);
    return result.fold(
      (_) {
        state = previous;
        return false;
      },
      (saved) {
        state = ReplenishmentPreferenceLoaded(saved);
        return true;
      },
    );
  }
}

@freezed
abstract class ReorderSuggestionsState with _$ReorderSuggestionsState {
  const ReorderSuggestionsState._();

  const factory ReorderSuggestionsState.initial() = _ReorderInitial;
  const factory ReorderSuggestionsState.loadInProgress() =
      _ReorderLoadInProgress;
  const factory ReorderSuggestionsState.loadSuccess(
    List<ReorderSuggestionDto> suggestions,
  ) = _ReorderLoadSuccess;
  const factory ReorderSuggestionsState.loadFailure(
    NetworkExceptions failure,
  ) = _ReorderLoadFailure;
}

/// "Buy It Again" — surfaces the backend's nightly purchase-cadence
/// predictions (Orders module `PredictiveReorder` / skill's reorder-
/// prediction job) on the customer's Orders screen.
class ReorderSuggestionsNotifier
    extends StateNotifier<ReorderSuggestionsState> {
  ReorderSuggestionsNotifier(this._repository)
    : super(const ReorderSuggestionsState.initial()) {
    unawaited(load());
  }

  final OrdersRepository _repository;

  Future<void> load() async {
    state = const ReorderSuggestionsState.loadInProgress();
    final either = await _repository.getReorderSuggestions();
    state = either.fold(
      ReorderSuggestionsState.loadFailure,
      ReorderSuggestionsState.loadSuccess,
    );
  }

  /// Optimistically removes the card, then confirms with the backend so a
  /// dismissed suggestion doesn't immediately resurface if the user
  /// navigates away and back before the next nightly recompute.
  Future<void> dismiss(String productId) async {
    final current = state;
    if (current is! _ReorderLoadSuccess) return;
    state = ReorderSuggestionsState.loadSuccess(
      current.suggestions.where((s) => s.productId != productId).toList(),
    );
    final either = await _repository.dismissReorderSuggestion(productId);
    either.match(
      (_) {}, // best-effort — the optimistic removal already stands.
      (_) {},
    );
  }
}

@freezed
abstract class OrderDetailState with _$OrderDetailState {
  const OrderDetailState._();

  const factory OrderDetailState.initial() = _OrderInitial;
  const factory OrderDetailState.loadInProgress() = _OrderLoadInProgress;
  const factory OrderDetailState.loadSuccess(OrderDetail order) =
      _OrderLoadSuccess;
  const factory OrderDetailState.loadFailure(NetworkExceptions failure) =
      _OrderLoadFailure;
  const factory OrderDetailState.actionInProgress(OrderDetail order) =
      _OrderActionInProgress;
  const factory OrderDetailState.actionFailure(NetworkExceptions failure) =
      _OrderActionFailure;
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

  /// Pull-to-refresh: refetches without swapping the screen for a loader. A
  /// failed refresh keeps the order already on screen.
  Future<void> refresh(String orderId) async {
    final current = state.maybeWhen(loadSuccess: (o) => o, orElse: () => null);
    if (current == null) return loadOrder(orderId);
    final either = await _repository.getOrderDetail(orderId);
    if (!mounted) return;
    either.fold(
      (_) {},
      (order) => state = OrderDetailState.loadSuccess(
        current.submittedReturnId == null
            ? order
            : order.copyWith(
                canReturn: false,
                submittedReturnId: current.submittedReturnId,
              ),
      ),
    );
  }

  // Order cancellation moved to the dedicated cancel flow
  // (CancelOrderScreen + cancelOrderControllerProvider), which collects the
  // reason / note / refund acknowledgement the backend requires.

  Future<void> requestReturn({
    required String subOrderId,
    required String subOrderLineId,
    required int quantity,
    required String reason,
    required List<String> photoUrls,
    ReturnResolutionChoice resolution = ReturnResolutionChoice.refund,
    String? replacementVariantId,
  }) async {
    await state.maybeWhen(
      loadSuccess: (order) async {
        state = OrderDetailState.actionInProgress(order);
        final either = await _repository.requestReturn(
          order.orderNumber,
          subOrderId: subOrderId,
          subOrderLineId: subOrderLineId,
          quantity: quantity,
          reason: reason,
          photoUrls: photoUrls,
          resolution: resolution,
          replacementVariantId: replacementVariantId,
        );
        state = either.fold(
          (failure) {
            _onActionFailure(order, failure);
            return OrderDetailState.actionFailure(failure);
          },
          (returnId) {
            return OrderDetailState.loadSuccess(
              order.copyWith(
                canReturn: false,
                submittedReturnId: returnId ?? '',
              ),
            );
          },
        );
      },
      orElse: () async {},
    );
  }

  Future<Either<NetworkExceptions, List<ReplacementOption>>>
  getReplacementOptions(String originalVariantId) =>
      _repository.getReplacementOptions(originalVariantId);

  Future<Either<NetworkExceptions, String>> uploadReturnPhoto(
    String filePath,
  ) => _repository.uploadReturnPhoto(filePath);

  Future<void> _onActionFailure(
    OrderDetail order,
    NetworkExceptions failure,
  ) async {
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
