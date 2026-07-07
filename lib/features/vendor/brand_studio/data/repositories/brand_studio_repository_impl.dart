import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/data/datasources/brand_studio_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/domain/entities/brand_studio.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/domain/repositories/brand_studio_repository.dart';

class BrandStudioRepositoryImpl implements BrandStudioRepository {
  BrandStudioRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final BrandStudioRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, BrandStudioInsights>> getInsights({
    int? windowDays,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getInsights(
          windowDays: windowDays,
        );
        return right(dto.toDomain());
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }
}
