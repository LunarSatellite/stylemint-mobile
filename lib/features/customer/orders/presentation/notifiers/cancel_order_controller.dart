import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_cancellation_reason.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';

/// UI state for the cancel-order flow. Plain (non-freezed) so it compiles
/// without codegen; the cancel action itself reuses [OrdersRepository.cancelOrder].
class CancelOrderUiState {
  const CancelOrderUiState({
    this.isSubmitting = false,
    this.errorMessage,
    this.done = false,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final bool done;

  CancelOrderUiState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool? done,
  }) {
    return CancelOrderUiState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      done: done ?? this.done,
    );
  }
}

class CancelOrderController extends StateNotifier<CancelOrderUiState> {
  CancelOrderController(this._repository) : super(const CancelOrderUiState());

  final OrdersRepository _repository;

  /// Cancels [orderId]. [reason]/[comment] are collected per the design spec
  /// but the backend cancel endpoint currently accepts no reason body.
  Future<void> cancel(
    String orderId, {
    required OrderCancellationReason reason,
    String? note,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    final either =
        await _repository.cancelOrder(orderId, reason: reason, note: note);
    state = either.fold(
      (_) => state.copyWith(
        isSubmitting: false,
        errorMessage: 'Could not cancel the order. Please try again.',
      ),
      (_) => const CancelOrderUiState(done: true),
    );
  }
}
