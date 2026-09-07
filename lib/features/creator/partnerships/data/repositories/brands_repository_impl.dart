import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/datasources/brands_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_list_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/brand.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/repositories/brands_repository.dart';

class BrandsRepositoryImpl implements BrandsRepository {
  BrandsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final BrandsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, List<Brand>>> listBrands() =>
      _guard(() async {
        final dtos = await remoteDataSource.listBrands();
        return dtos.map((d) => d.toDomain()).toList(growable: false);
      });

  @override
  Future<Either<NetworkExceptions, List<Brand>>> listRecommendedBrands() =>
      _guard(() async {
        final dtos = await remoteDataSource.listRecommendedBrands();
        return dtos.map((d) => d.toDomain()).toList(growable: false);
      });

  Future<Either<NetworkExceptions, T>> _guard<T>(
    Future<T> Function() call,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      return right(await call());
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}
