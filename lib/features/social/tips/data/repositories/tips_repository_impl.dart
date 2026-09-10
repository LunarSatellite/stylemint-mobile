import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/data/datasources/tips_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/domain/entities/tip.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/domain/repositories/tips_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class TipsRepositoryImpl implements TipsRepository {
  TipsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final TipsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;
  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, Tip>> sendTip({
    required String creatorProfileId,
    required Money amount,
    required String paymentIntentId,
    String? reelId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.sendTip(
          creatorProfileId: creatorProfileId,
          amount: amount.amount,
          currency: amount.currency,
          paymentIntentId: paymentIntentId,
          reelId: reelId,
          idempotencyKey: _uuid.v4(),
        );
        return right(dto.toDomain());
      } catch (e) {
        return left(_mapException(e));
      }
    }
    return left(NetworkExceptions.noInternetConnection());
  }

  @override
  Future<Either<NetworkExceptions, List<Tip>>> getTipHistory({
    required String type,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getTipHistory(type: type);
        return right(
          dtos.map((dto) => dto.toDomain()).toList(growable: false),
        );
      } catch (e) {
        return left(_mapException(e));
      }
    }
    return left(NetworkExceptions.noInternetConnection());
  }

  @override
  Future<Either<NetworkExceptions, TipBalance>> getBalance() async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getBalance();
        return right(dto.toDomain());
      } catch (e) {
        return left(_mapException(e));
      }
    }
    return left(NetworkExceptions.noInternetConnection());
  }

  NetworkExceptions _mapException(Object e) {
    if (e is DioException) {
      return NetworkExceptions.server(e.message.toString());
    }
    if (e is NetworkExceptions) return e;
    return NetworkExceptions.unexpectedError();
  }
}
