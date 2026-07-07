import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';

class VendorProductsRemoteDataSource {
  VendorProductsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<Map<String, dynamic>> getProducts({
    required int limit,
    String? cursor,
    String? status,
  }) async {
    final response = await apiClient.get(
      '/v1/vendor/products',
      queryParameters: {
        'pageSize': limit,
        if (cursor != null) 'cursor': cursor,
        if (status != null) 'state': _stateFromFilterKey(status),
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Maps the UI tab filter key to the backend's numeric `ProductState`
  /// enum (1=Draft, 2=Active, 3=OutOfStock, 4=Archived, 5=Suspended) — the
  /// `state` query param is an integer, not the string codes the tabs use.
  static int? _stateFromFilterKey(String key) {
    switch (key) {
      case 'active':
        return 2;
      case 'draft':
        return 1;
      case 'out_of_stock':
        return 3;
      default:
        return null;
    }
  }

  // No PUT /status endpoint exists on the backend — the only real
  // state-changing action is archive (Active|OutOfStock -> Archived,
  // terminal soft-delete). The lone caller only ever passes
  // VendorProductStatus.discontinued (the "Deactivate" action), which maps
  // directly onto it.
  Future<void> updateProductStatus(
    String productId,
    String status,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/vendor/products/$productId/archive',
      options: Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
  }

  /// PATCH /v1/vendor/products/{productId}/stock — Vendor §9G bulk
  /// variant stock update. `quantity` is confirmed **absolute** (the new
  /// on-hand count), not a delta — backend's `ProductVariant.SetQuantityOnHand`
  /// does a direct assignment, not `+=`.
  Future<Map<String, dynamic>> updateStock({
    required String productId,
    required String variantId,
    required int quantity,
    DateTime? restockUtc,
    required bool alertCustomersOnRestock,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.patch(
      '/v1/vendor/products/$productId/stock',
      data: {
        'adjustments': [
          {'variantId': variantId, 'quantity': quantity},
        ],
        if (restockUtc != null)
          'restockUtc': restockUtc.toUtc().toIso8601String(),
        'alertCustomersOnRestock': alertCustomersOnRestock,
      },
      options: Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
    return response as Map<String, dynamic>;
  }
}
