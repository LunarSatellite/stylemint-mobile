import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/data/datasources/reach_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/domain/entities/reach.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/domain/repositories/reach_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:uuid/uuid.dart';

class ReachRepositoryImpl implements ReachRepository {
  ReachRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ReachRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, List<PublishTarget>>> getPublishTargets() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getPublishTargets();
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
  Future<Either<NetworkExceptions, Unit>> schedulePublish({
    required String draftId,
    required List<String> platformNames,
    required DateTime scheduledAt,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.schedulePublish(
          draftId: draftId,
          platformNames: platformNames,
          scheduledAt: scheduledAt,
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
  Future<Either<NetworkExceptions, List<BoostCampaign>>> getBoostCampaigns() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getBoostCampaigns();
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
  Future<Either<NetworkExceptions, BoostCampaign>> createBoostCampaign({
    required String reelId,
    required String platform,
    required Money budget,
    required int durationDays,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.createBoostCampaign(
          reelId: reelId,
          platform: platform,
          budgetAmount: budget.amount,
          budgetCurrency: budget.currency,
          durationDays: durationDays,
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
  Future<Either<NetworkExceptions, ReachAnalytics>> getAnalytics({
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getAnalytics(
          periodStart: periodStart,
          periodEnd: periodEnd,
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
}
