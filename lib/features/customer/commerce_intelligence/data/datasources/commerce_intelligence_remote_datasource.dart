import 'package:stylemint_mobile_frontend/core/network/api_client.dart';

/// `/v1/customer/commerce-intelligence` — the temporal, consequential RAG
/// route family.
///
/// The controller is `[Authorize]` and reads the account from the JWT
/// subject, so no account id is ever sent from here.
///
/// There is exactly one method, and it is a read. This class has no way to
/// price, reserve, pay or add to a cart, and that is enforced by its shape.
class CommerceIntelligenceRemoteDataSource {
  CommerceIntelligenceRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const String base = '/v1/customer/commerce-intelligence';

  /// Server clamp is 1..50; sending the same default the controller uses.
  static const int defaultEvidenceLimit = 20;

  /// POST `/answer` — body `{query, asOfUtc, evidenceLimit}`.
  ///
  /// The server rejects a blank query (`validation.required`), a query over
  /// 500 characters (`validation.too_long`) and an `asOfUtc` more than five
  /// minutes ahead of server time (`validation.out_of_range`).
  ///
  /// [asOfUtc] is omitted rather than sent as null when the caller wants
  /// "now", so the server's clock decides rather than the handset's.
  Future<Map<String, dynamic>> answer({
    required String query,
    DateTime? asOfUtc,
    int evidenceLimit = defaultEvidenceLimit,
  }) async {
    final response = await apiClient.post(
      '$base/answer',
      data: {
        'query': query,
        'evidenceLimit': evidenceLimit,
        if (asOfUtc != null) 'asOfUtc': asOfUtc.toUtc().toIso8601String(),
      },
    );
    return response is Map<String, dynamic> ? response : <String, dynamic>{};
  }
}
