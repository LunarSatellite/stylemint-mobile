import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/product_delivery_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/product_option_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/product_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/regret_check.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
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
        final json = await remoteDataSource.getProductDetailJson(productId);
        final options = ProductOptionsDto.fromJson(json);
        return right(
          ProductDetailDto.fromJson(json).toDomain().copyWith(
            delivery: ProductDeliveryDto.fromJson(json),
            options: options.options,
            optionVariants: options.variants,
            // Real options replace the synthetic "pick a SKU" chip row.
            variants: options.isEmpty ? null : const <ProductVariant>[],
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
  Future<Either<NetworkExceptions, ProductUrgency>> getProductUrgency(
    String productId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final json = await remoteDataSource.getProductUrgency(productId);
        // Nothing is defaulted at the parse boundary. An absent field stays
        // absent all the way to the widget, because `?? 0` here is exactly
        // how a "not measured" becomes a "zero bought" on screen.
        final saleAmount = (json['flashSalePrice'] as num?)?.toDouble();
        final saleCurrency = json['flashSaleCurrency'] as String?;
        final endsAt = json['flashSaleEndsAt'] as String?;
        return right(
          ProductUrgency(
            isInStock: json['isInStock'] as bool?,
            isLowStock: json['isLowStock'] as bool?,
            viewersRightNow: json['viewersRightNow'] as int?,
            flashSaleEndsAt: endsAt == null ? null : DateTime.tryParse(endsAt),
            // Both halves or neither: a bare amount has no currency to be
            // formatted in, and guessing one is how a price starts lying.
            flashSalePrice: saleAmount != null && saleCurrency != null
                ? Money(amount: saleAmount, currency: saleCurrency)
                : null,
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
  Future<Either<NetworkExceptions, Map<String, ProductSocialProof>>>
  getSocialProof(List<String> productIds) async {
    if (productIds.isEmpty) {
      return right(const <String, ProductSocialProof>{});
    }
    if (await networkInfo.isConnected) {
      try {
        final json = await remoteDataSource.getSocialProof(productIds);
        return right({
          for (final entry in json.entries)
            if (entry.value case final Map<String, dynamic> proof)
              entry.key: ProductSocialProof(
                reviewCount: proof['reviewCount'] as int? ?? 0,
                // No `?? 0` on any of these three. Absent stays absent.
                unitsSoldLast30Days: proof['unitsSoldLast30Days'] as int?,
                viewersRightNow: proof['viewersRightNow'] as int?,
                averageRating: (proof['averageRating'] as num?)?.toDouble(),
              ),
        });
      } on DioException catch (e) {
        return left(NetworkExceptions.server(e.message.toString()));
      } on NetworkExceptions catch (e) {
        return left(e);
      } on Object {
        return left(const NetworkExceptions.unexpectedError());
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
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
            .map(
              (e) => ProductFaqEntry(
                question: e['question'] as String? ?? '',
                answer: e['answer'] as String? ?? '',
              ),
            )
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
  Future<Either<NetworkExceptions, ProductComparison?>> getProductComparison(
    String productId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final json = await remoteDataSource.getProductComparison(productId);
        // 204: the endpoint had nothing truthful to say. A successful "there
        // is no comparison" — right(null), not an error.
        if (json == null) return right(null);
        final alternatives =
            (json['alternatives'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .map(
                  (e) => ProductComparisonPoint(
                    productId: e['productId'] as String? ?? '',
                    productName: e['productName'] as String? ?? '',
                    // Absent stays absent: blanking it to '' would render an
                    // empty span after the product name.
                    howItDiffers: _nonEmpty(e['howItDiffers']),
                  ),
                )
                .where((p) => p.productId.isNotEmpty)
                .toList(growable: false);
        return right(
          ProductComparison(
            bestForTag: _nonEmpty(json['bestForTag']),
            alternatives: alternatives,
            recommendation: _nonEmpty(json['recommendation']),
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
  Future<Either<NetworkExceptions, ProductPassport>> getProductPassport(
    String productId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final json = await remoteDataSource.getProductPassport(productId);
        return right(
          ProductPassport(
            vendorBusinessName: json['vendorBusinessName'] as String? ?? '',
            vendorIdentityVerified:
                json['vendorIdentityVerified'] as bool? ?? false,
            vendorOnPlatformSince: json['vendorOnPlatformSinceUtc'] != null
                ? DateTime.tryParse(json['vendorOnPlatformSinceUtc'] as String)
                : null,
            authenticityStatement:
                json['authenticityStatement'] as String? ?? '',
            schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
            revision: json['revision'] as String? ?? '',
            generatedAt: DateTime.tryParse(
              json['generatedUtc'] as String? ?? '',
            ),
            provenance: (json['provenance'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(
                  (fact) => ProductProvenanceFact(
                    key: fact['key'] as String? ?? '',
                    label: fact['label'] as String? ?? '',
                    value: fact['value'] as String? ?? '',
                    verified: fact['verified'] as bool? ?? false,
                    observedAt: DateTime.tryParse(
                      fact['observedUtc'] as String? ?? '',
                    ),
                  ),
                )
                .where((fact) => fact.label.isNotEmpty && fact.value.isNotEmpty)
                .toList(growable: false),
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
  Future<Either<NetworkExceptions, RegretCheck>> getRegretCheck(
    String productId,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dto = await remoteDataSource.getRegretCheck(productId);
      return right(dto.toDomain());
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (e) {
      // 404 -> notFound, 5xx -> serverUnavailable, bad payload -> unexpected.
      return left(mapDioExceptionToNetworkException(e));
    }
  }

  @override
  Future<Either<NetworkExceptions, MissionShoppingPlan>>
  getMissionShoppingPlan({
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
            .map(
              (e) => MissionShoppingItem(
                productId: e['productId'] as String? ?? '',
                name: e['name'] as String? ?? '',
                thumbnailUrl: e['thumbnailUrl'] as String?,
                priceAmount: (e['priceAmount'] as num?)?.toDouble() ?? 0,
                reason: e['reason'] as String? ?? '',
              ),
            )
            .where((i) => i.productId.isNotEmpty)
            .toList(growable: false);
        return right(
          MissionShoppingPlan(
            missionSummary: json['missionSummary'] as String? ?? '',
            items: items,
            totalEstimatedCost:
                (json['totalEstimatedCost'] as num?)?.toDouble() ?? 0,
            currency: json['currency'] as String? ?? 'NPR',
            budgetAmount: (json['budgetAmount'] as num?)?.toDouble(),
            withinBudget: json['withinBudget'] as bool? ?? true,
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

/// Reads an optional string field the way the comparison contract means it:
/// absent, null, or blank all mean "the platform has nothing true to say
/// here", and all become null so the UI can omit the element entirely
/// instead of rendering a label with nothing after it.
String? _nonEmpty(Object? raw) {
  final value = raw is String ? raw.trim() : null;
  return (value == null || value.isEmpty) ? null : value;
}
