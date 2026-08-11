import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/data/datasources/creator_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/domain/entities/creator_search_result.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/domain/repositories/creator_search_repository.dart';

class CreatorSearchRepositoryImpl implements CreatorSearchRepository {
  CreatorSearchRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CreatorSearchRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<NetworkEither<List<SearchBrandResult>>> searchBrands(String query) =>
      _guard(() async {
        final dtos = await remoteDataSource.searchBrands(query);
        return dtos.map((d) => d.toDomain()).toList(growable: false);
      });

  @override
  Future<NetworkEither<List<SearchProductResult>>> searchProducts(
    String query,
  ) =>
      _guard(() async {
        final dtos = await remoteDataSource.searchProducts(query);
        return dtos.map((d) => d.toDomain()).toList(growable: false);
      });

  @override
  Future<NetworkEither<List<SearchCreatorResult>>> searchCreators(
    String query,
  ) =>
      _guard(() async {
        final dtos = await remoteDataSource.searchCreators(query);
        return dtos.map((d) => d.toDomain()).toList(growable: false);
      });

  /// All three searches hit the same endpoint with the same failure modes, so
  /// the connectivity check and exception mapping live in one place.
  Future<NetworkEither<T>> _guard<T>(Future<T> Function() call) async {
    if (!await networkInfo.isConnected) {
      return networkLeft<T>(const NetworkExceptions.noInternetConnection());
    }
    try {
      return networkRight<T>(await call());
    } on DioException catch (e) {
      return networkLeft<T>(
        NetworkExceptions.server(e.message ?? 'Server error'),
      );
    } on NetworkExceptions catch (e) {
      return networkLeft<T>(e);
    } on Exception {
      return networkLeft<T>(const NetworkExceptions.unexpectedError());
    }
  }
}
