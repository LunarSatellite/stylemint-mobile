import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/data/models/vendor_emi_json.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/entities/vendor_emi.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// The vendor side of the EMI phase 1 contract (vendor auth, own products).
class VendorEmiRemoteDataSource {
  VendorEmiRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static String _terms(String productId) =>
      '/v1/vendor/products/${Uri.encodeComponent(productId)}/emi-terms';

  Future<VendorEmiTerms> getTerms(String productId) async => readVendorEmiTerms(
    readJsonObject(await apiClient.get(_terms(productId))),
  );

  Future<VendorEmiTerms> putTerms(
    String productId, {
    required bool enabled,
    required int minDownPaymentPercent,
    required List<int> tenures,
    required String idempotencyKey,
  }) async => readVendorEmiTerms(
    readJsonObject(
      await apiClient.put(
        _terms(productId),
        data: vendorEmiTermsBody(
          enabled: enabled,
          minDownPaymentPercent: minDownPaymentPercent,
          tenures: tenures,
        ),
        options: Options(
          headers: <String, dynamic>{
            'requiresToken': true,
            'Idempotency-Key': idempotencyKey,
          },
        ),
      ),
    ),
  );

  /// `GET /v1/vendor/emi/products` — a bare array.
  Future<List<VendorEmiTerms>> getEmiProducts() async {
    final response = await apiClient.get('/v1/vendor/emi/products');
    final items = response is List
        ? response
        : response is Map && response['items'] is List
        ? response['items'] as List
        : const <dynamic>[];
    return [
      for (final item in items)
        if (item is Map<String, dynamic>) readVendorEmiTerms(item),
    ];
  }

  Future<VendorEmiSettings> getSettings() async => readVendorEmiSettings(
    readJsonObject(await apiClient.get('/v1/vendor/emi/settings')),
  );

  Future<VendorEmiSettings> putSettings(Money? exposureLimit) async =>
      readVendorEmiSettings(
        readJsonObject(
          await apiClient.put(
            '/v1/vendor/emi/settings',
            data: vendorEmiSettingsBody(exposureLimit),
          ),
        ),
      );
}
