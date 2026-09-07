import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/activity/data/datasources/creator_activity_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/activity/domain/entities/creator_activity_entry.dart';
import 'package:stylemint_mobile_frontend/features/creator/activity/domain/repositories/creator_activity_repository.dart';

class CreatorActivityRepositoryImpl implements CreatorActivityRepository {
  CreatorActivityRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CreatorActivityRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, List<CreatorActivityEntry>>> getActivity({
    int pageSize = 25,
    String? cursor,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final page = await remoteDataSource.getActivity(
          pageSize: pageSize,
          cursor: cursor,
        );
        return right(
          page.items.map((e) => e.toDomain()).toList(growable: false),
        );
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
