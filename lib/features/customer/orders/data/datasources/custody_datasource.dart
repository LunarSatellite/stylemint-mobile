import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/custody_chain.dart';

/// Reads the chain-of-custody proof for one parcel
/// (`/v1/deliveries/{trackingNumber}/custody` and `.../custody/verify`).
///
/// One member, and an interface rather than a bare function on purpose: the
/// card is wired through a provider that tests override with a fake, and the
/// two endpoints behind [fetch] will not stay one call forever.
// ignore: one_member_abstracts
abstract class CustodyDataSource {
  /// The whole proof, or `null` when this parcel has no custody log to show —
  /// no entries, or the endpoint is unavailable. Never throws: the custody
  /// card is supplementary and must not be able to break order detail.
  Future<CustodyProof?> fetch(String trackingNumber);
}

class CustodyRemoteDataSource implements CustodyDataSource {
  const CustodyRemoteDataSource({required ApiClient apiClient})
    : _api = apiClient;

  final ApiClient _api;

  @override
  Future<CustodyProof?> fetch(String trackingNumber) async {
    final List<CustodyEntry> entries;
    try {
      final response = await _api.get('/v1/deliveries/$trackingNumber/custody');
      entries = (response as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(CustodyEntry.fromJson)
          .toList(growable: false);
    } on Object catch (_) {
      // An unavailable endpoint is not a failed chain. Nothing renders.
      return null;
    }

    if (entries.isEmpty) return null;

    // The entries are worth showing on their own; the verdict is a second,
    // independent call. When it cannot be reached we say so in those words —
    // we never let an unreachable check pass for a passing one.
    return CustodyProof(
      entries: entries,
      verification: await _verify(trackingNumber),
    );
  }

  Future<CustodyVerification> _verify(String trackingNumber) async {
    try {
      final response = await _api.get(
        '/v1/deliveries/$trackingNumber/custody/verify',
      );
      if (response is! Map<String, dynamic>) {
        return const CustodyVerification.couldNotVerify();
      }
      return CustodyVerification.fromJson(response);
    } on Object catch (_) {
      return const CustodyVerification.couldNotVerify();
    }
  }
}
