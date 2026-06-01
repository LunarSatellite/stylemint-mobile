import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/data/datasources/earnings_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/data/models/earnings_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/repositories/earnings_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:uuid/uuid.dart';

class EarningsRepositoryImpl implements EarningsRepository {
  EarningsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final EarningsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, EarningsSummary>> getSummary() async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getSummary();
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
  Future<Either<NetworkExceptions, List<EarningsLedgerEntry>>> getLedger({
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
                      EarningsLedgerEntryDto.fromJson(
                        e as Map<String, dynamic>,
                      ),
                )
                .toList(growable: false);
        return right(
          items.map((dto) => dto.toDomain()).toList(growable: false),
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
  Future<Either<NetworkExceptions, List<PayoutMethod>>> getPayoutMethods() async {
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
  Future<Either<NetworkExceptions, Unit>> requestPayout({
    required Money amount,
    required String payoutMethodId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.requestPayout(
          amount: amount.amount,
          currency: amount.currency,
          payoutMethodId: payoutMethodId,
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

  @override
  Future<Either<NetworkExceptions, Unit>> addPayoutMethod({
    required PayoutMethodType type,
    required String label,
    required Map<String, String> details,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.addPayoutMethod(
          type: type.name,
          label: label,
          details: details,
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
