import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';

abstract interface class OrdersRepository {
  Future<Either<NetworkExceptions, List<TrackedOrder>>> getTrackedOrders({
    int limit,
    String? cursor,
  });

  Future<Either<NetworkExceptions, OrderDetail>> getOrderDetail(String orderId);

  Future<Either<NetworkExceptions, Unit>> cancelOrder(String orderId);

  Future<Either<NetworkExceptions, Unit>> requestReturn(String orderId, String reason);
}
