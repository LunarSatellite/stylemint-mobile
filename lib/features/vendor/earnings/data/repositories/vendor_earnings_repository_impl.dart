import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/data/datasources/vendor_earnings_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/data/models/vendor_earnings_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/entities/vendor_earnings.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/repositories/vendor_earnings_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';
import 'package:uuid/uuid.dart';

class VendorEarningsRepositoryImpl implements VendorEarningsRepository {
  VendorEarningsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final VendorEarningsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, VendorEarningsSummary>> getEarningsSummary() async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getEarningsSummary();
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
  Future<Either<NetworkExceptions, PagedResult<VendorEarningsLedger>>> getLedger({
    int limit = 20,
    String? cursor,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getLedger(
          limit: limit,
          cursor: cursor,
        );
        final items =
            (response['items'] as List<dynamic>? ?? const <dynamic>[])
                .map(
                  (e) =>
                      VendorEarningsLedgerDto.fromJson(
                        e as Map<String, dynamic>,
                      ),
                )
                .toList(growable: false);
        return right(
          PagedResult(
            items: items.map((dto) => dto.toDomain()).toList(growable: false),
            totalCount: response['totalCount'] as int? ?? items.length,
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
  Future<Either<NetworkExceptions, List<VendorPayoutMethod>>> getPayoutMethods() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getPayoutMethods();
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
  Future<Either<NetworkExceptions, VendorPayoutMethod>> addPayoutMethod({
    required VendorPayoutMethodType type,
    required String label,
    required String accountInfo,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.addPayoutMethod(
          type: type.name,
          label: label,
          accountInfo: accountInfo,
          idempotencyKey: const Uuid().v4(),
        );
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
  Future<Either<NetworkExceptions, Unit>> requestPayout({
    required Money amount,
    required String methodId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.requestPayout(
          amount: amount.amount,
          currency: amount.currency,
          methodId: methodId,
          idempotencyKey: const Uuid().v4(),
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
}
