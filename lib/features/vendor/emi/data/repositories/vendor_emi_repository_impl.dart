import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/repositories/emi_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/data/datasources/vendor_emi_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/entities/vendor_emi.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/repositories/vendor_emi_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:uuid/uuid.dart';

class VendorEmiRepositoryImpl implements VendorEmiRepository {
  VendorEmiRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final VendorEmiRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<EmiFailure, VendorEmiTerms>> getTerms(String productId) =>
      guardedEmiCall(networkInfo, () => remoteDataSource.getTerms(productId));

  @override
  Future<Either<EmiFailure, VendorEmiTerms>> saveTerms(
    String productId, {
    required bool enabled,
    required int minDownPaymentPercent,
    required List<int> tenures,
  }) => guardedEmiCall(
    networkInfo,
    () => remoteDataSource.putTerms(
      productId,
      enabled: enabled,
      minDownPaymentPercent: minDownPaymentPercent,
      tenures: tenures,
      idempotencyKey: _uuid.v4(),
    ),
  );

  @override
  Future<Either<EmiFailure, List<VendorEmiTerms>>> getEmiProducts() =>
      guardedEmiCall(networkInfo, remoteDataSource.getEmiProducts);

  @override
  Future<Either<EmiFailure, VendorEmiSettings>> getSettings() =>
      guardedEmiCall(networkInfo, remoteDataSource.getSettings);

  @override
  Future<Either<EmiFailure, VendorEmiSettings>> saveSettings(
    Money? exposureLimit,
  ) => guardedEmiCall(
    networkInfo,
    () => remoteDataSource.putSettings(exposureLimit),
  );
}
