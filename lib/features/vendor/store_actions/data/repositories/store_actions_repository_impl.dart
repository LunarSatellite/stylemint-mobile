import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/data/datasources/store_actions_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/domain/entities/store_actions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/domain/repositories/store_actions_repository.dart';

class StoreActionsRepositoryImpl implements StoreActionsRepository {
  StoreActionsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final StoreActionsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, StoreActionQueue>> getStoreActions() async {
    try {
      if (!await networkInfo.isConnected) {
        return left(const NetworkExceptions.noInternetConnection());
      }
      final dto = await remoteDataSource.getStoreActions();
      return right(dto.toDomain());
    } on DioException catch (e) {
      // 404 -> notFound, 5xx -> serverUnavailable, timeouts -> no internet.
      return left(mapDioExceptionToNetworkException(e));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}
