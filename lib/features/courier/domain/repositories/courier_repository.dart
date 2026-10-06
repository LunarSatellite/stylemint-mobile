import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';

/// An amount with its currency — the escrow balance endpoint returns a
/// MoneyDto and nothing else in this feature needs the shared Money type's
/// formatting.
class CourierMoney {
  const CourierMoney({required this.amount, required this.currency});

  final double amount;
  final String currency;
}

/// The delivery-partner surface.
///
/// Spans three backend modules (DeliveryCouriers, DeliveryRouting, Delivery)
/// behind one interface, because from the courier's point of view applying,
/// being offered work and carrying it are one job. The split is a server-side
/// ownership boundary and leaking it into the app would mean three
/// repositories for one screen flow.
abstract class CourierRepository {
  /// Null when this account has no courier profile — not an error. Most
  /// accounts are buyers, so "are you a courier?" has a legitimate no.
  Future<Either<NetworkExceptions, CourierProfile?>> getMyProfile(
    String accountId,
  );

  Future<Either<NetworkExceptions, CourierProfile>> apply({
    required String homeGeohash,
    CourierVehicle? vehicle,
  });

  /// Moves the profile to KycInReview. Approval is an admin action on a
  /// different endpoint, so a courier cannot approve themselves by calling
  /// this twice.
  Future<Either<NetworkExceptions, CourierProfile>> submitKyc({
    required String courierProfileId,
    required String governmentIdLast4,
    required String selfieMatchRef,
  });

  /// Goes on or off shift. Being online is what decides whether parcels are
  /// offered — see the backend's CourierProfile.IsOnline.
  Future<Either<NetworkExceptions, CourierProfile>> setShift({
    required String courierProfileId,
    required bool online,
  });

  // ── Device keys ────────────────────────────────────────────────────────

  Future<Either<NetworkExceptions, List<CourierDeviceKeyInfo>>> listDeviceKeys(
    String courierProfileId,
  );

  Future<Either<NetworkExceptions, CourierDeviceKeyInfo>> registerDeviceKey({
    required String courierProfileId,
    required String publicKeyId,
    required String publicKeyPem,
    required String deviceModel,
  });

  Future<Either<NetworkExceptions, Unit>> revokeDeviceKey({
    required String publicKeyId,
    required String reason,
  });

  // ── Travel plans ───────────────────────────────────────────────────────

  Future<Either<NetworkExceptions, List<CourierTravelPlan>>> listTravelPlans(
    String courierProfileId,
  );

  Future<Either<NetworkExceptions, CourierTravelPlan>> declareTravelPlan({
    required String courierProfileId,
    required String originGeohash,
    required String destinationGeohash,
    required DateTime departsUtcStart,
    required DateTime departsUtcEnd,
    required DateTime arrivesUtcExpected,
    required CourierVehicle vehicle,
    required double maxWeightGrams,
  });

  Future<Either<NetworkExceptions, Unit>> cancelTravelPlan({
    required String travelPlanId,
    required String reason,
  });

  // ── Standing ───────────────────────────────────────────────────────────

  /// Null when no window has been computed yet — a courier who has carried
  /// nothing has no reliability, which is different from a score of zero.
  Future<Either<NetworkExceptions, CourierReliability?>> getReliability(
    String courierProfileId,
  );

  Future<Either<NetworkExceptions, List<CourierReliability>>>
  getReliabilityHistory(String courierProfileId);

  Future<Either<NetworkExceptions, CourierMoney>> getEscrowBalance(
    String courierProfileId,
  );

  // ── Offers ─────────────────────────────────────────────────────────────

  Future<Either<NetworkExceptions, List<HopOffer>>> listOffers();

  Future<Either<NetworkExceptions, HopOffer>> acceptOffer(String offerId);

  Future<Either<NetworkExceptions, Unit>> declineOffer({
    required String offerId,
    required DeclineReason reason,
    String? note,
  });

  // ── Hops ───────────────────────────────────────────────────────────────

  /// The work list. Also the only source of hop ids: accepting an offer does
  /// not reveal one, because `HopOfferDto` carries the package id and the hop
  /// index but no hop id.
  Future<Either<NetworkExceptions, List<DeliveryHop>>> listMyHops();

  /// What this courier has earned from completed hops.
  ///
  /// Distinct from the escrow balance, which is their own deposit. See
  /// [CourierEarnings].
  Future<Either<NetworkExceptions, CourierEarnings>> getEarnings();

  /// The completed hops behind that total, newest first.
  Future<Either<NetworkExceptions, List<CourierEarningRow>>>
  listEarningsHistory({int skip, int take});

  /// [signature] must cover the canonical attestation for this event. Build it
  /// with `buildCustodyAttestation` and sign with `CourierDeviceKey.sign` —
  /// the server rebuilds the same string and verifies against it, so an
  /// arbitrary value is rejected rather than ignored.
  Future<Either<NetworkExceptions, Unit>> pickup({
    required String hopId,
    required String geohashAtEvent,
    required String proofPhotoUrl,
    required String signature,
    required String signerPublicKeyId,
  });

  /// Hand on to the next courier, or deliver to the buyer when
  /// [isFinalDelivery]. Same call either way; what differs is whether
  /// [nextCourierProfileId] is set.
  Future<Either<NetworkExceptions, Unit>> photoHandoff({
    required String hopId,
    String? nextCourierProfileId,
    required String geohashAtEvent,
    required String proofPhotoUrl,
    required String signature,
    required String signerPublicKeyId,
    String? notes,
    required bool isFinalDelivery,
  });

  /// [failHop] ends the courier's leg. A weather delay is worth recording
  /// without ending anything; a broken seal moves the package to Returning
  /// server-side whatever is passed here.
  Future<Either<NetworkExceptions, Unit>> reportException({
    required String hopId,
    required DeliveryExceptionCode code,
    required String geohashAtEvent,
    String? note,
    required bool failHop,
  });
}
