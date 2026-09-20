import 'dart:convert';

import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/custody_chain.dart';

/// Reads the chain-of-custody proof for one parcel
/// (`/v1/deliveries/{trackingNumber}/custody` and `.../custody/verify`).
///
/// An interface rather than bare functions on purpose: the card is wired
/// through a provider that tests override with a fake.
abstract class CustodyDataSource {
  /// The whole proof, or `null` when this parcel has no custody log to show —
  /// no entries, or the endpoint is unavailable. Never throws: the custody
  /// card is supplementary and must not be able to break order detail.
  Future<CustodyProof?> fetch(String trackingNumber);

  /// The self-contained export a buyer can hand to somebody else, or `null`
  /// when it cannot be produced or cannot be described honestly.
  ///
  /// [bearer] asks the server for the redacted profile: every hop fact
  /// withheld — no geohash, no courier identifiers, no delegate name, no free
  /// text — so the document can be given to somebody holding the parcel
  /// without handing them the buyer's identity or address.
  Future<CustodyProofExport?> export(
    String trackingNumber, {
    required bool bearer,
  });
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


  /// The export is fetched on demand, never alongside the card: it is a
  /// document a buyer asks for, and requesting it speculatively would pull the
  /// buyer's own hop facts down to the device for a share nobody asked for.
  ///
  /// Every value the server sent is carried through unchanged; only the
  /// whitespace is this client's, because the response arrives already parsed.
  /// That is safe here and it is worth being precise about why: the published
  /// algorithm verifies a declared pre-image over packageId, entry count and
  /// chainRoot, not the JSON encoding, so indentation carries no meaning. No
  /// field is renamed, reordered away, added or dropped — a client that
  /// rewrote the document would be handing over a proof of something else.
  @override
  Future<CustodyProofExport?> export(
    String trackingNumber, {
    required bool bearer,
  }) async {
    try {
      final response = await _api.get(
        '/v1/deliveries/$trackingNumber/custody/export',
        queryParameters: bearer ? const {'disclosure': 'bearer'} : null,
      );
      if (response is! Map<String, dynamic>) return null;
      return CustodyProofExport.fromJson(
        response,
        const JsonEncoder.withIndent('  ').convert(response),
      );
    } on Object catch (_) {
      // An unavailable endpoint is not a failed proof, and it is certainly not
      // a proof with no caveats. Nothing is offered.
      return null;
    }
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
