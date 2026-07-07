import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/data/datasources/vendor_earnings_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/data/models/vendor_earnings_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/entities/vendor_earnings.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/repositories/vendor_earnings_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';
import 'package:uuid/uuid.dart';

/// The backend's `PayeeKind.Vendor` wire value — `GET /v1/payouts` isn't
/// role-scoped server-side, so rows are filtered to this kind client-side.
const _vendorPayeeKind = 2;

class VendorEarningsRepositoryImpl implements VendorEarningsRepository {
  VendorEarningsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final VendorEarningsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, VendorEarningsSummary>>
  getEarningsSummary() async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getEarningsSummary();
        return right(dto.toDomain());
      } catch (e) {
        return left(_mapError(e));
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, VendorEarningsBalance>> getBalance() async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getBalance();
        return right(dto.toDomain());
      } catch (e) {
        return left(_mapError(e));
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, PagedResult<VendorEarningsLedger>>>
  getLedger({int pageSize = 20, String? cursor}) async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.getLedger(
          pageSize: pageSize,
          cursor: cursor,
        );
        final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (e) => VendorEarningsLedgerDto.fromJson(
                e as Map<String, dynamic>,
              ).toDomain(),
            )
            .toList(growable: false);
        return right(
          PagedResult(
            items: items,
            totalCount: data['totalCount'] as int? ?? items.length,
            pageSize: data['pageSize'] as int? ?? pageSize,
            nextCursor: data['nextCursor'] as String?,
            previousCursor: data['previousCursor'] as String?,
            hasMore: data['hasMore'] as bool? ?? false,
          ),
        );
      } catch (e) {
        return left(_mapError(e));
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, PagedResult<VendorPayout>>> getPayouts({
    int pageSize = 20,
    String? cursor,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.getPayouts(
          pageSize: pageSize,
          cursor: cursor,
        );
        final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (e) => VendorPayoutDto.fromJson(e as Map<String, dynamic>),
            )
            .where((dto) => dto.payeeKind == _vendorPayeeKind)
            .map((dto) => dto.toDomain())
            .toList(growable: false);
        return right(
          PagedResult(
            items: items,
            totalCount: data['totalCount'] as int? ?? items.length,
            pageSize: data['pageSize'] as int? ?? pageSize,
            nextCursor: data['nextCursor'] as String?,
            previousCursor: data['previousCursor'] as String?,
            hasMore: data['hasMore'] as bool? ?? false,
          ),
        );
      } catch (e) {
        return left(_mapError(e));
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, VendorPayoutInvoice>> getPayoutInvoice(
    String payoutId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getPayoutInvoice(payoutId);
        return right(dto.toDomain());
      } catch (e) {
        return left(_mapError(e));
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> requestPayout({
    required double amount,
    required int destinationKind,
    required String destinationId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.requestPayout(
          amount: amount,
          destinationKind: destinationKind,
          destinationId: destinationId,
          idempotencyKey: const Uuid().v4(),
        );
        return right(unit);
      } catch (e) {
        return left(_mapError(e));
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }

  NetworkExceptions _mapError(Object e) {
    if (e is DioException)
      return NetworkExceptions.server(e.message.toString());
    if (e is NetworkExceptions) return e;
    return const NetworkExceptions.unexpectedError();
  }
}
