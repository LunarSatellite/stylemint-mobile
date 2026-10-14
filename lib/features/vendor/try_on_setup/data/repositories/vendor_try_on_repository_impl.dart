import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/data/try_on_failure_mapper.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/data/datasources/vendor_try_on_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/domain/entities/vendor_try_on.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/domain/repositories/vendor_try_on_repository.dart';

class VendorTryOnRepositoryImpl implements VendorTryOnRepository {
  VendorTryOnRepositoryImpl({required this.remote, required this.networkInfo});

  final VendorTryOnRemoteDataSource remote;
  final NetworkInfoConnectivity networkInfo;

  Future<Either<TryOnFailure, T>> _call<T>(Future<T> Function() call) =>
      guardedTryOnCall(networkInfo, call);

  @override
  Future<Either<TryOnFailure, SizeChart?>> getSizeChart(
    String productId,
  ) async {
    final result = await _call(() => remote.getSizeChart(productId));
    return result.fold(
      (f) => f.isNotFound ? right(null) : left(f),
      right,
    );
  }

  @override
  Future<Either<TryOnFailure, SizeChart>> saveSizeChart(
    String productId,
    SizeChart chart, {
    required String idempotencyKey,
  }) => _call(() => remote.putSizeChart(productId, chart, idempotencyKey));

  @override
  Future<Either<TryOnFailure, Unit>> deleteSizeChart(
    String productId, {
    required String idempotencyKey,
  }) => _call(() async {
    await remote.deleteSizeChart(productId, idempotencyKey);
    return unit;
  });

  @override
  Future<Either<TryOnFailure, TryOnImage>> uploadTryOnImage(
    String productId,
    String filePath, {
    required String idempotencyKey,
    void Function(double progress)? onProgress,
  }) => _call(
    () => remote.uploadImage(
      productId,
      filePath,
      idempotencyKey,
      onProgress: onProgress,
    ),
  );

  @override
  Future<Either<TryOnFailure, Unit>> deleteTryOnImage(
    String productId, {
    required String idempotencyKey,
  }) => _call(() async {
    await remote.deleteImage(productId, idempotencyKey);
    return unit;
  });

  @override
  Future<Either<TryOnFailure, TryOnReadiness>> getReadiness(
    String productId,
  ) => _call(() => remote.getReadiness(productId));
}
