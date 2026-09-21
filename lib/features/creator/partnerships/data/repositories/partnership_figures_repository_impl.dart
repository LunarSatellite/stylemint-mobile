import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/datasources/partnerships_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership_figures.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/repositories/partnership_figures_repository.dart';

class PartnershipFiguresRepositoryImpl implements PartnershipFiguresRepository {
  PartnershipFiguresRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final PartnershipsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, PartnershipAffiliateEarnings>>
  getAffiliateEarnings(String partnershipId) => _guard(() async {
    final dto = await remoteDataSource.getAffiliateEarnings(partnershipId);
    return dto.toDomain();
  });

  @override
  Future<Either<NetworkExceptions, PartnershipTagCounts>> getTagCounts(
    String partnershipId,
  ) => _guard(() async {
    final dto = await remoteDataSource.getTagCounts(partnershipId);
    return dto.toDomain();
  });

  /// Connectivity guard plus the typed-failure mapping every other
  /// partnership read uses. A failure is returned as a failure — there is no
  /// fallback value here, because every value this repository returns is a
  /// figure a creator would read as a fact.
  Future<Either<NetworkExceptions, T>> _guard<T>(
    Future<T> Function() read,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      return right(await read());
    } on DioException catch (e) {
      return left(mapDioExceptionToNetworkException(e));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}
