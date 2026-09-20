import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/carbon_impact_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/customer_return_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_event_history_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_timeline_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_acceptance_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/delivery_acceptance.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/replacement_option.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_care_plan_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_invoice_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/reorder_suggestion_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/tracked_order_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/warranty_claim_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/warranty_eligibility_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/warranty_claim.dart';
import 'package:stylemint_mobile_frontend/shared/data/option_label.dart';

/// Remote datasource for customer orders. Throws on failure; the repository
/// maps exceptions to [Failure].
class OrdersRemoteDataSource {
  OrdersRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET `/v1/orders` — the customer's orders (most recent first).
  Future<List<TrackedOrderDto>> getTrackedOrders({
    required int limit,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/orders',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );

    final data = response as Map<String, dynamic>;
    return (data['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => TrackedOrderDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// GET `/v1/orders/by-tracking/{trackingNumber}` — which of the caller's
  /// orders a parcel belongs to, in one call (Orders module
  /// `OrderController.ResolveByTracking` → `OrderParcelRefDto`: `orderNumber`,
  /// `subOrderId`, `packageId`, `trackingNumber`; only the order number is
  /// useful to the client).
  ///
  /// Throws the underlying [DioException]: a 404 is the deliberately
  /// ambiguous "no order for you under that number", a 429 is the 20/min
  /// rate limit. Callers map both — see `orderNumberForTrackingProvider`.
  Future<String> resolveOrderNumberByTracking(String trackingNumber) async {
    final response = await apiClient.get(
      '/v1/orders/by-tracking/${Uri.encodeComponent(trackingNumber)}',
    );
    return (response as Map<String, dynamic>)['orderNumber'] as String;
  }

  /// GET `/v1/orders/{orderNumber}` — full order detail.
  Future<OrderDetailDto> getOrderDetail(String orderId) async {
    final response = await apiClient.get('/v1/orders/$orderId');
    // Order lines prefer the variant's `optionLabel` over the SKU snapshot.
    return OrderDetailDto.fromJson(
      withOptionLabels(response as Map<String, dynamic>),
    );
  }

  /// GET `/v1/orders/{orderNumber}/invoice` — immutable receipt projection.
  Future<OrderInvoiceDto> getOrderInvoice(String orderNumber) async {
    final response = await apiClient.get('/v1/orders/$orderNumber/invoice');
    return OrderInvoiceDto.fromJson(response as Map<String, dynamic>);
  }

  /// GET `/v1/orders/{orderNumber}/care` — Voyager Post-Purchase Care plan:
  /// per item, its stage, return deadline, available actions and one
  /// guidance sentence (Orders module `OrderController.GetCarePlan`).
  Future<OrderCarePlanDto> getOrderCarePlan(String orderNumber) async {
    final response = await apiClient.get('/v1/orders/$orderNumber/care');
    return OrderCarePlanDto.fromJson(response as Map<String, dynamic>);
  }

  Future<WarrantyClaimDto> submitWarrantyClaim({
    required String orderNumber,
    required String subOrderLineId,
    required WarrantyIssueKind issueKind,
    required String description,
    required List<String> evidenceUrls,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/warranties/claims',
      data: <String, dynamic>{
        'orderNumber': orderNumber,
        'subOrderLineId': subOrderLineId,
        'issueKind': issueKind.wireValue,
        'description': description,
        'evidenceUrls': evidenceUrls,
      },
      options: _idempotent(idempotencyKey),
    );
    return WarrantyClaimDto.fromJson(response as Map<String, dynamic>);
  }

  /// GET `/v1/warranties/orders/{orderNumber}/eligibility` — this order's
  /// warranty position line by line, with the bound units on any line that
  /// carries markers. Lines with no marker come back with an empty `units`,
  /// which is the normal answer for almost all stock.
  Future<WarrantyEligibilityDto> getWarrantyEligibility(
    String orderNumber,
  ) async {
    final response = await apiClient.get(
      '/v1/warranties/orders/${Uri.encodeComponent(orderNumber)}/eligibility',
    );
    return WarrantyEligibilityDto.fromJson(response as Map<String, dynamic>);
  }

  /// GET `/v1/warranties/units/{unitMarkerBindingId}/claims` — this buyer's
  /// claims against every binding the same marker has ever carried, so a
  /// corrected tag does not split one item's history in two.
  Future<List<WarrantyClaimDto>> getUnitWarrantyClaims(
    String unitMarkerBindingId,
  ) async {
    final response = await apiClient.get(
      '/v1/warranties/units/'
      '${Uri.encodeComponent(unitMarkerBindingId)}/claims',
    );
    return (response as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(WarrantyClaimDto.fromJson)
        .toList(growable: false);
  }

  Future<List<WarrantyClaimDto>> getWarrantyClaims() async {
    final response = await apiClient.get('/v1/warranties/mine');
    return (response as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(WarrantyClaimDto.fromJson)
        .toList(growable: false);
  }

  Future<bool> getReplenishmentPreference() async {
    final response = await apiClient.get(
      '/v1/customer/reorder-suggestions/preference',
    );
    return (response as Map<String, dynamic>)['enabled'] == true;
  }

  Future<bool> setReplenishmentPreference(
    bool enabled,
    String idempotencyKey,
  ) async {
    final response = await apiClient.put(
      '/v1/customer/reorder-suggestions/preference',
      data: <String, dynamic>{'enabled': enabled},
      options: _idempotent(idempotencyKey),
    );
    return (response as Map<String, dynamic>)['enabled'] == true;
  }

  /// GET `/v1/customer/reorder-suggestions` — "Buy It Again" predictions.
  /// Returns a raw JSON array (the controller returns
  /// `OkObjectResult(result.Value)` for the list, not an `{items:}` wrapper).
  Future<List<ReorderSuggestionDto>> getReorderSuggestions() async {
    final response = await apiClient.get('/v1/customer/reorder-suggestions');
    return (response as List<dynamic>)
        .map((e) => ReorderSuggestionDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// GET `/v1/customer/delivery/carbon-impact` — the signed-in customer's
  /// cumulative CO2 saved by community delivery hops versus a traditional
  /// courier (Delivery module `CarbonController`).
  Future<CarbonImpactDto> getCarbonImpact() async {
    final response = await apiClient.get('/v1/customer/delivery/carbon-impact');
    return CarbonImpactDto.fromJson(response as Map<String, dynamic>);
  }

  /// GET `/v1/deliveries/{trackingNumber}` — the StyleMint package (Delivery
  /// module `BuyerDeliveriesController.GetByTracking`), read for its state and
  /// whether the seller sealed it.
  Future<DeliveryPackageStatusDto> getDeliveryPackageStatus(
    String trackingNumber,
  ) async {
    final response = await apiClient.get('/v1/deliveries/$trackingNumber');
    return DeliveryPackageStatusDto.fromJson(response as Map<String, dynamic>);
  }

  /// GET `/v1/deliveries/{trackingNumber}/acceptance` — what the buyer
  /// recorded when the parcel arrived; 404 until they answer.
  Future<DeliveryAcceptanceDto> getDeliveryAcceptance(
    String trackingNumber,
  ) async {
    final response = await apiClient.get(
      '/v1/deliveries/$trackingNumber/acceptance',
    );
    return DeliveryAcceptanceDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/deliveries/{trackingNumber}/acceptance` — records what arrived,
  /// once. The same outcome again returns the saved record; a different one
  /// is a 409.
  Future<DeliveryAcceptanceDto> recordDeliveryAcceptance(
    String trackingNumber,
    String idempotencyKey, {
    required DeliveryAcceptanceOutcome outcome,
    bool? sealIntact,
    String? issueNote,
    List<DeliveryReceivedItemInput> receivedItems =
        const <DeliveryReceivedItemInput>[],
    String? scannedTrackingCode,
  }) async {
    final response = await apiClient.post(
      '/v1/deliveries/$trackingNumber/acceptance',
      data: recordDeliveryAcceptanceBody(
        outcome: outcome,
        sealIntact: sealIntact,
        issueNote: issueNote,
        receivedItems: receivedItems,
        scannedTrackingCode: scannedTrackingCode,
      ),
      options: _idempotent(idempotencyKey),
    );
    return DeliveryAcceptanceDto.fromJson(response as Map<String, dynamic>);
  }

  /// DELETE `/v1/customer/reorder-suggestions/{productId}` — dismiss one
  /// suggestion so it stops resurfacing until the next purchase cycle.
  Future<void> dismissReorderSuggestion(String productId) async {
    await apiClient.authDelete('/v1/customer/reorder-suggestions/$productId');
  }

  /// POST `/v1/orders/{orderNumber}/cancel` — cancel an order.
  /// [reason] is the backend OrderCancellationReason int; [note] is required
  /// when reason == Other. The 5-7 day refund acknowledgement is mandatory.
  Future<void> cancelOrder(
    String orderId,
    String idempotencyKey, {
    required int reason,
    String? note,
  }) async {
    await apiClient.post(
      '/v1/orders/$orderId/cancel',
      data: <String, dynamic>{
        'reason': reason,
        if (note != null && note.isNotEmpty) 'note': note,
        'acknowledgedFiveToSevenDayRefund': true,
      },
      options: _idempotent(idempotencyKey),
    );
  }

  /// GET `/v1/orders/{orderNumber}/timeline` — buyer tracking steps per
  /// sub-order (Orders contract §3).
  Future<OrderTimelineDto> getOrderTimeline(String orderNumber) async {
    final response = await apiClient.get('/v1/orders/$orderNumber/timeline');
    return OrderTimelineDto.fromJson(response as Map<String, dynamic>);
  }

  /// GET `/v1/orders/{orderNumber}/events` — what actually happened to this
  /// order, oldest first, plus the health of each source consulted.
  Future<OrderEventHistoryDto> getOrderEventHistory(String orderNumber) async {
    final response = await apiClient.get('/v1/orders/$orderNumber/events');
    return OrderEventHistoryDto.fromJson(response as Map<String, dynamic>);
  }

  /// GET `/v1/orders/returns` — the buyer's returns, newest first, as a
  /// cursor-paged `PagedResult<CustomerReturnRequestDto>` (contract §4).
  Future<Map<String, dynamic>> getMyReturns({
    required int pageSize,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/orders/returns',
      queryParameters: {
        'pageSize': pageSize,
        'cursor': ?cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// GET `/v1/orders/returns/{id}` — one of the buyer's returns.
  Future<CustomerReturnDto> getReturn(String returnId) async {
    final response = await apiClient.get('/v1/orders/returns/$returnId');
    return CustomerReturnDto.fromJson(response as Map<String, dynamic>);
  }

  Future<List<ReplacementOption>> getReplacementOptions(
    String originalVariantId,
  ) async {
    final response = await apiClient.get(
      '/v1/orders/replacement-options/$originalVariantId',
    );
    return (response as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ReplacementOption.fromJson)
        .where((option) => option.variantId.isNotEmpty)
        .toList(growable: false);
  }

  /// POST `/v1/orders/{orderNumber}/returns` — request a return.
  /// Backend `SubmitReturnVm` requires subOrderId/subOrderLineId/quantity/
  /// reason/photoUrls (skill §5 + §13.7) — a bare reason always 400s.
  /// Returns the new return request id when the response carries one.
  Future<String?> requestReturn(
    String orderId,
    String subOrderId,
    String subOrderLineId,
    int quantity,
    String reason,
    List<String> photoUrls,
    int resolution,
    String? replacementVariantId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/orders/$orderId/returns',
      data: {
        'subOrderId': subOrderId,
        'subOrderLineId': subOrderLineId,
        'quantity': quantity,
        'reason': reason,
        'photoUrls': photoUrls,
        'resolution': resolution,
        if (replacementVariantId != null)
          'replacementVariantId': replacementVariantId,
      },
      options: _idempotent(idempotencyKey),
    );
    // The backend answers with the created ReturnRequestDto.
    return response is Map<String, dynamic> ? response['id'] as String? : null;
  }

  /// POST `/v1/orders/returns/images` — multipart upload, returns the CDN
  /// URL to submit via `requestReturn`'s `photoUrls`.
  Future<String> uploadReturnPhoto(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: 'return.jpg'),
    });
    final response = await apiClient.rawPost(
      '/v1/orders/returns/images',
      data: formData,
      options: _authed(),
    );
    final data = response.data as Map<String, dynamic>;
    return data['url'] as String;
  }

  Options _authed() => Options(headers: {'requiresToken': true});

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
