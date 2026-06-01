import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/data/datasources/matchmaking_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/data/models/matchmaking_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/domain/entities/matchmaking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:uuid/uuid.dart';

class MatchmakingRepositoryImpl implements MatchmakingRepository {
  MatchmakingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final MatchmakingRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, List<MatchRecommendation>>> getRecommendations({
    MatchmakingFilter? filters,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final params = filters != null
            ? MatchmakingFilterDto(
                categories: filters.categories,
                minFollowers: filters.minFollowers,
                maxFollowers: filters.maxFollowers,
                minEngagementRate: filters.minEngagementRate,
                budgetRange: filters.budgetRange,
              ).toQueryParams()
            : null;
        final dtos = await remoteDataSource.getRecommendations(
          queryParams: params,
        );
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
  Future<Either<NetworkExceptions, int>> getCompatibilityScore(String creatorId) async {
    if (await networkInfo.isConnected) {
      try {
        final score = await remoteDataSource.getCompatibilityScore(creatorId);
        return right(score);
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
  Future<Either<NetworkExceptions, Unit>> inviteToCampaign(
    String campaignId,
    String creatorId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.inviteToCampaign(
          campaignId: campaignId,
          creatorId: creatorId,
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
