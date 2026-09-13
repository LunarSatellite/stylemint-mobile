import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/data/models/sponsored_listing_dto.dart';

/// Catalog module `VendorStoreController` (route `v1/vendor/store`). Catalog
/// vendor routes carry no `api/` prefix, same as `/v1/vendor/store/actions`.
class SponsoredProductsRemoteDataSource {
  SponsoredProductsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const _base = '/v1/vendor/store/sponsored';

  /// `GET /v1/vendor/store/sponsored` — every sponsorship the vendor has.
  Future<List<SponsoredListingDto>> getSponsoredListings() async {
    final response = await apiClient.get(_base);
    return SponsoredListingDto.listFromJson(response);
  }

  /// `PUT /v1/vendor/store/sponsored/{productId}` — starts a sponsorship, or
  /// changes and restarts the existing one. [endsUtc] null runs it until
  /// the vendor pauses it.
  Future<SponsoredListingDto> sponsor({
    required String productId,
    required int dailyImpressionCap,
    required String idempotencyKey,
    DateTime? endsUtc,
  }) async {
    final response = await apiClient.put(
      '$_base/${Uri.encodeComponent(productId)}',
      data: <String, dynamic>{
        'dailyImpressionCap': dailyImpressionCap,
        'endsUtc': endsUtc?.toUtc().toIso8601String(),
      },
      options: _mutationOptions(idempotencyKey),
    );
    return SponsoredListingDto.fromJson(response as Map<String, dynamic>);
  }

  /// `POST /v1/vendor/store/sponsored/{productId}/pause`.
  Future<SponsoredListingDto> pause({
    required String productId,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '$_base/${Uri.encodeComponent(productId)}/pause',
      options: _mutationOptions(idempotencyKey),
    );
    return SponsoredListingDto.fromJson(response as Map<String, dynamic>);
  }

  static Options _mutationOptions(String idempotencyKey) => Options(
    headers: <String, dynamic>{
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
