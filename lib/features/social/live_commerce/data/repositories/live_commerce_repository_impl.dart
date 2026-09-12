import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/data/datasources/live_commerce_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/domain/entities/live_session.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/domain/repositories/live_commerce_repository.dart';

class LiveCommerceRepositoryImpl implements LiveCommerceRepository {
  LiveCommerceRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final LiveCommerceRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, List<LiveSession>>> getLive() =>
      _call(() async {
        final dtos = await remoteDataSource.getLive();
        return dtos.map((d) => d.toDomain()).toList(growable: false);
      });

  @override
  Future<Either<NetworkExceptions, List<LiveSession>>> getUpcoming() =>
      _call(() async {
        final dtos = await remoteDataSource.getUpcoming();
        return dtos.map((d) => d.toDomain()).toList(growable: false);
      });

  @override
  Future<Either<NetworkExceptions, LiveSession>> getById(String id) =>
      _call(() async => (await remoteDataSource.getById(id)).toDomain());

  Future<Either<NetworkExceptions, T>> _call<T>(Future<T> Function() body) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      return right(await body());
    } catch (e) {
      if (e is DioException) {
        return left(NetworkExceptions.server(e.message.toString()));
      } else if (e is NetworkExceptions) {
        return left(e);
      } else {
        return left(NetworkExceptions.unexpectedError());
      }
    }
  }
}
