import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/data/datasources/sponsored_products_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/entities/sponsored_listing.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/repositories/sponsored_products_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/sponsored_products_errors.dart';
import 'package:uuid/uuid.dart';

class SponsoredProductsRepositoryImpl implements SponsoredProductsRepository {
  SponsoredProductsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final SponsoredProductsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, List<SponsoredListing>>>
  getSponsoredListings() => _call(
    () async => (await remoteDataSource.getSponsoredListings())
        .map((dto) => dto.toDomain())
        .toList(growable: false),
  );

  @override
  Future<Either<NetworkExceptions, SponsoredListing>> sponsor({
    required String productId,
    required int dailyImpressionCap,
    DateTime? endsUtc,
  }) => _call(
    () async => (await remoteDataSource.sponsor(
      productId: productId,
      dailyImpressionCap: dailyImpressionCap,
      endsUtc: endsUtc,
      // A fresh key per Save tap, so a retry after a failure is a new try.
      idempotencyKey: _uuid.v4(),
    )).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, SponsoredListing>> pause(
    String productId,
  ) => _call(
    () async => (await remoteDataSource.pause(
      productId: productId,
      idempotencyKey: _uuid.v4(),
    )).toDomain(),
  );

  Future<Either<NetworkExceptions, T>> _call<T>(
    Future<T> Function() call,
  ) async {
    try {
      if (!await networkInfo.isConnected) {
        return left(const NetworkExceptions.noInternetConnection());
      }
      return right(await call());
    } on DioException catch (e) {
      return left(mapSponsoredProductsDioError(e));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}

/// The shared mapper turns a 409 into an ordinary validation error, which
/// would make a lost race look like a form mistake. A 409 here (someone else
/// started sponsoring the product first) keeps the backend's sentence but
/// gets its own code, so the list knows to re-check itself. 400s keep the
/// backend's message and field; 404 stays `notFound`.
NetworkExceptions mapSponsoredProductsDioError(DioException e) {
  final response = e.response;
  if (response?.statusCode == 409) {
    final body = response!.data;
    final title = body is Map && body['title'] is String
        ? (body['title'] as String).trim()
        : '';
    return NetworkExceptions.validation(
      code: sponsorshipConflictCode,
      message: title.isEmpty ? sponsorshipConflictFallbackMessage : title,
    );
  }
  return mapDioExceptionToNetworkException(e);
}
