import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/data/datasources/creator_dashboard_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/domain/entities/creator_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/domain/repositories/creator_dashboard_repository.dart';

class CreatorDashboardRepositoryImpl implements CreatorDashboardRepository {
  CreatorDashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CreatorDashboardRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, CreatorDashboard>> getDashboard() async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getDashboard();
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
