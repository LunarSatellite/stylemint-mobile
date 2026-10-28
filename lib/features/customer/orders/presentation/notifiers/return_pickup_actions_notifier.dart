import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/customer_return.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_pickup.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';

/// The buyer's two return-pickup actions: cancel the return, and send a
/// rider again.
///
/// The bool is "an action is in flight", for the buttons. Outcomes are
/// returned, not held, like the rider's job actions: a shared last-result
/// would show one return another's error.
class ReturnPickupActionsNotifier extends StateNotifier<bool> {
  ReturnPickupActionsNotifier(this._repository) : super(false);

  final OrdersRepository _repository;

  Future<Either<NetworkExceptions, CustomerReturn>> cancel(
    String returnId, {
    String? note,
  }) => _run(() => _repository.cancelReturn(returnId, note: note));

  Future<Either<NetworkExceptions, ReturnPickup>> sendAgain(String returnId) =>
      _run(() => _repository.retryReturnPickup(returnId));

  Future<Either<NetworkExceptions, T>> _run<T>(
    Future<Either<NetworkExceptions, T>> Function() body,
  ) async {
    state = true;
    try {
      return await body();
    } finally {
      if (mounted) state = false;
    }
  }
}
