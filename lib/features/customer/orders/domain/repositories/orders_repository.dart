import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/reorder_suggestion_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_cancellation_reason.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';

abstract interface class OrdersRepository {
  Future<Either<NetworkExceptions, List<TrackedOrder>>> getTrackedOrders({
    int limit,
    String? cursor,
  });

  Future<Either<NetworkExceptions, OrderDetail>> getOrderDetail(String orderId);

  Future<Either<NetworkExceptions, OrderInvoice>> getOrderInvoice(
    String orderNumber,
  );

  Future<Either<NetworkExceptions, Unit>> cancelOrder(
    String orderId, {
    required OrderCancellationReason reason,
    String? note,
  });

  Future<Either<NetworkExceptions, Unit>> requestReturn(
    String orderId, {
    required String subOrderId,
    required String subOrderLineId,
    required int quantity,
    required String reason,
    required List<String> photoUrls,
  });

  Future<Either<NetworkExceptions, String>> uploadReturnPhoto(
    String filePath,
  );

  Future<Either<NetworkExceptions, List<ReorderSuggestionDto>>>
      getReorderSuggestions();

  Future<Either<NetworkExceptions, Unit>> dismissReorderSuggestion(
    String productId,
  );
}
