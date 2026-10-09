import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/datasources/emi_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/emi_failure_mapper.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_eligibility.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_quote.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/repositories/emi_repository.dart';

/// Runs [call], answering offline without touching the network and mapping
/// anything thrown through [mapEmiFailure]. Shared by the EMI, KYC and vendor
/// EMI repositories.
Future<Either<EmiFailure, T>> guardedEmiCall<T>(
  NetworkInfoConnectivity networkInfo,
  Future<T> Function() call,
) async {
  try {
    if (!await networkInfo.isConnected) {
      return left(const EmiFailure(EmiFailureKind.offline));
    }
    return right(await call());
  } on Object catch (error) {
    return left(mapEmiFailure(error));
  }
}

class EmiRepositoryImpl implements EmiRepository {
  EmiRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final EmiRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<EmiFailure, EmiQuote>> getQuote({
    required String variantId,
    required int downPaymentPercent,
    required int tenureMonths,
  }) => guardedEmiCall(
    networkInfo,
    () => remoteDataSource.getQuote(
      variantId: variantId,
      downPaymentPercent: downPaymentPercent,
      tenureMonths: tenureMonths,
    ),
  );

  @override
  Future<Either<EmiFailure, EmiEligibility>> getEligibility() =>
      guardedEmiCall(networkInfo, remoteDataSource.getEligibility);
}
