import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/bulk_action_result.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/packing_slip.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_return_request.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class VendorOrdersRepository {
  Future<Either<NetworkExceptions, PagedResult<VendorOrder>>> getOrders({
    int limit,
    String? cursor,
    String? status,
  });

  /// `totalCount` of sub-orders in a given `SubOrderState` (backend enum
  /// int) — used for dashboard "Pending Actions" tile counts.
  Future<Either<NetworkExceptions, int>> getSubOrderCount(int state);

  Future<Either<NetworkExceptions, VendorOrder>> getOrderDetail(String orderId);

  Future<Either<NetworkExceptions, VendorOrder>> updateOrderStatus(
    String orderId,
    VendorOrderStatus newStatus,
  );

  /// Vendor §8.1 — paged return requests awaiting/past the vendor's
  /// accept/reject decision.
  Future<Either<NetworkExceptions, PagedResult<VendorReturnRequest>>>
  listReturns({
    VendorReturnRequestState? state,
    String? cursor,
    int pageSize,
  });

  Future<Either<NetworkExceptions, VendorReturnRequest>> acceptReturn(
    String returnRequestId,
  );

  Future<Either<NetworkExceptions, VendorReturnRequest>> rejectReturn(
    String returnRequestId,
    String reason,
  );

  /// Vendor §3B single-id "Mark as Shipped".
  Future<Either<NetworkExceptions, VendorOrder>> markReadyToShip(
    String orderId,
  );

  /// "Assign Tracking No." — attaches carrier + tracking number.
  Future<Either<NetworkExceptions, VendorOrder>> addTracking(
    String orderId, {
    required String carrier,
    required String trackingNumber,
  });

  Future<Either<NetworkExceptions, VendorOrder>> markDelivered(
    String orderId,
  );

  /// Vendor §3D read-only packing slip projection.
  Future<Either<NetworkExceptions, PackingSlip>> getPackingSlip(
    String orderId,
  );

  /// Vendor §3B "Mark Multiple as Shipped".
  Future<Either<NetworkExceptions, BulkActionResult>> bulkMarkReadyToShip(
    List<String> orderIds,
  );

  /// Vendor §3C "Print All Packing Slips".
  Future<Either<NetworkExceptions, BulkActionResult>> bulkPackingSlips(
    List<String> orderIds,
  );
}
