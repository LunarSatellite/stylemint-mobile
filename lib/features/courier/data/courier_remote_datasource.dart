import 'dart:io';

import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';

/// The courier surface, across three backend modules:
///
/// - `/v1/courier/**` — DeliveryCouriers: profile, KYC, device keys, travel
///   plans, reliability, escrow
/// - `/v1/courier/offers/**` — DeliveryRouting: the Dutch-auction hop offers
/// - `/v1/deliveries/hops/**` — Delivery: the work itself
///
/// All three were fully built server-side with no client at all. Nothing here
/// is a new endpoint except `hops/mine`, which had to be added because
/// `HopOfferDto` carries no hop id and a courier therefore had no way to learn
/// what to call pickup on.
class CourierRemoteDataSource {
  CourierRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  // ── Profile ────────────────────────────────────────────────────────────

  /// POST `/v1/courier/apply`. The account comes from the token; `homeGeohash`
  /// is what the routing engine matches offers against.
  Future<Map<String, dynamic>> apply({
    required String homeGeohash,
    int? vehicle,
  }) async {
    final response = await apiClient.authPost(
      '/v1/courier/apply',
      data: {
        'homeGeohash': homeGeohash,
        if (vehicle != null) 'vehicle': vehicle,
      },
    );
    return (response as Map).cast<String, dynamic>();
  }

  /// GET `/v1/courier/by-account/{accountId}` — how the app discovers whether
  /// this account is a courier at all, and what state the application is in.
  /// GET `/v1/courier/by-account/{accountId}`, or null when this account has
  /// no courier profile.
  ///
  /// 404 is the normal answer here, not a failure: almost every account is not
  /// a courier, and the server returns NotFound rather than an empty body for
  /// one that has never applied. Letting that 404 propagate is what made the
  /// gate show "Couldn't load your partner account — check your connection" to
  /// every first-time visitor, which is both wrong and unactionable: the
  /// connection was fine and the right screen was the apply form.
  ///
  /// Only 404 is swallowed. A 401, 403 or 500 still throws, because those are
  /// real failures and must not be reported as "you are not a courier yet" —
  /// that would send someone who already has a profile back to the apply form
  /// and let them try to apply twice.
  Future<Map<String, dynamic>?> getByAccount(String accountId) async {
    try {
      final response = await apiClient.get('/v1/courier/by-account/$accountId');
      if (response == null) return null;
      return (response as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfile(String courierProfileId) async {
    final response = await apiClient.get('/v1/courier/$courierProfileId');
    return (response as Map).cast<String, dynamic>();
  }

  /// POST `/v1/courier/{id}/kyc`.
  ///
  /// `selfieMatchRef` is a reference to an identity check performed elsewhere,
  /// not an image: this endpoint takes the last four digits and the reference,
  /// never a document or a photo. Approval is an admin decision on a separate
  /// endpoint, so submitting moves the profile to KycInReview and no further.
  Future<Map<String, dynamic>> submitKyc({
    required String courierProfileId,
    required String governmentIdLast4,
    required String selfieMatchRef,
  }) async {
    final response = await apiClient.authPost(
      '/v1/courier/$courierProfileId/kyc',
      data: {
        'governmentIdLast4': governmentIdLast4,
        'selfieMatchRef': selfieMatchRef,
      },
    );
    return (response as Map).cast<String, dynamic>();
  }

  // ── Device keys ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listDeviceKeys(
    String courierProfileId,
  ) async {
    final response = await apiClient.get(
      '/v1/courier/$courierProfileId/device-keys',
    );
    return _mapList(response);
  }

  /// POST `/v1/courier/{id}/device-keys`. `publicKeyPem` is PEM-armoured
  /// SPKI; the backend strips the armor itself.
  Future<Map<String, dynamic>> registerDeviceKey({
    required String courierProfileId,
    required String publicKeyId,
    required String publicKeyPem,
    required String deviceModel,
  }) async {
    final response = await apiClient.authPost(
      '/v1/courier/$courierProfileId/device-keys',
      data: {
        'publicKeyId': publicKeyId,
        'publicKeyPem': publicKeyPem,
        'deviceModel': deviceModel,
      },
    );
    return (response as Map).cast<String, dynamic>();
  }

  /// DELETE `/v1/courier/device-keys/{publicKeyId}` — note this one is NOT
  /// nested under the profile id, unlike register and list.
  Future<void> revokeDeviceKey({
    required String publicKeyId,
    required String reason,
  }) async {
    await apiClient.authDelete(
      '/v1/courier/device-keys/${Uri.encodeComponent(publicKeyId)}',
      data: {'reason': reason},
    );
  }

  // ── Travel plans ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listTravelPlans(
    String courierProfileId,
  ) async {
    final response = await apiClient.get(
      '/v1/courier/$courierProfileId/travel-plans',
    );
    return _mapList(response);
  }

  /// POST `/v1/courier/{id}/travel-plans`. A declared journey the router can
  /// match Traveler-tier hops against.
  Future<Map<String, dynamic>> declareTravelPlan({
    required String courierProfileId,
    required String originGeohash,
    required String destinationGeohash,
    required DateTime departsUtcStart,
    required DateTime departsUtcEnd,
    required DateTime arrivesUtcExpected,
    required int vehicle,
    required num maxWeightGrams,
  }) async {
    final response = await apiClient.authPost(
      '/v1/courier/$courierProfileId/travel-plans',
      data: {
        'originGeohash': originGeohash,
        'destinationGeohash': destinationGeohash,
        'departsUtcStart': departsUtcStart.toUtc().toIso8601String(),
        'departsUtcEnd': departsUtcEnd.toUtc().toIso8601String(),
        'arrivesUtcExpected': arrivesUtcExpected.toUtc().toIso8601String(),
        'vehicle': vehicle,
        'maxWeightGrams': maxWeightGrams,
      },
    );
    return (response as Map).cast<String, dynamic>();
  }

  Future<void> cancelTravelPlan({
    required String travelPlanId,
    required String reason,
  }) async {
    await apiClient.authDelete(
      '/v1/courier/travel-plans/$travelPlanId',
      data: {'reason': reason},
    );
  }

  // ── Reliability + escrow ───────────────────────────────────────────────

  Future<Map<String, dynamic>?> getReliability(String courierProfileId) async {
    final response = await apiClient.get(
      '/v1/courier/$courierProfileId/reliability',
    );
    if (response == null) return null;
    return (response as Map).cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> getReliabilityHistory(
    String courierProfileId,
  ) async {
    final response = await apiClient.get(
      '/v1/courier/$courierProfileId/reliability/history',
    );
    return _mapList(response);
  }

  /// GET `/v1/courier/{id}/escrow/balance` — a MoneyDto. Couriers above the
  /// Neighbor tier must hold escrow against the parcels they carry, so an
  /// insufficient balance is why offers can stop arriving.
  Future<Map<String, dynamic>> getEscrowBalance(
    String courierProfileId,
  ) async {
    final response = await apiClient.get(
      '/v1/courier/$courierProfileId/escrow/balance',
    );
    return (response as Map).cast<String, dynamic>();
  }

  // ── Offers ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listOffers() async {
    final response = await apiClient.get('/v1/courier/offers');
    return _mapList(response);
  }

  Future<Map<String, dynamic>> acceptOffer({
    required String offerId,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.authPost(
      '/v1/courier/offers/$offerId/accept',
      options: _idempotent(idempotencyKey),
    );
    return (response as Map).cast<String, dynamic>();
  }

  Future<void> declineOffer({
    required String offerId,
    required int reasonCode,
    String? note,
    required String idempotencyKey,
  }) async {
    await apiClient.authPost(
      '/v1/courier/offers/$offerId/decline',
      data: {
        'reasonCode': reasonCode,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      options: _idempotent(idempotencyKey),
    );
  }

  // ── Hops ───────────────────────────────────────────────────────────────

  /// GET `/v1/deliveries/hops/mine` — the work list, and the only source of
  /// the hop ids every call below needs. 403 when the account has no courier
  /// profile; an empty list when it has one and no current work.
  Future<List<Map<String, dynamic>>> listMyHops() async {
    final response = await apiClient.get('/v1/deliveries/hops/mine');
    return _mapList(response);
  }

  /// POST `/v1/deliveries/hops/{id}/pickup`.
  ///
  /// [signature] must be over the canonical attestation for this event — see
  /// `buildCustodyAttestation`. The server rebuilds that string and verifies
  /// against it, so it is not optional and not free-form.
  Future<Map<String, dynamic>> pickup({
    required String hopId,
    required String geohashAtEvent,
    required String proofPhotoUrl,
    required String signature,
    required String signerPublicKeyId,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.authPost(
      '/v1/deliveries/hops/$hopId/pickup',
      data: {
        'geohashAtEvent': geohashAtEvent,
        'proofPhotoUrl': proofPhotoUrl,
        'signature': signature,
        'signerPublicKeyId': signerPublicKeyId,
      },
      options: _idempotent(idempotencyKey),
    );
    return (response as Map).cast<String, dynamic>();
  }

  /// POST `/v1/deliveries/hops/{id}/handoff/photo` — the fallback when the two
  /// devices cannot complete an NFC handshake, and the path used for a final
  /// delivery to the buyer ([isFinalDelivery]).
  Future<Map<String, dynamic>> photoHandoff({
    required String hopId,
    String? nextCourierProfileId,
    required String geohashAtEvent,
    required String proofPhotoUrl,
    required String signature,
    required String signerPublicKeyId,
    String? notes,
    required bool isFinalDelivery,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.authPost(
      '/v1/deliveries/hops/$hopId/handoff/photo',
      data: {
        if (nextCourierProfileId != null)
          'nextCourierProfileId': nextCourierProfileId,
        'geohashAtEvent': geohashAtEvent,
        'proofPhotoUrl': proofPhotoUrl,
        'signature': signature,
        'signerPublicKeyId': signerPublicKeyId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'isFinalDelivery': isFinalDelivery,
      },
      options: _idempotent(idempotencyKey),
    );
    return (response as Map).cast<String, dynamic>();
  }

  /// POST `/v1/deliveries/hops/{id}/handoff/nfc/init` — the outgoing courier
  /// starts the handshake; the response carries what the receiving device
  /// reads over NFC.
  Future<Map<String, dynamic>> initNfcHandoff({
    required String hopId,
    required String geohashAtEvent,
  }) async {
    final response = await apiClient.authPost(
      '/v1/deliveries/hops/$hopId/handoff/nfc/init',
      data: {'geohashAtEvent': geohashAtEvent},
    );
    return (response as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> confirmNfcHandoff({
    required String hopId,
    required String handshakeId,
    required String signedChallenge,
    required String signerPublicKeyId,
    required String geohashAtEvent,
    String? proofPhotoUrl,
    String? notes,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.authPost(
      '/v1/deliveries/hops/$hopId/handoff/nfc/confirm',
      data: {
        'handshakeId': handshakeId,
        'signedChallenge': signedChallenge,
        'signerPublicKeyId': signerPublicKeyId,
        'geohashAtEvent': geohashAtEvent,
        if (proofPhotoUrl != null) 'proofPhotoUrl': proofPhotoUrl,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
      options: _idempotent(idempotencyKey),
    );
    return (response as Map).cast<String, dynamic>();
  }

  /// POST `/v1/deliveries/hops/{id}/handoff/delegated-receipt/check`.
  ///
  /// Read-only door check: it does not spend the authorisation and reveals
  /// only the delegate's name, relationship, what they may accept and when the
  /// grant ends — never the order, the customer or the address.
  Future<Map<String, dynamic>> checkDelegatedReceipt({
    required String hopId,
    required String verificationCode,
  }) async {
    final response = await apiClient.authPost(
      '/v1/deliveries/hops/$hopId/handoff/delegated-receipt/check',
      data: {'verificationCode': verificationCode},
    );
    return (response as Map).cast<String, dynamic>();
  }

  /// POST `/v1/deliveries/hops/{id}/exception`. [failHop] decides whether this
  /// ends the courier's leg or is only recorded against it — a weather delay
  /// is not a failure, a broken seal is.
  Future<void> reportException({
    required String hopId,
    required int code,
    required String geohashAtEvent,
    String? note,
    required bool failHop,
    required String idempotencyKey,
  }) async {
    await apiClient.authPost(
      '/v1/deliveries/hops/$hopId/exception',
      data: {
        'code': code,
        'geohashAtEvent': geohashAtEvent,
        if (note != null && note.isNotEmpty) 'note': note,
        'failHop': failHop,
      },
      options: _idempotent(idempotencyKey),
    );
  }

  // ── Proof photos ───────────────────────────────────────────────────────

  /// POST `/v1/deliveries/courier/proof-images` — uploads one JPG/PNG and
  /// returns the absolute URL to pass as `proofPhotoUrl`.
  ///
  /// Pickup and photo handoff both require that URL and validate it is
  /// absolute http(s), so this is not optional decoration: without it those
  /// calls cannot be made at all.
  Future<String> uploadProofPhoto({
    required File file,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.postFile(
      '/v1/deliveries/courier/proof-images',
      file: file,
      options: _idempotent(idempotencyKey),
    );
    return ((response as Map)['url'] as String?) ?? '';
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Matches the orders datasource: the interceptor reads requiresToken, and
  /// the backend's IdempotentAttribute reads Idempotency-Key. Every mutating
  /// courier call is marked Idempotent server-side, so a retried accept or a
  /// double-tapped pickup resolves to the one event rather than two.
  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );

  static List<Map<String, dynamic>> _mapList(dynamic response) =>
      (response as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
}
