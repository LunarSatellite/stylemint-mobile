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
  Future<Either<NetworkExceptions, List<TrendingProduct>>> getCategoryProducts(
    String categoryId,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }

    try {
      final products = await remoteDataSource.getCategoryProducts(categoryId);
      return right(products.map((product) => product.toDomain()).toList());
    } catch (e) {
      if (e is DioException) {
        return left(NetworkExceptions.server(e.message.toString()));
      }
      if (e is NetworkExceptions) return left(e);
      return left(NetworkExceptions.unexpectedError());
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
  Future<Either<NetworkExceptions, ProductUrgency>> getProductUrgency(
    String productId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final json = await remoteDataSource.getProductUrgency(productId);
        return right(ProductUrgency(
          stockRemaining: json['stockRemaining'] as int? ?? 0,
          viewersRightNow: json['viewersRightNow'] as int? ?? 0,
          cartAddsLast10Min: json['cartAddsLast10Min'] as int? ?? 0,
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
  Future<Either<NetworkExceptions, List<ProductFaqEntry>>> getProductFaq(
    String productId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final json = await remoteDataSource.getProductSeoContent(productId);
        final faq = (json['faq'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>()
            .map((e) => ProductFaqEntry(
                  question: e['question'] as String? ?? '',
                  answer: e['answer'] as String? ?? '',
                ))
            .where((f) => f.question.isNotEmpty && f.answer.isNotEmpty)
            .toList(growable: false);
        return right(faq);
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
  Future<Either<NetworkExceptions, ProductComparison>> getProductComparison(
    String productId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final json = await remoteDataSource.getProductComparison(productId);
        final alternatives = (json['alternatives'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>()
            .map((e) => ProductComparisonPoint(
                  productId: e['productId'] as String? ?? '',
                  productName: e['productName'] as String? ?? '',
                  howItDiffers: e['howItDiffers'] as String? ?? '',
                ))
            .where((p) => p.productId.isNotEmpty)
            .toList(growable: false);
        return right(ProductComparison(
          bestForTag: json['bestForTag'] as String? ?? '',
          alternatives: alternatives,
          recommendation: json['recommendation'] as String? ?? '',
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
  Future<Either<NetworkExceptions, ProductPassport>> getProductPassport(
    String productId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final json = await remoteDataSource.getProductPassport(productId);
        return right(ProductPassport(
          vendorBusinessName: json['vendorBusinessName'] as String? ?? '',
          vendorIdentityVerified: json['vendorIdentityVerified'] as bool? ?? false,
          vendorOnPlatformSince: json['vendorOnPlatformSinceUtc'] != null
              ? DateTime.tryParse(json['vendorOnPlatformSinceUtc'] as String)
              : null,
          authenticityStatement: json['authenticityStatement'] as String? ?? '',
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
  Future<Either<NetworkExceptions, MissionShoppingPlan>> getMissionShoppingPlan({
    required String missionText,
    double? budgetAmount,
    int maxItems = 5,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final json = await remoteDataSource.getMissionShoppingPlan(
          missionText: missionText,
          budgetAmount: budgetAmount,
          maxItems: maxItems,
        );
        final items = (json['items'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>()
            .map((e) => MissionShoppingItem(
                  productId: e['productId'] as String? ?? '',
                  name: e['name'] as String? ?? '',
                  thumbnailUrl: e['thumbnailUrl'] as String?,
                  priceAmount: (e['priceAmount'] as num?)?.toDouble() ?? 0,
                  reason: e['reason'] as String? ?? '',
                ))
            .where((i) => i.productId.isNotEmpty)
            .toList(growable: false);
        return right(MissionShoppingPlan(
          missionSummary: json['missionSummary'] as String? ?? '',
          items: items,
          totalEstimatedCost: (json['totalEstimatedCost'] as num?)?.toDouble() ?? 0,
          currency: json['currency'] as String? ?? 'NPR',
          budgetAmount: (json['budgetAmount'] as num?)?.toDouble(),
          withinBudget: json['withinBudget'] as bool? ?? true,
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
  Future<Either<NetworkExceptions, PagedResult<ProductReviewPreview>>>
  getProductReviews(
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
              (e) => ProductReviewPreviewDto.fromJson(
                e as Map<String, dynamic>,
              ).toDomain(),
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
  Future<Either<NetworkExceptions, bool>> toggleSaved(
    String productId, {
    String? variantId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final isSaved = await remoteDataSource.toggleSaved(
          productId,
          variantId,
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
