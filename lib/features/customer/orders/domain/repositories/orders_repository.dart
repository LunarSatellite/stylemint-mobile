import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/reorder_suggestion_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/carbon_impact.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/customer_return.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_timeline.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/delivery_acceptance.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_cancellation_reason.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_care_plan.dart';
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

  /// Submits a return; the value is the new return request id, or null when
  /// the response didn't carry one.
  Future<Either<NetworkExceptions, String?>> requestReturn(
    String orderId, {
    required String subOrderId,
    required String subOrderLineId,
    required int quantity,
    required String reason,
    required List<String> photoUrls,
  });

  /// Buyer tracking timeline, one entry per sub-order (404 -> notFound).
  Future<Either<NetworkExceptions, OrderTimeline>> getOrderTimeline(
    String orderNumber,
  );

  /// The buyer's returns, newest first, cursor-paged.
  Future<Either<NetworkExceptions, PagedResult<CustomerReturn>>> getMyReturns({
    String? cursor,
    int pageSize,
  });

  /// One of the buyer's returns (404 -> notFound).
  Future<Either<NetworkExceptions, CustomerReturn>> getReturn(String returnId);

  Future<Either<NetworkExceptions, String>> uploadReturnPhoto(
    String filePath,
  );

  Future<Either<NetworkExceptions, List<ReorderSuggestionDto>>>
      getReorderSuggestions();

  Future<Either<NetworkExceptions, Unit>> dismissReorderSuggestion(
    String productId,
  );

  /// The signed-in customer's cumulative delivery carbon savings.
  Future<Either<NetworkExceptions, CarbonImpact>> getCarbonImpact();

  /// Voyager Post-Purchase Care plan for one order (404 -> notFound).
  Future<Either<NetworkExceptions, OrderCarePlan>> getOrderCarePlan(
    String orderNumber,
  );

  /// State and seal of a StyleMint package (404 -> notFound).
  Future<Either<NetworkExceptions, DeliveryPackageStatus>>
  getDeliveryPackageStatus(String trackingNumber);

  /// What the buyer recorded when the parcel arrived (404 -> notFound until
  /// they answer).
  Future<Either<NetworkExceptions, DeliveryAcceptance>> getDeliveryAcceptance(
    String trackingNumber,
  );

  /// Records what arrived, once (409 -> conflict when a different answer is
  /// already saved; 400 -> validation with the backend's sentence).
  Future<Either<NetworkExceptions, DeliveryAcceptance>>
  recordDeliveryAcceptance(
    String trackingNumber, {
    required DeliveryAcceptanceOutcome outcome,
    bool? sealIntact,
    String? issueNote,
  });
}
