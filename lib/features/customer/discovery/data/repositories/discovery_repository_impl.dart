import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/product_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  DiscoveryRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final DiscoveryRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, DiscoverData>> getDiscoverData() async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getDiscoverData();
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
  Future<Either<NetworkExceptions, ProductDetail>> getProductDetail(
    String productId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getProductDetail(productId);
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
  Future<Either<NetworkExceptions, PagedResult<ProductReviewPreview>>> getProductReviews(
    String productId, {
    int limit = 10,
    String? cursor,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getProductReviews(
          productId,
          limit: limit,
          cursor: cursor,
        );
        final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (e) =>
                  ProductReviewPreviewDto.fromJson(e as Map<String, dynamic>)
                      .toDomain(),
            )
            .toList(growable: false);
        return right(
          PagedResult<ProductReviewPreview>(
            items: items,
            totalCount: response['totalCount'] as int? ?? 0,
            pageSize: response['pageSize'] as int? ?? limit,
            nextCursor: response['nextCursor'] as String?,
            previousCursor: response['previousCursor'] as String?,
            hasMore: response['hasMore'] as bool? ?? false,
          ),
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

  @override
  Future<Either<NetworkExceptions, List<RelatedProduct>>> getRelatedProducts(
    String productId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getRelatedProducts(productId);
        return right(dtos.map((d) => d.toDomain()).toList(growable: false));
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
  Future<Either<NetworkExceptions, Unit>> addToCart({
    required String productId,
    required int qty,
    String? variantId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.addToCart(
          productId: productId,
          qty: qty,
          variantId: variantId,
          idempotencyKey: _uuid.v4(),
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
  Future<Either<NetworkExceptions, bool>> toggleSaved(String productId) async {
    if (await networkInfo.isConnected) {
      try {
        final isSaved = await remoteDataSource.toggleSaved(
          productId,
          _uuid.v4(),
        );
        return right(isSaved);
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
