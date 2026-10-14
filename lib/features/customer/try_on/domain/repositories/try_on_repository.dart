import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on_failure.dart';

/// The buyer's `/v1/try-on/*` surface. Every write takes the caller's
/// Idempotency-Key, minted once per tap.
abstract interface class TryOnRepository {
  Future<Either<TryOnFailure, TryOnAccess>> getAccess();

  Future<Either<TryOnFailure, TryOnAccess>> startTrial({
    required String idempotencyKey,
  });

  Future<Either<TryOnFailure, TryOnPaymentStart>> subscribe({
    required String planId,
    required TryOnPaymentRail rail,
    required String idempotencyKey,
  });

  Future<Either<TryOnFailure, MyTryOnSubscription>> confirmSubscription({
    required String subscriptionId,
    required String idempotencyKey,
  });

  Future<Either<TryOnFailure, List<MyTryOnSubscription>>> mySubscriptions();

  /// `Right(null)` when the buyer has not saved measurements yet (404).
  Future<Either<TryOnFailure, BodyMeasurements?>> getMeasurements();

  Future<Either<TryOnFailure, BodyMeasurements>> saveMeasurements(
    BodyMeasurements measurements, {
    required String idempotencyKey,
  });

  Future<Either<TryOnFailure, TryOnProduct>> getProduct(String productId);

  Future<Either<TryOnFailure, FitRecommendation>> getFit(String productId);

  Future<Either<TryOnFailure, Unit>> recordSession({
    required String productId,
    required TryOnMode mode,
    required String idempotencyKey,
    String? chosenSize,
  });

  /// Public `GET /v1/products/{id}/size-chart`; `Right(null)` on 404.
  Future<Either<TryOnFailure, SizeChart?>> getPublicSizeChart(String productId);
}
