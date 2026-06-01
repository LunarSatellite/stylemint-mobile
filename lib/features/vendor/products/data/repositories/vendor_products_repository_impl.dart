import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/data/datasources/vendor_products_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/data/models/vendor_product_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/repositories/vendor_products_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

class VendorProductsRepositoryImpl implements VendorProductsRepository {
  VendorProductsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final VendorProductsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, PagedResult<VendorProduct>>> getProducts({
    int limit = 20,
    String? cursor,
    String? status,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.getProducts(
          limit: limit,
          cursor: cursor,
          status: status,
        );
        final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => VendorProductDto.fromJson(e as Map<String, dynamic>).toDomain())
            .toList(growable: false);
        return right(PagedResult(
          items: items,
          totalCount: data['totalCount'] as int? ?? items.length,
          pageSize: data['pageSize'] as int? ?? limit,
          nextCursor: data['nextCursor'] as String?,
          previousCursor: data['previousCursor'] as String?,
          hasMore: data['hasMore'] as bool? ?? false,
        ));
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

  @override
  Future<Either<NetworkExceptions, VendorProduct>> getProduct(String productId) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getProduct(productId);
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

  @override
  Future<Either<NetworkExceptions, Unit>> updateProductStatus(
    String productId,
    VendorProductStatus status,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateProductStatus(
          productId,
          status.name,
          _uuid.v4(),
        );
        return right(unit);
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

  @override
  Future<Either<NetworkExceptions, Unit>> deleteProduct(String productId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteProduct(productId, _uuid.v4());
        return right(unit);
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
