import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/models/emi_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_eligibility.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_quote.dart';

/// The buyer side of the EMI phase 1 contract.
class EmiRemoteDataSource {
  EmiRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// `GET /v1/emi/quote` — anonymous allowed. Sends the token when there is
  /// one; without one the interceptor simply leaves it off.
  Future<EmiQuote> getQuote({
    required String variantId,
    required int downPaymentPercent,
    required int tenureMonths,
  }) async {
    final response = await apiClient.get(
      '/v1/emi/quote',
      queryParameters: <String, dynamic>{
        'variantId': variantId,
        'downPaymentPercent': downPaymentPercent,
        'tenureMonths': tenureMonths,
      },
    );
    return readEmiQuote(readJsonObject(response));
  }

  /// `GET /v1/customer/emi/eligibility` — buyer auth.
  Future<EmiEligibility> getEligibility() async {
    final response = await apiClient.get('/v1/customer/emi/eligibility');
    return readEmiEligibility(readJsonObject(response));
  }
}
