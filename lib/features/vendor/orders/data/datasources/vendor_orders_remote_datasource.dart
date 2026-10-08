import 'package:dio/dio.dart'
    show DioException, FormData, MultipartFile, Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/upload_filename.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_order_dto.dart';

class VendorOrdersRemoteDataSource {
  VendorOrdersRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );

  Future<Map<String, dynamic>> getOrders({
    required int limit,
    String? cursor,
    String? status,
    DateTime? placedFromUtc,
    DateTime? placedToUtc,
    String? productVariantId,
    double? minSubtotal,
    double? maxSubtotal,
    String? carrier,
  }) async {
    final response = await apiClient.get(
      '/v1/vendor/sub-orders',
      queryParameters: {
        'pageSize': limit,
        if (cursor != null) 'cursor': cursor,
        if (status != null) 'state': status,
        if (placedFromUtc != null)
          'placedFromUtc': placedFromUtc.toUtc().toIso8601String(),
        if (placedToUtc != null)
          'placedToUtc': placedToUtc.toUtc().toIso8601String(),
        if (productVariantId != null) 'productVariantId': productVariantId,
        if (minSubtotal != null) 'minSubtotal': minSubtotal,
        if (maxSubtotal != null) 'maxSubtotal': maxSubtotal,
        if (carrier != null) 'carrier': carrier,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// `totalCount` for a single `SubOrderState` — used for dashboard tile
  /// counts. Filters server-side via the (correctly-named) `state` int
  /// query param; `pageSize: 1` keeps the payload minimal since only the
  /// count is read.
  Future<int> getSubOrderCount(int state) async {
    final response = await apiClient.get(
      '/v1/vendor/sub-orders',
      queryParameters: {'state': state, 'pageSize': 1},
    );
    return (response as Map<String, dynamic>)['totalCount'] as int? ?? 0;
  }

  /// `totalCount` across SEVERAL states in one request, via the repeatable
  /// `states` param.
  ///
  /// The "to ship" bucket spans seven backend states, and [getSubOrderCount]
  /// takes one — so this exists to keep the nav-bar badge at one request
  /// instead of seven on every screen.
  ///
  /// Dio's default `ListFormat.multi` sends `?states=1&states=2&…`, which is
  /// the shape ASP.NET Core binds to `SubOrderState[]`. A comma-joined string
  /// would arrive as a single unparseable value, so the list is passed as a
  /// list rather than pre-joined.
  Future<int> getSubOrderCountForStates(List<int> states) async {
    if (states.isEmpty) return 0;
    final response = await apiClient.get(
      '/v1/vendor/sub-orders',
      queryParameters: {'states': states, 'pageSize': 1},
    );
    return (response as Map<String, dynamic>)['totalCount'] as int? ?? 0;
  }

  /// GET /v1/vendor/sub-orders/{subOrderId} — vendor sub-order detail
  /// (SM-BG-2). `orderId` here is the sub-order id (the list row's `id`).
  /// Requires backend PR #53 deployed.
  Future<VendorOrderDetailDto> getOrderDetail(String orderId) async {
    final response = await apiClient.get(
      '/v1/vendor/sub-orders/$orderId',
      options: Options(headers: {'requiresToken': true}),
    );
    return VendorOrderDetailDto.fromJson(response as Map<String, dynamic>);
  }

  // updateOrderStatus, markReadyToShip, addTracking and markDelivered all
  // respond with the backend's thin SubOrderDto (id/state/carrier/tracking
  // only — no orderNumber or subtotal), not the richer VendorOrderDto shape
  // the order-detail screen renders. Discard the response body rather than
  // parsing it as a VendorOrderDto — the repository re-fetches full detail
  // via getOrderDetail() afterward.
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/vendor/sub-orders/$orderId/$newStatus',
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST /v1/vendor/sub-orders/{subOrderId}/ready-to-ship — Vendor §3B
  /// single-id variant. "Mark as Shipped" in the UI maps to this transition.
  Future<void> markReadyToShip(
    String orderId,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/vendor/sub-orders/$orderId/ready-to-ship',
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST /v1/vendor/sub-orders/{subOrderId}/tracking — "Assign Tracking No."
  /// The backend SetTrackingVm contract requires `carrier` and
  /// `trackingNumber` (maximum lengths 100 and 200 respectively).
  Future<void> addTracking(
    String orderId,
    String carrier,
    String trackingNumber,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/vendor/sub-orders/$orderId/tracking',
      data: {'carrier': carrier, 'trackingNumber': trackingNumber},
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST /v1/vendor/sub-orders/{subOrderId}/delivered
  Future<void> markDelivered(
    String orderId,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/vendor/sub-orders/$orderId/delivered',
      options: _idempotent(idempotencyKey),
    );
  }

  // ── Seller steps (Orders contract §2). Responses are the thin SubOrderDto;
  // the repository re-fetches the detail afterward, as above.

  /// POST /v1/vendor/sub-orders/{id}/accept — Paid/AwaitingFulfillment ->
  /// Accepted. No body.
  Future<void> acceptOrder(String orderId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/vendor/sub-orders/$orderId/accept',
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST /v1/vendor/sub-orders/{id}/reject — Paid/AwaitingFulfillment ->
  /// Cancelled. `note` (≤ 200) is required when `reasonCode` is 6 (Other).
  Future<void> rejectOrder(
    String orderId, {
    required int reasonCode,
    required String idempotencyKey,
    String? note,
  }) async {
    final trimmed = note?.trim();
    await apiClient.post(
      '/v1/vendor/sub-orders/$orderId/reject',
      data: {
        'reasonCode': reasonCode,
        if (trimmed != null && trimmed.isNotEmpty) 'note': trimmed,
      },
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST /v1/vendor/sub-orders/{id}/packed — Accepted -> Packed. No body.
  Future<void> markPacked(String orderId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/vendor/sub-orders/$orderId/packed',
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST /v1/vendor/sub-orders/{id}/collected — counter handover on a
  /// collection sub-order -> Delivered. No body; the backend records the
  /// calling credential as the accountable party.
  ///
  /// 422 on a delivery sub-order ("Only a collection sub-order can be handed
  /// over at a counter"). That refusal is carried to the seller as the
  /// backend worded it rather than flattened into a generic failure.
  Future<void> markCollected(String orderId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/vendor/sub-orders/$orderId/collected',
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST /v1/vendor/sub-orders/{id}/handover — Packed -> HandedOver.
  /// `carrier` and `trackingNumber` travel together or not at all; the body
  /// may be empty.
  Future<void> handOver(
    String orderId, {
    required String idempotencyKey,
    String? carrier,
    String? trackingNumber,
    String? handoverNote,
  }) async {
    final c = carrier?.trim() ?? '';
    final t = trackingNumber?.trim() ?? '';
    final n = handoverNote?.trim() ?? '';
    await apiClient.post(
      '/v1/vendor/sub-orders/$orderId/handover',
      data: {
        if (c.isNotEmpty && t.isNotEmpty) ...{
          'carrier': c,
          'trackingNumber': t,
        },
        if (n.isNotEmpty) 'handoverNote': n,
      },
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST /v1/vendor/sub-orders/bulk/accept — 1–100 ids; outer 200 with a
  /// per-id BulkResult, same shape as bulk/ready-to-ship.
  Future<Map<String, dynamic>> bulkAccept(
    List<String> orderIds,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/vendor/sub-orders/bulk/accept',
      data: {'subOrderIds': orderIds},
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  /// GET /v1/vendor/sub-orders/{subOrderId}/packing-slip — Vendor §3D,
  /// read-only PackingSlipDto projection. Returned raw so the repository can
  /// translate the backend DTO into the presentation entity.
  Future<Map<String, dynamic>> getPackingSlip(String orderId) async {
    final response = await apiClient.get(
      '/v1/vendor/sub-orders/$orderId/packing-slip',
      options: Options(headers: {'requiresToken': true}),
    );
    return response as Map<String, dynamic>;
  }

  /// POST /v1/vendor/sub-orders/bulk/ready-to-ship — Vendor §3B "Mark
  /// Multiple as Shipped". Outer 200 with a per-row BulkResult even if some
  /// ids fail individually.
  /// The backend BulkSubOrderIdsVm request field is `subOrderIds`.
  Future<Map<String, dynamic>> bulkReadyToShip(
    List<String> orderIds,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/vendor/sub-orders/bulk/ready-to-ship',
      data: {'subOrderIds': orderIds},
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  /// POST /v1/vendor/sub-orders/bulk/packing-slips — Vendor §3C "Print All
  /// Packing Slips". Pure read; no state change.
  /// The backend BulkSubOrderIdsVm request field is `subOrderIds`.
  Future<Map<String, dynamic>> bulkPackingSlips(List<String> orderIds) async {
    final response = await apiClient.post(
      '/v1/vendor/sub-orders/bulk/packing-slips',
      data: {'subOrderIds': orderIds},
      options: Options(headers: {'requiresToken': true}),
    );
    return response as Map<String, dynamic>;
  }

  /// GET /v1/vendor/returns — Vendor §8.1 paged list of return requests
  /// awaiting (or past) the vendor's accept/reject decision.
  Future<Map<String, dynamic>> listReturns({
    int? state,
    String? cursor,
    int pageSize = 25,
  }) async {
    final response = await apiClient.get(
      '/v1/vendor/returns',
      queryParameters: {
        'pageSize': pageSize,
        if (state != null) 'state': state,
        if (cursor != null) 'cursor': cursor,
      },
      options: Options(headers: {'requiresToken': true}),
    );
    return response as Map<String, dynamic>;
  }

  /// POST /v1/vendor/returns/{id}/accept — Submitted -> Approved.
  Future<Map<String, dynamic>> acceptReturn(
    String returnRequestId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/vendor/returns/$returnRequestId/accept',
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  /// POST /v1/vendor/returns/{id}/complete — Approved -> Completed and refund.
  Future<Map<String, dynamic>> completeReturn(
    String returnRequestId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/vendor/returns/$returnRequestId/complete',
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  /// POST /v1/vendor/returns/{id}/reject — Submitted -> Rejected (terminal).
  Future<Map<String, dynamic>> rejectReturn(
    String returnRequestId,
    String reason,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/vendor/returns/$returnRequestId/reject',
      data: {'reason': reason},
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  /// GET /v1/vendor/sub-orders/{id}/delivery-candidates — the delivery
  /// partners routing would accept for this order's parcel, best first.
  ///
  /// An empty list is a real answer: either the parcel does not exist yet
  /// (parcels are created when the order is paid) or nobody is on shift and in
  /// range. The handover sheet says so rather than showing an empty picker.
  Future<List<Map<String, dynamic>>> listDeliveryCandidates(
    String subOrderId,
  ) async {
    final response = await apiClient.get(
      '/v1/vendor/sub-orders/$subOrderId/delivery-candidates',
    );
    return (response as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  /// POST /v1/vendor/sub-orders/{id}/offer-to-courier/{courierProfileId}.
  ///
  /// Offers, never assigns: the partner accepts, or the offer expires and the
  /// parcel goes to every eligible courier. A refusal — off shift, outside
  /// their tier's locality, no parcel yet — arrives as a 422 the caller
  /// surfaces, because it is something the vendor can act on.
  Future<void> offerToCourier(
    String subOrderId,
    String courierProfileId, {
    required String idempotencyKey,
    String? note,
  }) async {
    final n = note?.trim() ?? '';
    await apiClient.post(
      '/v1/vendor/sub-orders/$subOrderId/offer-to-courier/$courierProfileId',
      data: {if (n.isNotEmpty) 'note': n},
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST /v1/vendor/sub-orders/{id}/delivery-requests — opens (or re-opens)
  /// a request: the parcel is re-planned and every eligible rider within the
  /// radius is notified. Riders answer with interest; nothing is assigned
  /// until [selectDeliveryPartner].
  Future<Map<String, dynamic>> openDeliveryRequest(
    String subOrderId, {
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/vendor/sub-orders/$subOrderId/delivery-requests',
      data: const <String, dynamic>{},
      options: _idempotent(idempotencyKey),
    );
    return (response as Map).cast<String, dynamic>();
  }

  /// GET /v1/vendor/sub-orders/{id}/delivery-requests/current, or null when
  /// no request was ever opened for it.
  ///
  /// 404 is that normal "none yet" answer, not a failure — the sheet offers
  /// "Find a delivery partner" for it. Every other status still throws, so a
  /// real error is never shown as "nobody has been asked".
  Future<Map<String, dynamic>?> getCurrentDeliveryRequest(
    String subOrderId,
  ) async {
    try {
      final response = await apiClient.get(
        '/v1/vendor/sub-orders/$subOrderId/delivery-requests/current',
      );
      if (response == null) return null;
      return (response as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// POST /v1/vendor/sub-orders/{id}/delivery-requests/current/select —
  /// assigns the hop to the rider behind [offerId] and tells the others it
  /// was taken.
  Future<Map<String, dynamic>> selectDeliveryPartner(
    String subOrderId, {
    required String offerId,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/vendor/sub-orders/$subOrderId/delivery-requests/current/select',
      data: {'offerId': offerId},
      options: _idempotent(idempotencyKey),
    );
    return (response as Map).cast<String, dynamic>();
  }

  /// POST /v1/vendor/packages/seal-images — multipart upload, returns the CDN
  /// URL to pass as `sealPhotoUrl` when sealing.
  ///
  /// Filename is fixed via [uploadFilename]: dio derives Content-Type from the
  /// name and never from the bytes, and the endpoint allows only JPG and PNG.
  Future<String> uploadSealPhoto(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: uploadFilename(filePath),
      ),
    });
    final response = await apiClient.rawPost(
      '/v1/vendor/packages/seal-images',
      data: formData,
      options: Options(headers: {'requiresToken': true}),
    );
    final data = response.data as Map<String, dynamic>;
    return data['url'] as String;
  }

  /// POST /v1/vendor/sub-orders/{id}/seal — the seal number plus a photo URL.
  ///
  /// Required before any courier can be assigned: an unsealed parcel is
  /// refused by the hop assignment, so without this an accepted offer is
  /// dropped. Idempotent for the same seal number.
  Future<void> sealPackage(
    String orderId, {
    required String sealId,
    required String sealPhotoUrl,
    required String idempotencyKey,
  }) async {
    await apiClient.post(
      '/v1/vendor/sub-orders/$orderId/seal',
      data: {'sealId': sealId, 'sealPhotoUrl': sealPhotoUrl},
      options: _idempotent(idempotencyKey),
    );
  }
}
