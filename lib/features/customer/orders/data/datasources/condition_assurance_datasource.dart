import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/condition_assurance.dart';

/// Reads the condition and tamper record for one parcel
/// (`GET /v1/deliveries/{trackingNumber}/condition-assurance`).
///
/// An interface rather than a bare function because the card is wired through
/// a provider that tests override with a fake.
// ignore: one_member_abstracts
abstract class ConditionAssuranceDataSource {
  /// The document, or `null` when there is nothing to show — no controls, no
  /// findings, or the endpoint is unavailable. Never throws: the condition
  /// card is supplementary and must not be able to break order detail.
  ///
  /// An unreachable endpoint returning `null` is deliberate and is *not* the
  /// same as `notRecorded`: nothing renders at all, rather than the app
  /// asserting an absence of evidence it did not actually read.
  Future<ConditionAssurance?> fetch(String trackingNumber);
}

class ConditionAssuranceRemoteDataSource
    implements ConditionAssuranceDataSource {
  const ConditionAssuranceRemoteDataSource({required ApiClient apiClient})
    : _api = apiClient;

  final ApiClient _api;

  @override
  Future<ConditionAssurance?> fetch(String trackingNumber) async {
    final ConditionAssurance assurance;
    try {
      final response = await _api.get(
        '/v1/deliveries/$trackingNumber/condition-assurance',
      );
      if (response is! Map<String, dynamic>) return null;
      assurance = ConditionAssurance.fromJson(response);
    } on Object catch (_) {
      return null;
    }
    return assurance.isEmpty ? null : assurance;
  }
}
