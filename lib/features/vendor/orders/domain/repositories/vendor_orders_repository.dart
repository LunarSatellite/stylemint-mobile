import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class VendorOrdersRepository {
  Future<Either<NetworkExceptions, PagedResult<VendorOrder>>> getOrders({
    int limit,
    String? cursor,
    String? status,
  });

  Future<Either<NetworkExceptions, VendorOrder>> getOrderDetail(String orderId);

  Future<Either<NetworkExceptions, VendorOrder>> updateOrderStatus(
    String orderId,
    VendorOrderStatus newStatus,
  );

  Future<Either<NetworkExceptions, Unit>> handleReturn(
    String orderId,
    String action,
  );
}
