import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/repositories/courier_repository.dart';

class CourierRepositoryImpl implements CourierRepository {
  CourierRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CourierRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, CourierProfile?>> getMyProfile(
    String accountId,
  ) => _guard(() async {
    final json = await remoteDataSource.getByAccount(accountId);
    return json == null ? null : _profile(json);
  });

  @override
  Future<Either<NetworkExceptions, CourierProfile>> apply({
    required String homeGeohash,
    CourierVehicle? vehicle,
  }) => _guard(() async {
    final json = await remoteDataSource.apply(
      homeGeohash: homeGeohash,
      vehicle: vehicle?.wire,
    );
    return _profile(json);
  });

  @override
  Future<Either<NetworkExceptions, CourierProfile>> submitKyc({
    required String courierProfileId,
    required String governmentIdLast4,
    required String selfieMatchRef,
  }) => _guard(() async {
    final json = await remoteDataSource.submitKyc(
      courierProfileId: courierProfileId,
      governmentIdLast4: governmentIdLast4,
      selfieMatchRef: selfieMatchRef,
    );
    return _profile(json);
  });

  // ── Device keys ────────────────────────────────────────────────────────

  @override
  Future<Either<NetworkExceptions, List<CourierDeviceKeyInfo>>> listDeviceKeys(
    String courierProfileId,
  ) => _guard(() async {
    final rows = await remoteDataSource.listDeviceKeys(courierProfileId);
    return rows.map(_deviceKey).toList(growable: false);
  });

  @override
  Future<Either<NetworkExceptions, CourierDeviceKeyInfo>> registerDeviceKey({
    required String courierProfileId,
    required String publicKeyId,
    required String publicKeyPem,
    required String deviceModel,
  }) => _guard(() async {
    final json = await remoteDataSource.registerDeviceKey(
      courierProfileId: courierProfileId,
      publicKeyId: publicKeyId,
      publicKeyPem: publicKeyPem,
      deviceModel: deviceModel,
    );
    return _deviceKey(json);
  });

  @override
  Future<Either<NetworkExceptions, Unit>> revokeDeviceKey({
    required String publicKeyId,
    required String reason,
  }) => _guard(() async {
    await remoteDataSource.revokeDeviceKey(
      publicKeyId: publicKeyId,
      reason: reason,
    );
    return unit;
  });

  // ── Travel plans ───────────────────────────────────────────────────────

  @override
  Future<Either<NetworkExceptions, List<CourierTravelPlan>>> listTravelPlans(
    String courierProfileId,
  ) => _guard(() async {
    final rows = await remoteDataSource.listTravelPlans(courierProfileId);
    return rows.map(_travelPlan).toList(growable: false);
  });

  @override
  Future<Either<NetworkExceptions, CourierTravelPlan>> declareTravelPlan({
    required String courierProfileId,
    required String originGeohash,
    required String destinationGeohash,
    required DateTime departsUtcStart,
    required DateTime departsUtcEnd,
    required DateTime arrivesUtcExpected,
    required CourierVehicle vehicle,
    required double maxWeightGrams,
  }) => _guard(() async {
    final json = await remoteDataSource.declareTravelPlan(
      courierProfileId: courierProfileId,
      originGeohash: originGeohash,
      destinationGeohash: destinationGeohash,
      departsUtcStart: departsUtcStart,
      departsUtcEnd: departsUtcEnd,
      arrivesUtcExpected: arrivesUtcExpected,
      vehicle: vehicle.wire,
      maxWeightGrams: maxWeightGrams,
    );
    return _travelPlan(json);
  });

  @override
  Future<Either<NetworkExceptions, Unit>> cancelTravelPlan({
    required String travelPlanId,
    required String reason,
  }) => _guard(() async {
    await remoteDataSource.cancelTravelPlan(
      travelPlanId: travelPlanId,
      reason: reason,
    );
    return unit;
  });

  // ── Standing ───────────────────────────────────────────────────────────

  @override
  Future<Either<NetworkExceptions, CourierReliability?>> getReliability(
    String courierProfileId,
  ) => _guard(() async {
    final json = await remoteDataSource.getReliability(courierProfileId);
    return json == null ? null : _reliability(json);
  });

  @override
  Future<Either<NetworkExceptions, List<CourierReliability>>>
  getReliabilityHistory(String courierProfileId) => _guard(() async {
    final rows = await remoteDataSource.getReliabilityHistory(courierProfileId);
    return rows.map(_reliability).toList(growable: false);
  });

  @override
  Future<Either<NetworkExceptions, CourierMoney>> getEscrowBalance(
    String courierProfileId,
  ) => _guard(() async {
    final json = await remoteDataSource.getEscrowBalance(courierProfileId);
    return CourierMoney(
      amount: _double(json['amount']),
      currency: (json['currency'] as String?) ?? 'NPR',
    );
  });

  // ── Offers ─────────────────────────────────────────────────────────────

  @override
  Future<Either<NetworkExceptions, List<HopOffer>>> listOffers() =>
      _guard(() async {
        final rows = await remoteDataSource.listOffers();
        return rows.map(_offer).toList(growable: false);
      });

  @override
  Future<Either<NetworkExceptions, HopOffer>> acceptOffer(String offerId) =>
      _guard(() async {
        final json = await remoteDataSource.acceptOffer(
          offerId: offerId,
          idempotencyKey: _uuid.v4(),
        );
        return _offer(json);
      });

  @override
  Future<Either<NetworkExceptions, Unit>> declineOffer({
    required String offerId,
    required DeclineReason reason,
    String? note,
  }) => _guard(() async {
    await remoteDataSource.declineOffer(
      offerId: offerId,
      reasonCode: reason.wire,
      note: note,
      idempotencyKey: _uuid.v4(),
    );
    return unit;
  });

  // ── Hops ───────────────────────────────────────────────────────────────

  @override
  Future<Either<NetworkExceptions, List<DeliveryHop>>> listMyHops() =>
      _guard(() async {
        final rows = await remoteDataSource.listMyHops();
        return rows.map(_hop).toList(growable: false);
      });

  @override
  Future<Either<NetworkExceptions, CourierEarnings>> getEarnings() =>
      _guard(() async => _earnings(await remoteDataSource.getEarnings()));

  @override
  Future<Either<NetworkExceptions, List<CourierEarningRow>>>
  listEarningsHistory({int skip = 0, int take = 20}) => _guard(() async {
    final rows = await remoteDataSource.listEarningsHistory(
      skip: skip,
      take: take,
    );
    return rows.map(_earningRow).toList(growable: false);
  });

  @override
  Future<Either<NetworkExceptions, Unit>> pickup({
    required String hopId,
    required String geohashAtEvent,
    required String proofPhotoUrl,
    required String signature,
    required String signerPublicKeyId,
  }) => _guard(() async {
    await remoteDataSource.pickup(
      hopId: hopId,
      geohashAtEvent: geohashAtEvent,
      proofPhotoUrl: proofPhotoUrl,
      signature: signature,
      signerPublicKeyId: signerPublicKeyId,
      idempotencyKey: _uuid.v4(),
    );
    return unit;
  });

  @override
  Future<Either<NetworkExceptions, Unit>> photoHandoff({
    required String hopId,
    String? nextCourierProfileId,
    required String geohashAtEvent,
    required String proofPhotoUrl,
    required String signature,
    required String signerPublicKeyId,
    String? notes,
    required bool isFinalDelivery,
  }) => _guard(() async {
    await remoteDataSource.photoHandoff(
      hopId: hopId,
      nextCourierProfileId: nextCourierProfileId,
      geohashAtEvent: geohashAtEvent,
      proofPhotoUrl: proofPhotoUrl,
      signature: signature,
      signerPublicKeyId: signerPublicKeyId,
      notes: notes,
      isFinalDelivery: isFinalDelivery,
      idempotencyKey: _uuid.v4(),
    );
    return unit;
  });

  @override
  Future<Either<NetworkExceptions, Unit>> reportException({
    required String hopId,
    required DeliveryExceptionCode code,
    required String geohashAtEvent,
    String? note,
    required bool failHop,
  }) => _guard(() async {
    await remoteDataSource.reportException(
      hopId: hopId,
      code: code.wire,
      geohashAtEvent: geohashAtEvent,
      note: note,
      failHop: failHop,
      idempotencyKey: _uuid.v4(),
    );
    return unit;
  });

  // ── Plumbing ───────────────────────────────────────────────────────────

  /// Same shape as the other repositories here: offline is its own failure
  /// rather than a Dio timeout, and anything unrecognised becomes
  /// unexpectedError instead of escaping as a raw exception.
  Future<Either<NetworkExceptions, T>> _guard<T>(
    Future<T> Function() body,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      return right(await body());
    } catch (e) {
      if (e is DioException) return left(mapDioExceptionToNetworkException(e));
      if (e is NetworkExceptions) return left(e);
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  // ── Mappers ────────────────────────────────────────────────────────────
  //
  // Hand-written rather than generated: these DTOs come from three different
  // backend modules and carry fields this app has no use for, and a mapper
  // that names what it reads fails loudly on a rename instead of silently
  // producing a default.

  static CourierProfile _profile(Map<String, dynamic> json) => CourierProfile(
    id: _string(json['id']),
    accountId: _string(json['accountId']),
    state: CourierProfileState.fromWire(_int(json['state'])),
    tier: DeliveryTier.fromWire(_int(json['currentTier'])),
    homeGeohash: _string(json['homeGeohash']),
    vehicle: CourierVehicle.fromWire(_intOrNull(json['vehicle'])),
    escrowHeldAmount: _double(json['escrowHeldAmount']),
    escrowRequiredAmount: _double(json['escrowRequiredAmount']),
    escrowCurrency: (json['escrowCurrency'] as String?) ?? 'NPR',
    kycVerifiedUtc: _dateOrNull(json['kycVerifiedUtc']),
    suspendedReason: json['suspendedReason'] as String?,
    failureStreak: _int(json['failureStreak']) ?? 0,
    // Resolved from Identity server-side; absent on older responses, and
    // genuinely absent for an account with no name or no email set.
    accountDisplayName: json['accountDisplayName'] as String?,
    accountEmail: json['accountEmail'] as String?,
    accountPhone: json['accountPhone'] as String?,
  );

  static CourierDeviceKeyInfo _deviceKey(Map<String, dynamic> json) =>
      CourierDeviceKeyInfo(
        id: _string(json['id']),
        publicKeyId: _string(json['publicKeyId']),
        deviceModel: _string(json['deviceModel']),
        registeredUtc: _date(json['registeredUtc']),
        state: DeviceKeyState.fromWire(_int(json['state'])),
        revokedUtc: _dateOrNull(json['revokedUtc']),
        revocationReason: json['revocationReason'] as String?,
      );

  static CourierTravelPlan _travelPlan(Map<String, dynamic> json) =>
      CourierTravelPlan(
        id: _string(json['id']),
        originGeohash: _string(json['originGeohash']),
        destinationGeohash: _string(json['destinationGeohash']),
        departsUtcStart: _date(json['departsUtcStart']),
        departsUtcEnd: _date(json['departsUtcEnd']),
        arrivesUtcExpected: _date(json['arrivesUtcExpected']),
        vehicle: CourierVehicle.fromWire(_intOrNull(json['vehicle'])),
        maxWeightGrams: _double(json['maxWeightGrams']),
        state: TravelPlanState.fromWire(_int(json['state'])),
        cancellationReason: json['cancellationReason'] as String?,
      );

  static CourierReliability _reliability(Map<String, dynamic> json) =>
      CourierReliability(
        windowStartUtc: _date(json['windowStartUtc']),
        windowEndUtc: _date(json['windowEndUtc']),
        hopsCompleted: _int(json['hopsCompleted']) ?? 0,
        hopsAccepted: _int(json['hopsAccepted']) ?? 0,
        hopsDeclined: _int(json['hopsDeclined']) ?? 0,
        hopsFailed: _int(json['hopsFailed']) ?? 0,
        hopsOnTime: _int(json['hopsOnTime']) ?? 0,
        averageCustomerRating: _double(json['averageCustomerRating']),
        onTimeRate: _double(json['onTimeRate']),
        acceptanceRate: _double(json['acceptanceRate']),
        reliabilityScore: _double(json['reliabilityScore']),
      );

  static HopOffer _offer(Map<String, dynamic> json) => HopOffer(
    id: _string(json['id']),
    packageId: _string(json['packageId']),
    tier: DeliveryTier.fromWire(_int(json['tier'])),
    hopIndex: _int(json['hopIndex']) ?? 0,
    roundNumber: _int(json['roundNumber']) ?? 1,
    proposedPayoutAmount: _double(json['proposedPayoutAmount']),
    proposedPayoutCurrency:
        (json['proposedPayoutCurrency'] as String?) ?? 'NPR',
    fromGeohash: _string(json['fromGeohash']),
    toGeohash: _string(json['toGeohash']),
    state: HopOfferState.fromWire(_int(json['state'])),
    offeredUtc: _date(json['offeredUtc']),
    expiresUtc: _date(json['expiresUtc']),
  );

  static CourierEarnings _earnings(Map<String, dynamic> json) =>
      CourierEarnings(
        totalEarned: _double(json['totalEarned']),
        last7Days: _double(json['last7Days']),
        last30Days: _double(json['last30Days']),
        completedHops: _int(json['completedHops']) ?? 0,
        // Not defaulted to NPR. The server leaves this empty for a courier
        // who has completed nothing, and stamping a currency on a zero would
        // tell a rider they are paid in one we invented.
        currency: (json['currency'] as String?) ?? '',
        lastEarnedUtc: _dateOrNull(json['lastEarnedUtc']),
      );

  static CourierEarningRow _earningRow(Map<String, dynamic> json) =>
      CourierEarningRow(
        hopId: _string(json['hopId']),
        packageId: _string(json['packageId']),
        hopIndex: _int(json['hopIndex']) ?? 0,
        amount: _double(json['amount']),
        currency: (json['currency'] as String?) ?? '',
        fromGeohash: _string(json['fromGeohash']),
        toGeohash: _string(json['toGeohash']),
        handedOffUtc: _dateOrNull(json['handedOffUtc']),
      );

  static DeliveryHop _hop(Map<String, dynamic> json) => DeliveryHop(
    id: _string(json['id']),
    packageId: _string(json['packageId']),
    hopIndex: _int(json['hopIndex']) ?? 0,
    tier: DeliveryTier.fromWire(_int(json['tier'])),
    courierProfileId: _string(json['courierProfileId']),
    state: HopState.fromWire(_int(json['state'])),
    fromGeohash: _string(json['fromGeohash']),
    toGeohash: _string(json['toGeohash']),
    payoutAmount: _double(json['courierPayoutAmount']),
    payoutCurrency: (json['courierPayoutCurrency'] as String?) ?? 'NPR',
    acceptedUtc: _dateOrNull(json['acceptedUtc']),
    pickedUpUtc: _dateOrNull(json['pickedUpUtc']),
    handedOffUtc: _dateOrNull(json['handedOffUtc']),
    etaUtc: _dateOrNull(json['etaUtc']),
    failureCode: _exceptionCode(_intOrNull(json['failureCode'])),
    failureNote: json['failureNote'] as String?,
  );

  static DeliveryExceptionCode? _exceptionCode(int? wire) => wire == null
      ? null
      : DeliveryExceptionCode.values
            .where((c) => c.wire == wire)
            .firstOrNull;

  static String _string(dynamic value) => (value as String?) ?? '';

  static int? _int(dynamic value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v),
    _ => null,
  };

  static int? _intOrNull(dynamic value) => value == null ? null : _int(value);

  static double _double(dynamic value) => switch (value) {
    final num v => v.toDouble(),
    final String v => double.tryParse(v) ?? 0,
    _ => 0,
  };

  /// Dates arrive as ISO-8601 with an offset. Always normalised to UTC: hop
  /// ETAs and offer expiry are compared against `DateTime.now().toUtc()`, and
  /// mixing a local and a UTC instant makes a countdown wrong by the device's
  /// timezone offset.
  static DateTime _date(dynamic value) =>
      _dateOrNull(value) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  static DateTime? _dateOrNull(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }
}
