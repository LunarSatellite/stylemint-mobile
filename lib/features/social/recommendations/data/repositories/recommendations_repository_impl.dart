import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/data/datasources/recommendations_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/domain/entities/recommendation.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/domain/repositories/recommendations_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';
import 'package:uuid/uuid.dart';

class RecommendationsRepositoryImpl implements RecommendationsRepository {
  RecommendationsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final RecommendationsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, PagedResult<RecommendationRequest>>> getRequests({
    int limit = 20,
    String? cursor,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getRequests(limit: limit, cursor: cursor);
        return right(
          PagedResult(
            items: dto.items.map((d) => d.toDomain()).toList(growable: false),
            totalCount: dto.totalCount,
            pageSize: dto.pageSize,
            nextCursor: dto.nextCursor,
            previousCursor: dto.previousCursor,
            hasMore: dto.hasMore,
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
  Future<Either<NetworkExceptions, List<RecommendationReply>>> getThread(
    String requestId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getThread(requestId);
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
  Future<Either<NetworkExceptions, RecommendationRequest>> createRequest({
    required String question,
    String? context,
    List<String>? taggedProducts,
    List<String>? categories,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.createRequest(
          question: question,
          context: context,
          taggedProducts: taggedProducts,
          categories: categories,
          idempotencyKey: _uuid.v4(),
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
  Future<Either<NetworkExceptions, RecommendationReply>> replyToRequest({
    required String requestId,
    required String content,
    String? suggestedProduct,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.replyToRequest(
          requestId: requestId,
          content: content,
          suggestedProduct: suggestedProduct,
          idempotencyKey: _uuid.v4(),
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
  Future<Either<NetworkExceptions, Unit>> likeReply(String replyId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.likeReply(replyId, _uuid.v4());
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
