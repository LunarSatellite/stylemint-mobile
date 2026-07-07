import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/data/datasources/matchmaking_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/data/models/matchmaking_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/domain/entities/matchmaking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';
import 'package:uuid/uuid.dart';

class MatchmakingRepositoryImpl implements MatchmakingRepository {
  MatchmakingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final MatchmakingRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, PagedResult<MatchRecommendation>>>
  getRecommendations({required int pageSize, String? cursor}) async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.getRecommendations(
          pageSize: pageSize,
          cursor: cursor,
        );
        final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (e) => MatchRecommendationDto.fromJson(
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
      } on Object catch (e) {
        return left(_mapError(e));
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, PartnershipPrefill>> invite(
    String matchId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.invite(
          matchId: matchId,
          idempotencyKey: _uuid.v4(),
        );
        return right(PartnershipPrefillDto.fromJson(data).toDomain());
      } on Object catch (e) {
        return left(_mapError(e));
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> dismissMatch(String matchId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.dismiss(
          matchId: matchId,
          idempotencyKey: _uuid.v4(),
        );
        return right(unit);
      } on Object catch (e) {
        return left(_mapError(e));
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }

  NetworkExceptions _mapError(Object e) {
    if (e is DioException) {
      return NetworkExceptions.server(e.message.toString());
    }
    if (e is NetworkExceptions) return e;
    return const NetworkExceptions.unexpectedError();
  }
}
