import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/datasources/reel_import_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/tag_product_commission.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/repositories/tag_product_commission_repository.dart';

class TagProductCommissionRepositoryImpl
    implements TagProductCommissionRepository {
  TagProductCommissionRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ReelImportRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, Map<String, TagProductCommission>>>
  getCommissions(List<String> productIds) async {
    if (productIds.isEmpty) {
      return right(const <String, TagProductCommission>{});
    }
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dtos = await remoteDataSource.getTagProductCommissions(productIds);
      return right(<String, TagProductCommission>{
        for (final dto in dtos)
          if (dto.productId.isNotEmpty) dto.productId: dto.toDomain(),
      });
    } on DioException catch (e) {
      return left(mapDioExceptionToNetworkException(e));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}
