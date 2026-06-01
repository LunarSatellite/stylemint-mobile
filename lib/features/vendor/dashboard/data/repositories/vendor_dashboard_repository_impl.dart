import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/data/datasources/vendor_dashboard_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/domain/entities/vendor_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/domain/repositories/vendor_dashboard_repository.dart';

class VendorDashboardRepositoryImpl implements VendorDashboardRepository {
  VendorDashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final VendorDashboardRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, VendorDashboard>> getDashboard() async {
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
