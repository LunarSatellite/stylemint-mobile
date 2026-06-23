import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_cancellation_reason.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/orders_mock_data.dart';

/// In-memory repository that returns [kMockTrackedOrders] / [kMockOrderDetails].
/// A small artificial delay simulates network latency so loading states are
/// visible during development.
///
/// Replace [ordersRepositoryProvider] with [OrdersRepositoryImpl] for production.
class MockOrdersRepository implements OrdersRepository {
  @override
  Future<Either<NetworkExceptions, List<TrackedOrder>>> getTrackedOrders({
    int limit = 20,
    String? cursor,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return right(kMockTrackedOrders);
  }

  @override
  Future<Either<NetworkExceptions, OrderDetail>> getOrderDetail(
    String orderId,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final detail = kMockOrderDetails[orderId];
    if (detail == null) return left(const NetworkExceptions.notFound());
    return right(detail);
  }

  @override
  Future<Either<NetworkExceptions, Unit>> cancelOrder(
    String orderId, {
    required OrderCancellationReason reason,
    String? note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return right(unit);
  }

  @override
  Future<Either<NetworkExceptions, Unit>> requestReturn(
    String orderId,
    String reason,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return right(unit);
  }
}
