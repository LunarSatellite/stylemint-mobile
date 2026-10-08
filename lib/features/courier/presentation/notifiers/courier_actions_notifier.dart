import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_device_key.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/custody_attestation.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/geohash.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/repositories/courier_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/services/location_capture_service.dart';

/// Outcome of a courier action, in the terms the screens need to react to.
///
/// Not a generic `Either`: the custody actions have failure modes that are
/// neither a network error nor a server rejection — no signing key on this
/// device, or no location fix — and both need a specific screen rather than a
/// red snackbar. Flattening them into "something went wrong" is how a courier
/// ends up tapping Collect repeatedly at a doorstep.
sealed class CourierActionResult {
  const CourierActionResult();
}

final class CourierActionOk extends CourierActionResult {
  const CourierActionOk();
}

final class CourierActionFailed extends CourierActionResult {
  const CourierActionFailed(this.failure);
  final NetworkExceptions failure;
}

/// This device holds no usable signing key, so no custody event can be signed.
/// The screen sends the courier to device-key enrolment.
final class CourierActionNeedsDeviceKey extends CourierActionResult {
  const CourierActionNeedsDeviceKey();
}

/// Location is unavailable or was refused. Every custody event records where it
/// happened, so there is nothing to send without it.
final class CourierActionNeedsLocation extends CourierActionResult {
  const CourierActionNeedsLocation({required this.permanentlyDenied});

  /// True when the OS will not ask again — the screen has to send them to
  /// settings rather than retry, which would silently do nothing.
  final bool permanentlyDenied;
}

class CourierActionsNotifier extends StateNotifier<bool> {
  CourierActionsNotifier({
    required CourierRepository repository,
    required CourierRemoteDataSource dataSource,
    required CourierDeviceKey deviceKey,
    required LocationCaptureService location,
  }) : _repository = repository,
       _dataSource = dataSource,
       _deviceKey = deviceKey,
       _location = location,
       super(false);

  final CourierRepository _repository;
  final CourierRemoteDataSource _dataSource;
  final CourierDeviceKey _deviceKey;
  final LocationCaptureService _location;

  static const _uuid = Uuid();

  /// True while an action is in flight, so screens can disable their buttons.
  bool get busy => state;

  // ── Onboarding ─────────────────────────────────────────────────────────

  /// Applies using the device's current location as the home area.
  ///
  /// Five characters of precision, not nine: the router matches on a 5-char
  /// prefix anyway, and recording where a courier lives to street level buys
  /// nothing and gives away a lot.
  Future<CourierActionResult> apply({CourierVehicle? vehicle}) =>
      _guarded(() async {
        final fix = await _location.capture();
        final located = _requireLocation(fix);
        if (located is! _Located) return located.asResult;

        final result = await _repository.apply(
          homeGeohash: encodeGeohash(
            located.latitude,
            located.longitude,
            precision: serviceAreaPrecision,
          ),
          vehicle: vehicle,
        );
        return result.fold(CourierActionFailed.new, (_) => const CourierActionOk());
      });

  Future<CourierActionResult> submitKyc({
    required String courierProfileId,
    required String governmentIdLast4,
    required String selfieMatchRef,
  }) => _guarded(() async {
    final result = await _repository.submitKyc(
      courierProfileId: courierProfileId,
      governmentIdLast4: governmentIdLast4,
      selfieMatchRef: selfieMatchRef,
    );
    return result.fold(CourierActionFailed.new, (_) => const CourierActionOk());
  });

  /// Goes on or off shift.
  ///
  /// Takes the desired state rather than toggling, so a double tap or a retry
  /// lands where the rider pointed instead of flipping back.
  ///
  /// Going online carries the rider's position when one can be had quickly,
  /// so they are matched by distance at once. Best effort and bounded: no fix
  /// within a few seconds, or no permission, and the rider goes online
  /// without one — the location reporter sends it as soon as it has it.
  Future<CourierActionResult> setShift({
    required String courierProfileId,
    required bool online,
  }) => _guarded(() async {
    double? latitude;
    double? longitude;
    if (online) {
      try {
        final fix = await _location.capture(timeout: _shiftFixTimeout);
        if (fix is LocationCaptured) {
          latitude = fix.latitude;
          longitude = fix.longitude;
        }
      } catch (_) {
        // A position is a nicety here; going online is the point.
      }
    }
    final result = await _repository.setShift(
      courierProfileId: courierProfileId,
      online: online,
      latitude: latitude,
      longitude: longitude,
    );
    return result.fold(CourierActionFailed.new, (_) => const CourierActionOk());
  });

  /// How long going online waits for a GPS fix before going without one.
  static const _shiftFixTimeout = Duration(seconds: 4);

  /// Generates a keypair, registers the public half, and only then marks it as
  /// this device's signing key.
  ///
  /// The order matters. Marking it active first would leave the device signing
  /// with a key the server has never heard of if registration failed, and every
  /// later pickup would fail at `Unknown signer public key id` with nothing on
  /// screen connecting the two.
  Future<CourierActionResult> enrolDeviceKey({
    required String courierProfileId,
    required String deviceModel,
  }) => _guarded(() async {
    final generated = await _deviceKey.generate();
    final result = await _repository.registerDeviceKey(
      courierProfileId: courierProfileId,
      publicKeyId: generated.keyId,
      publicKeyPem: generated.publicKeyPem,
      deviceModel: deviceModel,
    );
    return result.fold(
      (failure) async {
        // Registration failed, so drop the local half rather than leave an
        // orphan private key in secure storage that nothing can use.
        await _deviceKey.forget(generated.keyId);
        return CourierActionFailed(failure);
      },
      (_) async {
        await _deviceKey.markActive(generated.keyId);
        return const CourierActionOk();
      },
    );
  });

  Future<CourierActionResult> revokeDeviceKey({
    required String publicKeyId,
    required String reason,
  }) => _guarded(() async {
    final result = await _repository.revokeDeviceKey(
      publicKeyId: publicKeyId,
      reason: reason,
    );
    return result.fold(CourierActionFailed.new, (_) async {
      await _deviceKey.forget(publicKeyId);
      return const CourierActionOk();
    });
  });

  // ── Offers ─────────────────────────────────────────────────────────────

  Future<CourierActionResult> acceptOffer(String offerId) => _guarded(() async {
    final result = await _repository.acceptOffer(offerId);
    return result.fold(CourierActionFailed.new, (_) => const CourierActionOk());
  });

  /// Takes back interest in a vendor-select offer.
  Future<CourierActionResult> withdrawInterest(String offerId) =>
      _guarded(() async {
        final result = await _repository.withdrawInterest(offerId);
        return result.fold(
          CourierActionFailed.new,
          (_) => const CourierActionOk(),
        );
      });

  Future<CourierActionResult> declineOffer({
    required String offerId,
    required DeclineReason reason,
    String? note,
  }) => _guarded(() async {
    final result = await _repository.declineOffer(
      offerId: offerId,
      reason: reason,
      note: note,
    );
    return result.fold(CourierActionFailed.new, (_) => const CourierActionOk());
  });

  // ── Custody events ─────────────────────────────────────────────────────

  /// Records a pickup: fix the location, upload the proof photo, sign the
  /// attestation, send.
  ///
  /// The attestation is built here rather than in the repository because it has
  /// to describe the event exactly as the server will reconstruct it — for a
  /// pickup that means `fromCourier` is null (the parcel came from the vendor)
  /// and `toCourier` is this courier. Getting either wrong produces a valid
  /// signature over the wrong statement, which fails verification and looks
  /// identical to a key problem.
  Future<CourierActionResult> pickup({
    required DeliveryHop hop,
    required File proofPhoto,
  }) => _guarded(() async {
    final fix = await _location.capture();
    final located = _requireLocation(fix);
    if (located is! _Located) return located.asResult;
    final geohash = encodeGeohash(located.latitude, located.longitude);

    final keyId = await _deviceKey.currentKeyId();
    if (keyId == null || !await _deviceKey.hasKey()) {
      return const CourierActionNeedsDeviceKey();
    }

    final signature = await _deviceKey.sign(
      buildCustodyAttestation(
        packageId: hop.packageId,
        eventKind: ChainEventKind.pickedUp,
        fromCourierProfileId: null,
        toCourierProfileId: hop.courierProfileId,
        geohashAtEvent: geohash,
      ),
    );
    if (signature == null) return const CourierActionNeedsDeviceKey();

    final String photoUrl;
    try {
      photoUrl = await _dataSource.uploadProofPhoto(
        file: proofPhoto,
        idempotencyKey: _uuid.v4(),
      );
    } catch (_) {
      return const CourierActionFailed(NetworkExceptions.unexpectedError());
    }
    if (photoUrl.isEmpty) {
      return const CourierActionFailed(NetworkExceptions.unexpectedError());
    }

    final result = await _repository.pickup(
      hopId: hop.id,
      geohashAtEvent: geohash,
      proofPhotoUrl: photoUrl,
      signature: signature,
      signerPublicKeyId: keyId,
    );
    return result.fold(CourierActionFailed.new, (_) => const CourierActionOk());
  });

  /// Hands the parcel on, or delivers it.
  ///
  /// [nextCourierProfileId] null together with [isFinalDelivery] true is a
  /// delivery to the buyer; a non-null id is a courier-to-courier handoff. The
  /// event kind follows that distinction, because the server signs and verifies
  /// against it.
  Future<CourierActionResult> handoff({
    required DeliveryHop hop,
    required File proofPhoto,
    String? nextCourierProfileId,
    required bool isFinalDelivery,
    String? notes,
  }) => _guarded(() async {
    final fix = await _location.capture();
    final located = _requireLocation(fix);
    if (located is! _Located) return located.asResult;
    final geohash = encodeGeohash(located.latitude, located.longitude);

    final keyId = await _deviceKey.currentKeyId();
    if (keyId == null || !await _deviceKey.hasKey()) {
      return const CourierActionNeedsDeviceKey();
    }

    final signature = await _deviceKey.sign(
      buildCustodyAttestation(
        packageId: hop.packageId,
        eventKind: isFinalDelivery
            ? ChainEventKind.deliveryConfirmed
            : ChainEventKind.handedOff,
        // This courier is giving the parcel up, so they are the FROM party.
        fromCourierProfileId: hop.courierProfileId,
        toCourierProfileId: nextCourierProfileId,
        geohashAtEvent: geohash,
      ),
    );
    if (signature == null) return const CourierActionNeedsDeviceKey();

    final String photoUrl;
    try {
      photoUrl = await _dataSource.uploadProofPhoto(
        file: proofPhoto,
        idempotencyKey: _uuid.v4(),
      );
    } catch (_) {
      return const CourierActionFailed(NetworkExceptions.unexpectedError());
    }
    if (photoUrl.isEmpty) {
      return const CourierActionFailed(NetworkExceptions.unexpectedError());
    }

    final result = await _repository.photoHandoff(
      hopId: hop.id,
      nextCourierProfileId: nextCourierProfileId,
      geohashAtEvent: geohash,
      proofPhotoUrl: photoUrl,
      signature: signature,
      signerPublicKeyId: keyId,
      notes: notes,
      isFinalDelivery: isFinalDelivery,
    );
    return result.fold(CourierActionFailed.new, (_) => const CourierActionOk());
  });

  /// Reports a problem. No signature and no photo — the exception endpoint
  /// takes neither, because a courier whose phone cannot sign or whose parcel
  /// is gone still has to be able to say so.
  Future<CourierActionResult> reportException({
    required String hopId,
    required DeliveryExceptionCode code,
    String? note,
    required bool failHop,
  }) => _guarded(() async {
    final fix = await _location.capture();
    final located = _requireLocation(fix);
    if (located is! _Located) return located.asResult;

    final result = await _repository.reportException(
      hopId: hopId,
      code: code,
      geohashAtEvent: encodeGeohash(located.latitude, located.longitude),
      note: note,
      failHop: failHop,
    );
    return result.fold(CourierActionFailed.new, (_) => const CourierActionOk());
  });

  // ── Plumbing ───────────────────────────────────────────────────────────

  /// Serialises actions and exposes a busy flag. A second tap while one is in
  /// flight is dropped rather than queued: these calls are idempotent on the
  /// server, but a queued duplicate pickup would still fail the replay check
  /// and show the courier an error for something that worked.
  Future<CourierActionResult> _guarded(
    Future<CourierActionResult> Function() body,
  ) async {
    if (state) return const CourierActionOk();
    state = true;
    try {
      return await body();
    } catch (e) {
      if (e is NetworkExceptions) return CourierActionFailed(e);
      return const CourierActionFailed(NetworkExceptions.unexpectedError());
    } finally {
      state = false;
    }
  }

  _LocationOutcome _requireLocation(LocationCaptureResult result) =>
      switch (result) {
        LocationCaptured(:final latitude, :final longitude) => _Located(
          latitude,
          longitude,
        ),
        LocationPermissionDeniedForever() => const _NotLocated(
          permanentlyDenied: true,
        ),
        _ => const _NotLocated(permanentlyDenied: false),
      };
}

sealed class _LocationOutcome {
  const _LocationOutcome();
  CourierActionResult get asResult;
}

final class _Located extends _LocationOutcome {
  const _Located(this.latitude, this.longitude);
  final double latitude;
  final double longitude;

  @override
  CourierActionResult get asResult => const CourierActionOk();
}

final class _NotLocated extends _LocationOutcome {
  const _NotLocated({required this.permanentlyDenied});
  final bool permanentlyDenied;

  @override
  CourierActionResult get asResult =>
      CourierActionNeedsLocation(permanentlyDenied: permanentlyDenied);
}
