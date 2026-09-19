import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/settings/data/datasources/memory_vault_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/companion_memory.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/repositories/memory_vault_repository.dart';

class MemoryVaultRepositoryImpl implements MemoryVaultRepository {
  MemoryVaultRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final MemoryVaultRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, MemoryVault>> load() =>
      _call(remoteDataSource.load);

  @override
  Future<Either<NetworkExceptions, CompanionMemory>> correct(
    String memoryId,
    String content,
  ) => _call(() => remoteDataSource.correct(memoryId, content));

  @override
  Future<Either<NetworkExceptions, Unit>> forget(String memoryId) =>
      _call(() async {
        await remoteDataSource.forget(memoryId);
        return unit;
      });

  @override
  Future<Either<NetworkExceptions, Unit>> forgetAll() => _call(() async {
    await remoteDataSource.forgetAll();
    return unit;
  });

  @override
  Future<Either<NetworkExceptions, Unit>> setPaused({required bool paused}) =>
      _call(() async {
        await remoteDataSource.setPaused(paused: paused);
        return unit;
      });

  @override
  Future<Either<NetworkExceptions, String>> export() =>
      _call(remoteDataSource.export);

  @override
  Future<Either<NetworkExceptions, int>> importPortableTwin(
    String bundleJson,
  ) => _call(() async {
    final result = await remoteDataSource.importPortableTwin(bundleJson);
    return result['imported'] as int? ?? 0;
  });

  Future<Either<NetworkExceptions, T>> _call<T>(
    Future<T> Function() body,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      return right(await body());
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message.toString()));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object {
      return left(NetworkExceptions.unexpectedError());
    }
  }
}
