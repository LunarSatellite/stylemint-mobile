import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_fare_mapper.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_payouts_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_payout.dart';

/// The rider's balance, earnings ledger and payouts (rider-payout contract
/// v1). Separate from `CourierRepository`, which is the delivery work; this
/// is the money side and has its own lifecycle (it 404s until deployed).
abstract class CourierPayoutsRepository {
  Future<Either<NetworkExceptions, CourierBalance>> getBalance();

  Future<Either<NetworkExceptions, CourierPage<CourierPayoutEarning>>>
  listEarnings({String? cursor, int pageSize});

  Future<Either<NetworkExceptions, CourierPage<CourierPayout>>> listPayouts({
    String? cursor,
    int pageSize,
  });

  /// [amount] null asks for the whole net payable.
  Future<Either<NetworkExceptions, CourierPayout>> requestPayout({
    required String destinationId,
    double? amount,
  });

  Future<Either<NetworkExceptions, Unit>> cancelPayout(String payoutId);
}

class CourierPayoutsRepositoryImpl implements CourierPayoutsRepository {
  CourierPayoutsRepositoryImpl(this._remote);

  final CourierPayoutsRemoteDataSource _remote;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, CourierBalance>> getBalance() =>
      _guard(() async => CourierPayoutMapper.balance(await _remote.getBalance()));

  @override
  Future<Either<NetworkExceptions, CourierPage<CourierPayoutEarning>>>
  listEarnings({String? cursor, int pageSize = 25}) => _guard(() async {
    final json = await _remote.listEarnings(cursor: cursor, pageSize: pageSize);
    return CourierPayoutMapper.page(json, CourierPayoutMapper.earning);
  });

  @override
  Future<Either<NetworkExceptions, CourierPage<CourierPayout>>> listPayouts({
    String? cursor,
    int pageSize = 25,
  }) => _guard(() async {
    final json = await _remote.listPayouts(cursor: cursor, pageSize: pageSize);
    return CourierPayoutMapper.page(json, CourierPayoutMapper.payout);
  });

  @override
  Future<Either<NetworkExceptions, CourierPayout>> requestPayout({
    required String destinationId,
    double? amount,
  }) => _guard(
    () async => CourierPayoutMapper.payout(
      await _remote.requestPayout(
        destinationId: destinationId,
        amount: amount,
        idempotencyKey: _uuid.v4(),
      ),
    ),
  );

  @override
  Future<Either<NetworkExceptions, Unit>> cancelPayout(String payoutId) =>
      _guard(() async {
        await _remote.cancelPayout(
          payoutId: payoutId,
          idempotencyKey: _uuid.v4(),
        );
        return unit;
      });

  /// No connectivity pre-check, unlike the delivery repository: a balance
  /// screen that says "offline" while the request would have worked is worse
  /// than letting Dio report a real connection error.
  Future<Either<NetworkExceptions, T>> _guard<T>(
    Future<T> Function() body,
  ) async {
    try {
      return right(await body());
    } catch (e) {
      if (e is DioException) return left(mapDioExceptionToNetworkException(e));
      if (e is NetworkExceptions) return left(e);
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}

/// JSON → payout entities. Tolerant: a missing number is 0 for balances
/// (the server always sends them) and null where null means something.
abstract final class CourierPayoutMapper {
  static CourierBalance balance(Map<String, dynamic> json) {
    final inFlight = json['inFlightPayout'];
    return CourierBalance(
      pendingEarnings: _num(json['pendingEarnings']) ?? 0,
      onHoldEarnings: _num(json['onHoldEarnings']) ?? 0,
      availableEarnings: _num(json['availableEarnings']) ?? 0,
      cashToRemit: _num(json['cashToRemit']) ?? 0,
      netPayable: _num(json['netPayable']) ?? 0,
      lifetimeEarnings: _num(json['lifetimeEarnings']) ?? 0,
      currency: _text(json['currency']) ?? 'NPR',
      settleAfterHours: _num(json['settleAfterHours'])?.toInt(),
      onDemandMinAmount: _num(json['onDemandMinAmount']),
      onDemandMaxAmount: _num(json['onDemandMaxAmount']),
      onDemandFeePercent: _num(json['onDemandFeePercent']),
      hasDefaultDestination: json['hasDefaultDestination'] == true,
      inFlightPayout: inFlight is Map
          ? payout(inFlight.cast<String, dynamic>())
          : null,
    );
  }

  static CourierPayoutEarning earning(Map<String, dynamic> json) {
    final currency = _text(json['currency']) ?? 'NPR';
    final rawFare = json['fareBreakdown'];
    final lines = rawFare is Map && rawFare['lines'] is List
        ? (rawFare['lines'] as List)
              .whereType<Map<dynamic, dynamic>>()
              .map((l) {
                final amount = _num(l['amount']);
                if (amount == null) return null;
                final code = _text(l['code']) ?? '';
                return FareLine(
                  code: code,
                  label: _text(l['label']) ?? code,
                  amount: amount,
                );
              })
              .whereType<FareLine>()
              .toList(growable: false)
        : const <FareLine>[];
    return CourierPayoutEarning(
      entryId: _text(json['entryId']) ?? '',
      hopId: _text(json['hopId']) ?? '',
      packageId: _text(json['packageId']),
      trackingNumber: _text(json['trackingNumber']),
      amount: _num(json['amount']) ?? 0,
      currency: currency,
      status: CourierEarningStatus.fromWire(json['status']),
      holdReason: _text(json['holdReason']),
      completedUtc: _date(json['completedUtc']),
      settleAfterUtc: _date(json['settleAfterUtc']),
      settledUtc: _date(json['settledUtc']),
      reversedUtc: _date(json['reversedUtc']),
      cashCollected: _positive(_num(json['cashCollected'])),
      fare: CourierFareMapper.breakdown(rawFare, fallbackCurrency: currency),
      lines: lines,
      fareMethodRoad: switch (rawFare is Map ? _text(rawFare['method'])?.toLowerCase() : null) {
        'road' => true,
        'estimated' => false,
        _ => null,
      },
      fareDistanceKm: rawFare is Map ? _num(rawFare['distanceKm']) : null,
      fareTier: rawFare is Map ? _text(rawFare['tier']) : null,
    );
  }

  static CourierPayout payout(Map<String, dynamic> json) => CourierPayout(
    id: _text(json['id']) ?? '',
    state: CourierPayoutState.fromWire(json['state']),
    requestedAmount: _num(json['requestedAmountValue']) ?? 0,
    feeAmount: _num(json['feeAmountValue']) ?? 0,
    netAmount: _num(json['netAmountValue']) ?? 0,
    currency:
        _text(json['netAmountCurrency']) ??
        _text(json['requestedAmountCurrency']) ??
        'NPR',
    automatic: _num(json['mode'])?.toInt() == 1,
    destinationKind: _num(json['destination'])?.toInt(),
    destinationRef: _text(json['destinationRef']),
    requestedUtc: _date(json['requestedUtc']),
    pendingUntilUtc: _date(json['pendingUntilUtc']),
    paidUtc: _date(json['paidUtc']),
    reference: _text(json['providerPayoutId']),
    failureCode: _text(json['failureCode']),
    failureMessage: _text(json['failureMessage']),
  );

  static CourierPage<T> page<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) item,
  ) {
    final items = (json['items'] is List ? json['items'] as List : const [])
        .whereType<Map<dynamic, dynamic>>()
        .map((m) => item(m.cast<String, dynamic>()))
        .toList(growable: false);
    final cursor = _text(json['nextCursor']);
    return CourierPage<T>(
      items: items,
      nextCursor: cursor,
      hasMore: json['hasMore'] == true && cursor != null,
    );
  }

  static double? _positive(double? value) =>
      value == null || value <= 0 ? null : value;

  static String? _text(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static double? _num(Object? value) => switch (value) {
    final num v => v.toDouble(),
    final String v => double.tryParse(v.trim()),
    _ => null,
  };

  /// UTC always; a zone-less timestamp is read as UTC.
  static DateTime? _date(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    final text = value.trim();
    final zoned =
        RegExp(r'(Z|[+-]\d{2}:?\d{2})$', caseSensitive: false).hasMatch(text) ||
            !text.contains('T')
        ? text
        : '${text}Z';
    return DateTime.tryParse(zoned)?.toUtc();
  }
}
