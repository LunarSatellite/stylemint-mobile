import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/data/datasources/creator_performance_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/domain/entities/creator_performance.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/domain/repositories/creator_performance_repository.dart';

class CreatorPerformanceRepositoryImpl implements CreatorPerformanceRepository {
  CreatorPerformanceRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CreatorPerformanceRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, List<CreatorPerformance>>>
      getCreatorPerformance({
    String? sortBy,
    String? window,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getCreatorPerformance(
          sortBy: sortBy,
          window: window,
        );
        return right(dtos.map((d) => d.toDomain()).toList());
      } on DioException catch (e) {
        return left(NetworkExceptions.server(e.message.toString()));
      } on NetworkExceptions catch (e) {
        return left(e);
      } on Object catch (_) {
        return left(const NetworkExceptions.unexpectedError());
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }
}
