import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/data/datasources/try_on_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/data/try_on_failure_mapper.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/repositories/try_on_repository.dart';

class TryOnRepositoryImpl implements TryOnRepository {
  TryOnRepositoryImpl({required this.remote, required this.networkInfo});

  final TryOnRemoteDataSource remote;
  final NetworkInfoConnectivity networkInfo;

  Future<Either<TryOnFailure, T>> _call<T>(Future<T> Function() call) =>
      guardedTryOnCall(networkInfo, call);

  /// A 404 that means "nothing yet" rather than an error.
  Future<Either<TryOnFailure, T?>> _orNullOn404<T>(
    Future<T> Function() call,
  ) async {
    final result = await _call(call);
    return result.fold(
      (f) => f.isNotFound ? right(null) : left(f),
      right,
    );
  }

  @override
  Future<Either<TryOnFailure, TryOnAccess>> getAccess() =>
      _call(remote.getAccess);

  @override
  Future<Either<TryOnFailure, TryOnAccess>> startTrial({
    required String idempotencyKey,
  }) => _call(() => remote.startTrial(idempotencyKey));

  @override
  Future<Either<TryOnFailure, TryOnPaymentStart>> subscribe({
    required String planId,
    required TryOnPaymentRail rail,
    required String idempotencyKey,
  }) => _call(
    () => remote.subscribe(
      planId: planId,
      paymentMethod: rail.wire,
      idempotencyKey: idempotencyKey,
    ),
  );

  @override
  Future<Either<TryOnFailure, MyTryOnSubscription>> confirmSubscription({
    required String subscriptionId,
    required String idempotencyKey,
  }) => _call(
    () => remote.confirm(
      subscriptionId: subscriptionId,
      idempotencyKey: idempotencyKey,
    ),
  );

  @override
  Future<Either<TryOnFailure, List<MyTryOnSubscription>>> mySubscriptions() =>
      _call(remote.mySubscriptions);

  @override
  Future<Either<TryOnFailure, BodyMeasurements?>> getMeasurements() =>
      _orNullOn404(remote.getMeasurements);

  @override
  Future<Either<TryOnFailure, BodyMeasurements>> saveMeasurements(
    BodyMeasurements measurements, {
    required String idempotencyKey,
  }) => _call(() => remote.putMeasurements(measurements, idempotencyKey));

  @override
  Future<Either<TryOnFailure, TryOnProduct>> getProduct(String productId) =>
      _call(() => remote.getProduct(productId));

  @override
  Future<Either<TryOnFailure, FitRecommendation>> getFit(String productId) =>
      _call(() => remote.getFit(productId));

  @override
  Future<Either<TryOnFailure, Unit>> recordSession({
    required String productId,
    required TryOnMode mode,
    required String idempotencyKey,
    String? chosenSize,
  }) => _call(() async {
    await remote.recordSession(
      productId: productId,
      mode: mode.wire,
      chosenSize: chosenSize,
      idempotencyKey: idempotencyKey,
    );
    return unit;
  });

  @override
  Future<Either<TryOnFailure, SizeChart?>> getPublicSizeChart(
    String productId,
  ) => _orNullOn404(() => remote.getPublicSizeChart(productId));
}
