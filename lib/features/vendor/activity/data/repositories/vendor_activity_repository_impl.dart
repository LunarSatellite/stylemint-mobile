import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/activity/data/datasources/vendor_activity_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/activity/domain/entities/vendor_activity_entry.dart';
import 'package:stylemint_mobile_frontend/features/vendor/activity/domain/repositories/vendor_activity_repository.dart';

class VendorActivityRepositoryImpl implements VendorActivityRepository {
  VendorActivityRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final VendorActivityRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, List<VendorActivityEntry>>> getActivity({
    int pageSize = 25,
    String? cursor,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final page = await remoteDataSource.getActivity(
          pageSize: pageSize,
          cursor: cursor,
        );
        return right(page.items.map((e) => e.toDomain()).toList(growable: false));
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
