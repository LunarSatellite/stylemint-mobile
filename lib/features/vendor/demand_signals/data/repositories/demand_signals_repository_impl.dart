import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/data/datasources/demand_signals_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/domain/entities/demand_signals.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/domain/repositories/demand_signals_repository.dart';

class DemandSignalsRepositoryImpl implements DemandSignalsRepository {
  DemandSignalsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final DemandSignalsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, DemandSignals>> getDemandSignals({
    required int days,
    required int limit,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getDemandSignals(
          days: days,
          limit: limit,
        );
        return right(dto.toDomain());
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
