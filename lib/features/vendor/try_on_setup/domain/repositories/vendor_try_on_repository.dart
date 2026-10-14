import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/domain/entities/vendor_try_on.dart';

/// `/v1/vendor/products/{id}/size-chart|try-on-image|try-on`.
abstract interface class VendorTryOnRepository {
  /// `Right(null)` when the product has no chart yet.
  Future<Either<TryOnFailure, SizeChart?>> getSizeChart(String productId);

  Future<Either<TryOnFailure, SizeChart>> saveSizeChart(
    String productId,
    SizeChart chart, {
    required String idempotencyKey,
  });

  Future<Either<TryOnFailure, Unit>> deleteSizeChart(
    String productId, {
    required String idempotencyKey,
  });

  Future<Either<TryOnFailure, TryOnImage>> uploadTryOnImage(
    String productId,
    String filePath, {
    required String idempotencyKey,
    void Function(double progress)? onProgress,
  });

  Future<Either<TryOnFailure, Unit>> deleteTryOnImage(
    String productId, {
    required String idempotencyKey,
  });

  Future<Either<TryOnFailure, TryOnReadiness>> getReadiness(String productId);
}
